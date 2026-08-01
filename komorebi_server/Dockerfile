# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Generate sqlc code
RUN go run github.com/sqlc-dev/sqlc/cmd/sqlc@latest generate

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o server ./main.go

# Final stage
FROM alpine:latest

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/server .
# Copy any required assets if they exist (e.g., .env template, static files)
# COPY --from=builder /app/.env . 
COPY --from=builder /app/assets/ ./assets/

# Set Gin to release mode
ENV GIN_MODE=release

# Expose the port the app runs on (adjust if needed, Gin defaults to 8080)
EXPOSE 8080

# Command to run the application
CMD ["./server"]
