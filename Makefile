# Makefile for Rekognition Monitor Lambda

.PHONY: help build clean test deploy local-test

BINARY_NAME=bootstrap
LAMBDA_ARCH=arm64
LAMBDA_OS=linux
GO_VERSION=$(shell go version)

help:
	@echo "Rekognition Monitor Lambda - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build        - Build the Lambda binary"
	@echo "  make test         - Run unit tests"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make deploy       - Build and deploy to AWS"
	@echo "  make local-test   - Test the Lambda function"
	@echo "  make package      - Create deployment package"
	@echo "  make help         - Show this help message"

build: clean
	@echo "Building Go binary for AWS Lambda..."
	@echo "Go version: $(GO_VERSION)"
	GOOS=$(LAMBDA_OS) GOARCH=$(LAMBDA_ARCH) go build -o $(BINARY_NAME) main.go
	@echo "✓ Build successful: $(BINARY_NAME)"

test:
	@echo "Running tests..."
	go test -v -cover ./...
	@echo "✓ Tests passed"

clean:
	@echo "Cleaning up..."
	rm -f $(BINARY_NAME)
	rm -f rekognition-monitor.zip
	@echo "✓ Cleanup complete"

package: build
	@echo "Creating deployment package..."
	zip -r rekognition-monitor.zip $(BINARY_NAME)
	@echo "✓ Package created: rekognition-monitor.zip"

deploy: package
	@echo "Deploying to AWS..."
	@./deploy.sh
	@echo "✓ Deployment complete"

local-test:
	@echo "Testing Lambda function..."
	@./test.sh

.DEFAULT_GOAL := help
