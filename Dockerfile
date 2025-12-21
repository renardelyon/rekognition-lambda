# Stage 1: Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the Lambda function
RUN CGO_ENABLED=0 GOOS=linux go build -tags lambda.norpc -o bootstrap main.go

# Stage 2: Runtime stage using AWS Lambda base image
FROM public.ecr.aws/lambda/provided:al2023

# Copy the compiled binary from the builder stage
COPY --from=builder /app/bootstrap ${LAMBDA_TASK_ROOT}/

# Make the binary executable
RUN chmod +x ${LAMBDA_TASK_ROOT}/bootstrap

# Set the CMD to the Lambda handler
CMD [ "bootstrap" ]
