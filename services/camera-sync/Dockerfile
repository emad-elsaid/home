FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
rsync \
bash \
util-linux \
e2fsprogs \
ntfs-3g \
dosfstools

# Create app directory
WORKDIR /app

# Copy the monitor script
COPY monitor_and_sync.sh /app/monitor_and_sync.sh

# Make the script executable
RUN chmod +x /app/monitor_and_sync.sh

# Create necessary directories
RUN mkdir -p /sync /mnt/camera

# Run the monitoring script
CMD ["/app/monitor_and_sync.sh"]
