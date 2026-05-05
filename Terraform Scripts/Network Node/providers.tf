################################################################################
# providers.tf
# Proxmox VE provider configuration for kgmt.us homelab
#
# Provider : bpg/proxmox
# Docs     : https://registry.terraform.io/providers/bpg/proxmox/latest/docs
#
# Why bpg/proxmox over Telmate?
#   - Actively maintained (Telmate is largely abandoned)
#   - Full LXC + VM resource coverage
#   - Proper support for PVE 8+ / PVE 9 API
#   - First-class support for cloud-init, tags, and modern PVE features
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.78.0"
    }
  }
}

provider "proxmox" {
  # The API endpoint for your Proxmox host.
  # Uses the FQDN so it matches the TLS cert CN if you set one up later.
  endpoint = var.proxmox_endpoint

  # API token authentication — preferred over username/password.
  # Create a token in PVE UI: Datacenter > Permissions > API Tokens
  # Format: USER@REALM!TOKENID  e.g. terraform@pve!terraform-token
  api_token = var.proxmox_api_token

  # Set to true only if you are using a self-signed cert and have not yet
  # set up a proper cert for the PVE web UI. Flip to false once you have
  # a valid cert (e.g. from Let's Encrypt via Cloudflare DNS challenge).
  insecure = var.proxmox_insecure

  # SSH is used by the bpg provider for file uploads (e.g. snippets).
  # Not required for basic LXC creation but good to configure now.
  ssh {
    agent    = false
    username = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }
}
