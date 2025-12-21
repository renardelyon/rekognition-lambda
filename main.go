package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/rekognition"
)

// Event represents the EventBridge Lambda input event
type Event struct {
	ProjectArn string `json:"projectArn"`
	ModelArn   string `json:"modelArn"`
}

var (
	rekognitionClient *rekognition.Client
)

// init initializes AWS clients
func init() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("Unable to load SDK config: %v", err)
	}

	rekognitionClient = rekognition.NewFromConfig(cfg)
}

// stopModel calls the StopProjectVersion API
func stopModel(ctx context.Context, client *rekognition.Client, modelArn string) error {
	input := &rekognition.StopProjectVersionInput{
		ProjectVersionArn: &modelArn,
	}

	_, err := client.StopProjectVersion(ctx, input)
	return err
}

// checkCustomLabelModelStatus checks the status of a Rekognition custom label model
func checkCustomLabelModelStatus(ctx context.Context, projectArn string) (string, error) {
	input := &rekognition.DescribeProjectVersionsInput{
		ProjectArn: &projectArn,
	}

	result, err := rekognitionClient.DescribeProjectVersions(ctx, input)
	if err != nil {
		log.Printf("Error checking model status: %v", err)
		return "", err
	}

	// The response should contain exactly one ProjectVersionDescription
	if len(result.ProjectVersionDescriptions) == 0 {
		return "", os.ErrNotExist // Model not found
	}

	status := string(result.ProjectVersionDescriptions[0].Status)
	log.Printf("Model status: %s", status)
	return status, nil
}

// lambdaHandler is the main Lambda handler triggered by EventBridge
func lambdaHandler(ctx context.Context, event Event) error {
	// Validate required parameters
	if event.ProjectArn == "" {
		log.Printf("Error: Missing required parameters. ProjectArn: %s",
			event.ProjectArn)
		return fmt.Errorf("missing required parameters: ProjectArn is required")
	}

	log.Printf("EventBridge trigger - Checking model status for project: %s", event.ProjectArn)

	// Check model status
	modelStatus, err := checkCustomLabelModelStatus(ctx, event.ProjectArn)
	if err != nil {
		log.Printf("Failed to check model status: %v", err)
		return fmt.Errorf("failed to check model status: %w", err)
	}

	log.Printf("Current model status: %s", modelStatus)

	// Check the status and take action
	if modelStatus == "RUNNING" {
		log.Printf("Model is RUNNING. Attempting to stop model: %s", event.ModelArn)

		// Stop the model
		err = stopModel(ctx, rekognitionClient, event.ModelArn)
		if err != nil {
			log.Printf("Failed to stop model %s: %v", event.ModelArn, err)
			return err
		}

		log.Printf("Successfully initiated STOP_RUNNING for model: %s", event.ModelArn)
		return nil
	}

	// Model is in TRAINING, STOPPING, FAILED, or other state
	log.Printf("Model is in %s state. No action taken.", modelStatus)
	return nil
}

func main() {
	lambda.Start(lambdaHandler)
}
