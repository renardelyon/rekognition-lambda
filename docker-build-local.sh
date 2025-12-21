#!/bin/bash
# Docker build and run script for Rekognition Model Lambda

set -e

IMAGE_NAME="rekognition-lambda"
IMAGE_TAG="latest"
CONTAINER_NAME="rekognition-lambda"

echo "=== Building Rekognition Lambda Docker Image ==="
echo ""

# Build the Docker image
echo "Building Docker image..."
docker buildx build --platform linux/amd64 --provenance=false -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "✓ Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "✗ Docker build failed!"
    exit 1
fi

echo ""
echo "=== Docker Image Built ==="
echo ""

# Check if a container with the same name is already running
if docker ps | grep -q ${CONTAINER_NAME}; then
    echo "Stopping existing container: ${CONTAINER_NAME}"
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
fi