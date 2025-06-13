// Tambahkan ke main.go atau buat file terpisah
// File: controllers/debug_controller.go

package controllers

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"backend/config"

	"github.com/gin-gonic/gin"
	"github.com/sashabaranov/go-openai"
)

type DebugController struct {
	Cfg *config.Config
}

func NewDebugController(cfg *config.Config) *DebugController {
	return &DebugController{Cfg: cfg}
}

// DebugEnvironment shows current environment variables (masked for security)
func (d *DebugController) DebugEnvironment(c *gin.Context) {
	apiKey := d.Cfg.Azure.OpenAIAPIKey
	masked := ""
	if len(apiKey) > 8 {
		masked = apiKey[:4] + "..." + apiKey[len(apiKey)-4:]
	}

	debug := map[string]interface{}{
		"azure_config": map[string]string{
			"api_key_masked":     masked,
			"endpoint":           d.Cfg.Azure.OpenAIEndpoint,
			"deployment_name":    d.Cfg.Azure.OpenAIDeploymentName,
			"api_version":        d.Cfg.Azure.OpenAIAPIVersion,
		},
		"config_status": map[string]bool{
			"api_key_set":      len(d.Cfg.Azure.OpenAIAPIKey) > 0,
			"endpoint_set":     len(d.Cfg.Azure.OpenAIEndpoint) > 0,
			"deployment_set":   len(d.Cfg.Azure.OpenAIDeploymentName) > 0,
			"version_set":      len(d.Cfg.Azure.OpenAIAPIVersion) > 0,
		},
		"timestamp": time.Now(),
	}

	c.JSON(http.StatusOK, gin.H{"debug": debug})
}

// TestAzureOpenAI tests direct connection to Azure OpenAI
func (d *DebugController) TestAzureOpenAI(c *gin.Context) {
	apiKey := d.Cfg.Azure.OpenAIAPIKey
	endpoint := d.Cfg.Azure.OpenAIEndpoint
	deploymentName := d.Cfg.Azure.OpenAIDeploymentName
	apiVersion := d.Cfg.Azure.OpenAIAPIVersion

	fmt.Printf("🔍 Testing Azure OpenAI Connection...\n")
	fmt.Printf("   Endpoint: %s\n", endpoint)
	fmt.Printf("   Deployment: %s\n", deploymentName)
	fmt.Printf("   API Version: %s\n", apiVersion)
	fmt.Printf("   API Key Length: %d\n", len(apiKey))

	if apiKey == "" || endpoint == "" || deploymentName == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Missing Azure OpenAI configuration",
			"missing": map[string]bool{
				"api_key":    apiKey == "",
				"endpoint":   endpoint == "",
				"deployment": deploymentName == "",
			},
		})
		return
	}

	// Test connection
	config := openai.DefaultAzureConfig(apiKey, endpoint)
	config.APIVersion = apiVersion
	client := openai.NewClientWithConfig(config)

	fmt.Printf("🔗 Sending test request to Azure OpenAI...\n")

	req := openai.ChatCompletionRequest{
		Model: deploymentName,
		Messages: []openai.ChatCompletionMessage{
			{
				Role:    openai.ChatMessageRoleSystem,
				Content: "You are a helpful assistant.",
			},
			{
				Role:    openai.ChatMessageRoleUser,
				Content: "Say 'Hello from Azure OpenAI test' in Indonesian.",
			},
		},
		MaxTokens:   50,
		Temperature: 0.7,
	}

	start := time.Now()
	resp, err := client.CreateChatCompletion(context.Background(), req)
	duration := time.Since(start)

	if err != nil {
		fmt.Printf("❌ Azure OpenAI Error: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":    "Azure OpenAI connection failed",
			"details":  err.Error(),
			"duration": duration.String(),
			"config": map[string]string{
				"endpoint":    endpoint,
				"deployment":  deploymentName,
				"api_version": apiVersion,
			},
		})
		return
	}

	if len(resp.Choices) == 0 {
		fmt.Printf("❌ Azure OpenAI returned no choices\n")
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":    "No response choices from Azure OpenAI",
			"duration": duration.String(),
		})
		return
	}

	response := resp.Choices[0].Message.Content
	fmt.Printf("✅ Azure OpenAI Response: %s\n", response)
	fmt.Printf("✅ Request completed in: %s\n", duration)

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"response": response,
		"duration": duration.String(),
		"usage": map[string]interface{}{
			"prompt_tokens":     resp.Usage.PromptTokens,
			"completion_tokens": resp.Usage.CompletionTokens,
			"total_tokens":      resp.Usage.TotalTokens,
		},
		"model": resp.Model,
	})
}