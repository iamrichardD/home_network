#!/bin/bash

# setup-ssl.sh
# Automates Let's Encrypt SSL setup on Proxmox VE using DNS-01 challenge (Cloudflare)
# Author: Expert DevSecOps Engineer

set -e

# Configuration
ENV_FILE=".env"
ACME_ACCOUNT_NAME="default"
PLUGIN_ID="cloudflare"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  log_error "Please run as root"
  exit 1
fi

# Load Environment Variables
if [ -f "$ENV_FILE" ]; then
    # Ensure secure permissions on .env file
    if [ "$(stat -c %a "$ENV_FILE")" != "600" ]; then
        log_warn "Permissions on $ENV_FILE are not secure. Fixing..."
        chmod 600 "$ENV_FILE"
        log_info "Permissions set to 600 for $ENV_FILE."
    fi

    # shellcheck disable=SC1090
    source "$ENV_FILE"
else
    log_error "Configuration file $ENV_FILE not found!"
    echo "Please copy .env.example to .env and fill in your details."
    exit 1
fi

# Validate Variables
if [ -z "$CF_EMAIL" ] || [ -z "$CF_TOKEN" ] || [ -z "$DOMAIN" ]; then
    log_error "Missing required variables in .env file."
    echo "Required: CF_EMAIL, CF_TOKEN, DOMAIN"
    exit 1
fi

log_info "Starting Proxmox SSL Setup for domain: $DOMAIN"

# 1. Register ACME Account
if pvenode acme account list | grep -q "$ACME_ACCOUNT_NAME"; then
    log_info "ACME account '$ACME_ACCOUNT_NAME' already exists. Skipping registration."
else
    log_info "Registering ACME account '$ACME_ACCOUNT_NAME' with email $CF_EMAIL..."
    pvenode acme account register "$ACME_ACCOUNT_NAME" "$CF_EMAIL"
fi

# 2. Configure Cloudflare Plugin
if pvenode acme plugin list | grep -q "$PLUGIN_ID"; then
    log_info "ACME plugin '$PLUGIN_ID' already exists. Updating configuration..."
    pvenode acme plugin set "$PLUGIN_ID" --api cf --data "CF_Token=$CF_TOKEN"
else
    log_info "Creating ACME plugin '$PLUGIN_ID'..."
    pvenode acme plugin add "$PLUGIN_ID" --api cf --data "CF_Token=$CF_TOKEN"
fi

# 3. Configure Node Certificate
# Check if the domain is already configured for the node
CURRENT_CONFIG=$(pvenode config get --property acme)

if [[ "$CURRENT_CONFIG" == *"$DOMAIN"* ]]; then
    log_info "Domain $DOMAIN is already configured for this node."
else
    log_info "Configuring domain $DOMAIN for this node using plugin $PLUGIN_ID..."
    pvenode config set --acme domains="$DOMAIN,plugin=$PLUGIN_ID"
fi

# 4. Order Certificate
log_info "Ordering certificate..."
pvenode acme cert order

log_info "Setup complete! The certificate should now be installed."
log_info "You can verify the certificate status in the Proxmox GUI under System -> Certificates."
