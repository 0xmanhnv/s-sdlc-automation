#!/bin/bash

# Setup permissions for n8n DevSecOps environment
echo "Setting up permissions for n8n DevSecOps environment..."

# Function to fix volume permissions
fix_volume_permissions() {
    local volume_name=$1
    local user_id=$2
    local group_id=$3
    
    local volume_path="/var/lib/docker/volumes/s-sdlc-automation_${volume_name}/_data"
    
    if [ -d "$volume_path" ]; then
        echo "Fixing permissions for $volume_name..."
        sudo chown -R ${user_id}:${group_id} "$volume_path"
        sudo chmod -R 755 "$volume_path"
    else
        echo "Creating directory for $volume_name..."
        sudo mkdir -p "$volume_path"
        sudo chown -R ${user_id}:${group_id} "$volume_path"
        sudo chmod -R 755 "$volume_path"
    fi
}

# Fix permissions for all volumes
fix_volume_permissions "postgres_data" 999 999
fix_volume_permissions "redis_data" 999 999
fix_volume_permissions "n8n_data" 1000 1000
fix_volume_permissions "certbot_data" 1000 1000
fix_volume_permissions "nginx_logs" 101 101

echo "Permissions setup completed!"
echo "You can now run: docker-compose -f docker-compose.devsecops.yml up -d" 