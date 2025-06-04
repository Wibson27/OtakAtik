package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	//Router
	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hello, World!",
		})
	})
	router.Run("192.168.100.15:8080")
}
