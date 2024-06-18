#!/usr/bin/env bash

# Define the directory and file path
# see: https://github.com/containerd/containerd/blob/main/docs/hosts.md
DIR="/etc/containerd/certs.d/docker.io"
FILE="$DIR/hosts.toml"

# Create the directory if it does not exist
if [ ! -d "$DIR" ]; then
    sudo mkdir -p "$DIR"
fi

# Write the content to the file
sudo tee -a  "$FILE" > /dev/null <<EOF
server = "https://registry-1.docker.io"  # default after trying hosts
host."https://dockerhub-proxy.us-east-1-a.stg.aws.gather.town".capabilities = ["pull", "resolve"]
EOF

# Verify the file has been created and display its content
if [ -f "$FILE" ]; then
    echo "Dockerhub proxy has been successfully set at $FILE with the following content:"
else
    echo "Failed to create the file at $FILE"
fi
