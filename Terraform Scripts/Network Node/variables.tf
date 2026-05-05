################################################################################
# variables.tf
# Input variable definitions for the kgmt.us Proxmox LXC module
################################################################################

# =============================================================================
# Proxmox Connection
# =============================================================================

variable "proxmox_endpoint" {
  description = "HTTPS URL of the Proxmox VE API endpoint."
  type        = string
  default     = "https://10.0.0.100:8006"
}

variable "proxmox_api_token" {
  description = <<-EOT
    Proxmox API token in the format USER@REALM!TOKENID=SECRET.
    Create in PVE UI: Datacenter > Permissions > API Tokens.
    The token role needs at minimum: VM.Allocate, Datastore.AllocateSpace,
    Datastore.Audit, SDN.Use, Sys.Audit.
  EOT
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification. Set to false once you have a valid cert."
  type        = bool
  default     = true
}

variable "proxmox_ssh_user" {
  description = "SSH username for the Proxmox host (used by the bpg provider for file ops)."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "SSH password for the Proxmox host."
  type        = string
  sensitive   = true
}

# =============================================================================
# LXC Container
# =============================================================================

variable "lxc_node" {
  description = "Proxmox node name to deploy the container on."
  type        = string
  default     = "kgmt-pve01-p"
}

variable "lxc_vm_id" {
  description = "Proxmox container ID (VMID). Must be unique across all VMs and CTs on the node."
  type        = number
  default     = 100
}

variable "lxc_hostname" {
  description = "Hostname for the LXC container."
  type        = string
  default     = "fedora-lxc-01"
}

variable "lxc_description" {
  description = "Description / notes for the container (visible in PVE UI)."
  type        = string
  default     = "Fedora LXC — provisioned by Terraform | kgmt.us homelab"
}

variable "lxc_tags" {
  description = "List of tags to apply to the container in the PVE UI."
  type        = list(string)
  default     = ["terraform", "fedora", "lxc"]
}

variable "lxc_template" {
  description = "Full path to the Fedora LXC template in PVE storage. Format: STORAGE:vztmpl/FILENAME"
  type        = string
  default     = "local:vztmpl/fedora-41-default_20241118_amd64.tar.xz"
}

variable "lxc_root_password" {
  description = "Root password for the LXC container."
  type        = string
  sensitive   = true
}

variable "lxc_cpu_cores" {
  description = "Number of CPU cores to allocate to the container."
  type        = number
  default     = 1
}

variable "lxc_memory_mb" {
  description = "RAM allocation in megabytes."
  type        = number
  default     = 1024
}

variable "lxc_swap_mb" {
  description = "Swap allocation in megabytes. Set to 0 to disable swap."
  type        = number
  default     = 512
}

variable "lxc_disk_size" {
  description = "Root disk size in gigabytes as a number (e.g. 20)."
  type        = number
  default     = 20
}

variable "lxc_storage_pool" {
  description = "Proxmox storage pool to use for the root disk."
  type        = string
  default     = "local-lvm"
}

variable "lxc_unprivileged" {
  description = "Run as an unprivileged container. Recommended for security."
  type        = bool
  default     = true
}

variable "lxc_start_after_create" {
  description = "Start the container immediately after Terraform creates it."
  type        = bool
  default     = true
}

# =============================================================================
# Networking
# =============================================================================

variable "lxc_net_bridge" {
  description = "Linux bridge interface on the Proxmox host to attach the container to."
  type        = string
  default     = "vmbr0"
}

variable "lxc_ip_address" {
  description = "Static IP address in CIDR notation (e.g. '10.0.0.101/24'). Use 'dhcp' for DHCP."
  type        = string
  default     = "10.0.0.101/24"
}

variable "lxc_gateway" {
  description = "Default gateway IP (e.g. '10.0.0.1'). Leave empty if using DHCP."
  type        = string
  default     = ""
}

# NOTE: This must be a list of strings, not a space-separated string.
# In terraform.tfvars write it as: lxc_dns_servers = ["1.1.1.1", "8.8.8.8"]
variable "lxc_dns_servers" {
  description = "List of DNS server IPs for the container."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "lxc_dns_domain" {
  description = "DNS search domain for the container."
  type        = string
  default     = "kgmt.us"
}
