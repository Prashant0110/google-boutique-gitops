#!/bin/bash

set -e

# Update packages
apt-get update -y

# Install Docker
apt-get install -y docker.io

# Start Docker
systemctl enable docker
systemctl start docker

# Ensure SSM Agent is running
snap install amazon-ssm-agent --classic || true
snap start amazon-ssm-agent

# Wait until SSM creates the ssm-user
while ! id ssm-user >/dev/null 2>&1; do
    sleep 2
done

# Allow ssm-user to use Docker without sudo
usermod -aG docker ssm-user