# Running Rekognition Lambda in Docker

This guide explains how to build and run the Rekognition Lambda in a Docker container.

## Prerequisites

- Docker installed and running
- AWS credentials configured (for AWS SDK access)
- Go 1.21+ (for building from source)

## Quick Start

### Using docker-build-local.sh Script

```bash
# Build and run
chmod +x docker-build-local.sh
./docker-build-local.sh

# View logs
docker logs -f rekognition-lambda

# Run the container
docker run -d \
  --entrypoint /usr/local/bin/aws-lambda-rie \
  --name rekognition-lambda \
  -p 9000:8080 \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v ~/.aws:/root/.aws:ro \
  rekognition-lambda:latest

# Test the function
curl -X POST \
  "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d @event.json

# View logs
docker logs -f rekognition-monitor

# Stop the container
docker stop rekognition-monitor
```

## AWS Credentials in Docker

### Option 1: Using AWS Credentials File (Recommended)

The docker-compose.yml and docker-build.sh automatically mount your local AWS credentials:

```yaml
volumes:
  - ~/.aws:/root/.aws:ro
```

This reads your AWS credentials from `~/.aws/credentials` and `~/.aws/config`.

### Option 2: Using Environment Variables

```bash
docker run -d \
  --name rekognition-monitor \
  -p 9000:8080 \
  -e AWS_ACCESS_KEY_ID=your_access_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret_key \
  -e AWS_DEFAULT_REGION=us-east-1 \
  rekognition-monitor:latest
```

### Option 3: Using AWS IAM Role (Production)

For production environments, use IAM roles through EC2 metadata service or ECS task roles:

```bash
docker run -d \
  --name rekognition-monitor \
  -p 9000:8080 \
  --env-file .env.production \
  rekognition-monitor:latest
```

### Manual Testing with curl

```bash
# Invoke the function
curl -X POST \
  "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d '{"modelArn":"arn:aws:rekognition:us-east-1:123456789012:project/MyProject/version/v1"}'

# With jq for formatted output
curl -X POST \
  "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d @event.json | jq .
```
## Container Management

### List Running Containers

```bash
docker ps | grep rekognition-monitor
```

### Stop the Container

```bash
docker stop rekognition-monitor
```

### Remove the Container

```bash
docker rm rekognition-monitor
```

### Restart the Container

```bash
docker restart rekognition-monitor
```

### Execute Command in Container

```bash
docker exec -it rekognition-monitor sh
```

### Function Not Responding

```bash
# Check if container is running
docker ps | grep rekognition-lambda

# Test connectivity
curl -v http://localhost:9000/2015-03-31/functions/function/invocations

# Check container health
docker stats rekognition-lambda
```

## Production Deployment

### Using Docker Registry

```bash
# Tag for registry
docker tag rekognition-lambda:latest myregistry.azurecr.io/rekognition-lambda:latest

# Push to registry
docker push myregistry.azurecr.io/rekognition-lambda:latest

# Pull and run
docker pull myregistry.azurecr.io/rekognition-lambda:latest
docker run -d myregistry.azurecr.io/rekognition-lambda:latest
```

### Using Docker with AWS ECR

```bash
# Create ECR repository
aws ecr create-repository --repository-name rekognition-lambda

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag rekognition-lambda:latest <account>.dkr.ecr.us-east-1.amazonaws.com/rekognition-lambda:latest

# Push to ECR
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/rekognition-lambda:latest
```

## References

- [AWS Lambda Docker Images](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [AWS SDK for Go](https://aws.github.io/aws-sdk-go-v2/)

## Support

For issues:
1. Check container logs: `docker logs -f rekognition-monitor`
2. Verify AWS credentials: `docker exec rekognition-monitor aws sts get-caller-identity`
3. Test connectivity: `curl http://localhost:9000/2015-03-31/functions/function/invocations`
4. Review CloudWatch logs after deployment to Lambda
