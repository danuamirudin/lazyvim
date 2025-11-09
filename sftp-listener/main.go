package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

type ProjectConfig struct {
	LocalBasePath string `json:"local_base_path"`
	SFTPHost      string `json:"sftp_host"`
	SFTPPort      string `json:"sftp_port"`
	SFTPUser      string `json:"sftp_user"`
	SFTPPassword  string `json:"sftp_password"`
	SFTPBasePath  string `json:"sftp_base_path"`
}

type Config struct {
	ServerPort         string                   `json:"server_port"`
	RegisteredProjects map[string]ProjectConfig `json:"registered_projects"`
}

type UploadRequest struct {
	BaseRoot string `json:"base_root"`
	FilePath string `json:"file_path"`
}

type FolderRequest struct {
	BaseRoot   string `json:"base_root"`
	FolderPath string `json:"folder_path"`
}

type DownloadRequest struct {
	BaseRoot string `json:"base_root"`
	FilePath string `json:"file_path"`
}

type UploadResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	File    string `json:"file"`
}

var appConfig Config

func main() {
	if err := loadConfig(); err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	log.Printf("Starting HTTP server on port %s", appConfig.ServerPort)
	log.Printf("Registered %d projects", len(appConfig.RegisteredProjects))
	for key := range appConfig.RegisteredProjects {
		log.Printf("  - %s", key)
	}

	http.HandleFunc("/upload", handleUpload)
	http.HandleFunc("/upload-folder", handleUploadFolder)
	http.HandleFunc("/download", handleDownload)
	http.HandleFunc("/download-folder", handleDownloadFolder)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/projects", handleListProjects)

	log.Fatal(http.ListenAndServe(":"+appConfig.ServerPort, nil))
}

func loadConfig() error {
	configPath := os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "sftp-listener.json"
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	if err := json.Unmarshal(data, &appConfig); err != nil {
		return fmt.Errorf("failed to parse config file: %w", err)
	}

	if appConfig.ServerPort == "" {
		appConfig.ServerPort = "8765"
	}

	return nil
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func handleListProjects(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	projects := make([]string, 0, len(appConfig.RegisteredProjects))
	for key := range appConfig.RegisteredProjects {
		projects = append(projects, key)
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"projects": projects,
		"count":    len(projects),
	})
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req UploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FilePath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and file_path are required",
		})
		return
	}

	projectConfig, exists := appConfig.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Project not registered",
		})
		return
	}

	if !strings.HasPrefix(req.FilePath, projectConfig.LocalBasePath) {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "File path must be within the project base path",
		})
		return
	}

	if _, err := os.Stat(req.FilePath); os.IsNotExist(err) {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "File does not exist",
		})
		return
	}

	log.Printf("[%s] Uploading: %s", req.BaseRoot, req.FilePath)

	if err := uploadFile(projectConfig, req.FilePath); err != nil {
		log.Printf("[%s] Upload failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Upload failed: %v", err),
			File:    req.FilePath,
		})
		return
	}

	log.Printf("[%s] Successfully uploaded: %s", req.BaseRoot, req.FilePath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "File uploaded successfully",
		File:    req.FilePath,
	})
}

func uploadFile(config ProjectConfig, localPath string) error {
	sshConfig := &ssh.ClientConfig{
		User: config.SFTPUser,
		Auth: []ssh.AuthMethod{
			ssh.Password(config.SFTPPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:%s", config.SFTPHost, config.SFTPPort), sshConfig)
	if err != nil {
		return fmt.Errorf("failed to dial: %w", err)
	}
	defer conn.Close()

	client, err := sftp.NewClient(conn)
	if err != nil {
		return fmt.Errorf("failed to create SFTP client: %w", err)
	}
	defer client.Close()

	srcFile, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer srcFile.Close()

	relativePath := strings.TrimPrefix(localPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remotePath := filepath.Join(config.SFTPBasePath, relativePath)
	remoteDir := filepath.Dir(remotePath)

	if err := client.MkdirAll(remoteDir); err != nil {
		return fmt.Errorf("failed to create remote directory: %w", err)
	}

	dstFile, err := client.Create(remotePath)
	if err != nil {
		return fmt.Errorf("failed to create remote file: %w", err)
	}
	defer dstFile.Close()

	if _, err := dstFile.ReadFrom(srcFile); err != nil {
		return fmt.Errorf("failed to upload file: %w", err)
	}

	return nil
}

func handleUploadFolder(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req FolderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FolderPath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and folder_path are required",
		})
		return
	}

	projectConfig, exists := appConfig.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Project not registered",
		})
		return
	}

	log.Printf("[%s] Uploading folder: %s", req.BaseRoot, req.FolderPath)

	fileCount := 0
	err := filepath.Walk(req.FolderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			if err := uploadFile(projectConfig, path); err != nil {
				log.Printf("[%s] Failed to upload %s: %v", req.BaseRoot, path, err)
			} else {
				fileCount++
			}
		}
		return nil
	})

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Folder upload failed: %v", err),
		})
		return
	}

	log.Printf("[%s] Successfully uploaded folder with %d files", req.BaseRoot, fileCount)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: fmt.Sprintf("Folder uploaded successfully (%d files)", fileCount),
		File:    req.FolderPath,
	})
}

func handleDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req DownloadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FilePath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and file_path are required",
		})
		return
	}

	projectConfig, exists := appConfig.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Project not registered",
		})
		return
	}

	log.Printf("[%s] Downloading: %s", req.BaseRoot, req.FilePath)

	if err := downloadFile(projectConfig, req.FilePath); err != nil {
		log.Printf("[%s] Download failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Download failed: %v", err),
			File:    req.FilePath,
		})
		return
	}

	log.Printf("[%s] Successfully downloaded: %s", req.BaseRoot, req.FilePath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "File downloaded successfully",
		File:    req.FilePath,
	})
}

func handleDownloadFolder(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req FolderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FolderPath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and folder_path are required",
		})
		return
	}

	projectConfig, exists := appConfig.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Project not registered",
		})
		return
	}

	log.Printf("[%s] Downloading folder: %s", req.BaseRoot, req.FolderPath)

	if err := downloadFolder(projectConfig, req.FolderPath); err != nil {
		log.Printf("[%s] Folder download failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Folder download failed: %v", err),
		})
		return
	}

	log.Printf("[%s] Successfully downloaded folder: %s", req.BaseRoot, req.FolderPath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "Folder downloaded successfully",
		File:    req.FolderPath,
	})
}

func downloadFile(config ProjectConfig, localPath string) error {
	sshConfig := &ssh.ClientConfig{
		User: config.SFTPUser,
		Auth: []ssh.AuthMethod{
			ssh.Password(config.SFTPPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:%s", config.SFTPHost, config.SFTPPort), sshConfig)
	if err != nil {
		return fmt.Errorf("failed to dial: %w", err)
	}
	defer conn.Close()

	client, err := sftp.NewClient(conn)
	if err != nil {
		return fmt.Errorf("failed to create SFTP client: %w", err)
	}
	defer client.Close()

	relativePath := strings.TrimPrefix(localPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remotePath := filepath.Join(config.SFTPBasePath, relativePath)

	srcFile, err := client.Open(remotePath)
	if err != nil {
		return fmt.Errorf("failed to open remote file: %w", err)
	}
	defer srcFile.Close()

	localDir := filepath.Dir(localPath)
	if err := os.MkdirAll(localDir, 0755); err != nil {
		return fmt.Errorf("failed to create local directory: %w", err)
	}

	dstFile, err := os.Create(localPath)
	if err != nil {
		return fmt.Errorf("failed to create local file: %w", err)
	}
	defer dstFile.Close()

	if _, err := dstFile.ReadFrom(srcFile); err != nil {
		return fmt.Errorf("failed to download file: %w", err)
	}

	return nil
}

func downloadFolder(config ProjectConfig, localFolderPath string) error {
	sshConfig := &ssh.ClientConfig{
		User: config.SFTPUser,
		Auth: []ssh.AuthMethod{
			ssh.Password(config.SFTPPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	conn, err := ssh.Dial("tcp", fmt.Sprintf("%s:%s", config.SFTPHost, config.SFTPPort), sshConfig)
	if err != nil {
		return fmt.Errorf("failed to dial: %w", err)
	}
	defer conn.Close()

	client, err := sftp.NewClient(conn)
	if err != nil {
		return fmt.Errorf("failed to create SFTP client: %w", err)
	}
	defer client.Close()

	relativePath := strings.TrimPrefix(localFolderPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remoteFolderPath := filepath.Join(config.SFTPBasePath, relativePath)

	walker := client.Walk(remoteFolderPath)
	for walker.Step() {
		if err := walker.Err(); err != nil {
			log.Printf("Error walking remote folder: %v", err)
			continue
		}

		remotePath := walker.Path()
		relPath := strings.TrimPrefix(remotePath, config.SFTPBasePath)
		relPath = strings.TrimPrefix(relPath, "/")
		localPath := filepath.Join(config.LocalBasePath, relPath)

		if walker.Stat().IsDir() {
			if err := os.MkdirAll(localPath, 0755); err != nil {
				log.Printf("Failed to create directory %s: %v", localPath, err)
			}
		} else {
			if err := downloadFile(config, localPath); err != nil {
				log.Printf("Failed to download %s: %v", localPath, err)
			}
		}
	}

	return nil
}
