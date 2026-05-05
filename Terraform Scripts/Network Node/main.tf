################################################################################
# main.tf
# Proxmox LXC container — Fedora base template
# Target host : kgmt-pve01-p.kgmt.us
# Provider    : bpg/proxmox ~> 0.78.0
################################################################################

resource "proxmox_virtual_environment_container" "fedora_lxc" {

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  node_name   = var.lxc_node
  vm_id       = var.lxc_vm_id
  description = var.lxc_description
  tags        = var.lxc_tags

  # ---------------------------------------------------------------------------
  # Container OS
  # ---------------------------------------------------------------------------
  operating_system {
    template_file_id = var.lxc_template

    # Valid values: alpine, archlinux, centos, debian, devuan, fedora,
    #               gentoo, nixos, opensuse, ubuntu, unmanaged
    type = "fedora"
  }

  # ---------------------------------------------------------------------------
  # Initialization / Credentials / Network Config
  # ---------------------------------------------------------------------------
  # NOTE: In the bpg/proxmox provider, IP address and gateway for LXC
  # containers live inside initialization > ip_config > ipv4 {},
  # NOT inside the network_interface block. network_interface only handles
  # the interface-level settings (bridge, vlan, mac, etc.).
  initialization {
    hostname = var.lxc_hostname

    # IP configuration — paired 1:1 with network interfaces by index order.
    # This ip_config applies to the first (and only) network_interface below.
    ip_config {
      ipv4 {
        address = var.lxc_ip_address   # e.g. "10.0.0.101/24" or "dhcp"
        gateway = var.lxc_gateway      # e.g. "10.0.0.1"
      }
    }

    user_account {
      password = var.lxc_root_password
    }

    # dns.servers must be a list of strings.
    # In terraform.tfvars: lxc_dns_servers = ["1.1.1.1", "8.8.8.8"]
    dns {
      servers = var.lxc_dns_servers
      domain  = var.lxc_dns_domain
    }
  }

  # ---------------------------------------------------------------------------
  # CPU
  # ---------------------------------------------------------------------------
  cpu {
    cores        = var.lxc_cpu_cores
    architecture = "amd64"
  }

  # ---------------------------------------------------------------------------
  # Memory
  # ---------------------------------------------------------------------------
  memory {
    dedicated = var.lxc_memory_mb
    swap      = var.lxc_swap_mb
  }

  # ---------------------------------------------------------------------------
  # Root Disk
  # ---------------------------------------------------------------------------
  disk {
    datastore_id = var.lxc_storage_pool
    size         = var.lxc_disk_size
  }

  # ---------------------------------------------------------------------------
  # Network Interface
  # ---------------------------------------------------------------------------
  # Only bridge/interface-level settings go here.
  # IP address and gateway are configured in initialization > ip_config above.
  network_interface {
    name   = "eth0"
    bridge = var.lxc_net_bridge
  }

  # ---------------------------------------------------------------------------
  # Security & Behavior
  # ---------------------------------------------------------------------------
  unprivileged = var.lxc_unprivileged

  startup {
    order      = 1
    up_delay   = 10
    down_delay = 10
  }

  started = var.lxc_start_after_create

  # ---------------------------------------------------------------------------
  # Lifecycle
  # ---------------------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      # Prevents accidental destruction if the template filename changes
      # (e.g. a newer Fedora version is downloaded to local storage).
      operating_system,
    ]
  }
}
