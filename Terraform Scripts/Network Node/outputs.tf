################################################################################
# outputs.tf
# Values printed after a successful terraform apply
################################################################################

output "container_id" {
  description = "Proxmox VMID assigned to the container."
  value       = proxmox_virtual_environment_container.fedora_lxc.vm_id
}

output "container_hostname" {
  description = "Hostname of the container."
  value       = proxmox_virtual_environment_container.fedora_lxc.initialization[0].hostname
}

output "container_node" {
  description = "Proxmox node the container is running on."
  value       = proxmox_virtual_environment_container.fedora_lxc.node_name
}

output "container_ip" {
  description = "Configured IP address of the container."
  value       = var.lxc_ip_address
}

output "container_status" {
  description = "Whether the container was started after creation."
  value       = proxmox_virtual_environment_container.fedora_lxc.started ? "running" : "stopped"
}
