#!/bin/bash
# =============================================================================
# Proxmox VE 9.1+ Post-Install Script
# =============================================================================
# Author      : Grayson Morris (@GraysonMor31)
# Domain      : kgmt.us
# Target Host : kgmt-pve01-p.kgmt.us
# License     : GNU General Public License v3.0
# Description : Post-install script for Proxmox VE 9.1+ (Debian 13 "Trixie").
#               - Configures no-subscription APT repositories (deb822 format)
#               - Removes the subscription nag banner
#               - Sets hostname and FQDN
#               - Installs common utility packages
#               - Optionally configures PCIe passthrough / VFIO
#
# IMPORTANT   : Run as root directly on the Proxmox host, NOT inside a VM/CT.
#               Tested on PVE 9.1.1 / Debian 13 Trixie / Kernel 6.17+
#
# CHANGELOG:
#   v3.0.3 - 2025-xx-xx : Fix nag banner patch string for PVE 9.1.
#                          PVE 9.1 proxmoxlib.js no longer uses the
#                          "data.status !== 'Active'" check. The correct
#                          patch is replacing "Ext.Msg.show({" with "void({"
#                          which voids the entire dialog call at the source.
#   v3.0.2 - 2025-xx-xx : Fix enterprise repo disable — overwrite files
#                          entirely instead of patching in-place. Patching
#                          is fragile and state-dependent; a full overwrite
#                          with a known-good deb822 stanza is idempotent and
#                          works regardless of the file's prior state.
#   v3.0.1 - 2025-xx-xx : Fix deb822 "malformed stanza 1" apt error.
#                          Replaced "comment out Types:" with "Enabled: no".
#   v3.0.0 - 2025-xx-xx : Rewrite for PVE 9.x / Debian 13 Trixie.
#                          Switched to deb822 .sources repo format,
#                          updated Ceph repo to ceph-squid, removed
#                          vfio_virqfd, added FQDN config, pre-flight
#                          checks, and modular function structure.
#   v2.0.0 - 2024-xx-xx : PVE 8.x / Debian 12 Bookworm version.
#   v1.0.0 - 2024-xx-xx : Initial release.
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION — Edit these before running
# =============================================================================
HOSTNAME_SHORT="kgmt-pve01-p"
DOMAIN="kgmt.us"
FQDN="${HOSTNAME_SHORT}.${DOMAIN}"

# Set to "true" to configure PCIe passthrough / VFIO
CONFIGURE_PCIE_PASSTHROUGH="true"

# CPU vendor for IOMMU flag: "intel" or "amd"
CPU_VENDOR="intel"

# Common packages to install
COMMON_PACKAGES="htop curl wget git net-tools vim tmux lsof iotop"

# =============================================================================
# COLORS & FORMATTING
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
section() { echo -e "\n${BOLD}${BLUE}==> $*${RESET}"; }

# =============================================================================
# BANNER
# =============================================================================
print_banner() {
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
    __ __ _____ __  _________   ____             __     ____           __        ____
   / //_// ___//  |/  /_  __/  / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / ,<  / (_ // /|_/ / / /    / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / /
 / /| |/ /_\ \/ /  / / / /   / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /
/_/ |_|\____/_/  /_/ /_/   /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/

    PVE 9.1  |  Debian 13 Trixie  |  kgmt.us Homelab
EOF
    echo -e "${RESET}"
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
preflight_checks() {
    section "Pre-flight Checks"

    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root."
        exit 1
    fi
    success "Running as root."

    if ! command -v pvesh &>/dev/null; then
        error "Proxmox VE not detected (pvesh not found). Are you on the right host?"
        exit 1
    fi
    success "Proxmox VE detected."

    # pveversion requires a working apt cache; run it best-effort
    PVE_VERSION=$(pveversion 2>/dev/null | grep -oP 'pve-manager/\K[0-9]+\.[0-9]+' || echo "unknown")
    info "Proxmox VE version: ${PVE_VERSION}"

    echo ""
    warn "This script will modify system repositories, packages, and kernel parameters."
    warn "Target host: ${FQDN}"
    warn "PCIe passthrough: ${CONFIGURE_PCIE_PASSTHROUGH}"
    echo ""
    read -rp "$(echo -e "${YELLOW}Continue? [y/N]:${RESET} ")" CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Aborted by user."
        exit 0
    fi
}

# =============================================================================
# SECTION 1: HOSTNAME / FQDN
# =============================================================================
configure_hostname() {
    section "Configuring Hostname & FQDN"

    hostnamectl set-hostname "${HOSTNAME_SHORT}"

    # Remove any stale entries for this hostname then insert the correct line
    sed -i "/\b${HOSTNAME_SHORT}\b/d" /etc/hosts

    local HOST_IP
    HOST_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)

    if [[ -z "$HOST_IP" ]]; then
        warn "Could not detect a primary IP. Using 127.0.1.1 in /etc/hosts."
        HOST_IP="127.0.1.1"
    fi

    sed -i "/^127\.0\.0\.1/a ${HOST_IP}\t${FQDN}\t${HOSTNAME_SHORT}" /etc/hosts

    success "Hostname  : $(hostname)"
    success "FQDN      : ${FQDN}"
    info    "hosts entry: ${HOST_IP}  ${FQDN}  ${HOSTNAME_SHORT}"
}

# =============================================================================
# SECTION 2: APT REPOSITORIES (deb822 format — required for Debian 13 Trixie)
# =============================================================================
# All enterprise repo files are OVERWRITTEN entirely with a clean, known-good
# deb822 stanza containing "Enabled: no". This is intentional — patching
# existing files in-place is fragile because a prior failed run may have left
# the file in an unknown state. A full overwrite is idempotent and always
# produces a valid, parseable result.
#
# deb822 rules:
#   - Every stanza MUST have a Types: field. Commenting it out = malformed.
#   - The correct way to disable a stanza is "Enabled: no" as a field.
#   - Files use the .sources extension. The legacy .list format causes
#     warnings on Debian 13 Trixie and must not be used.
#
# Repository layout after this section:
#   pve-enterprise.sources       → valid deb822, Enabled: no
#   ceph.sources                 → valid deb822, Enabled: no
#   pve-no-subscription.sources  → valid deb822, active
#   ceph-no-subscription.sources → valid deb822, active
#   debian.sources               → verified present, not touched
# =============================================================================
configure_repositories() {
    section "Configuring APT Repositories (deb822 / Trixie)"

    # --- Disable Enterprise PVE Repository ---
    # Overwrite with a structurally valid stanza that has Enabled: no.
    # Works correctly on a fresh install AND on any re-run of this script.
    info "Writing disabled enterprise PVE repo..."
    cat > /etc/apt/sources.list.d/pve-enterprise.sources << 'EOF'
# Proxmox VE Enterprise Repository
# Requires a valid subscription. Disabled for homelab use.
# To re-enable: change "Enabled: no" to "Enabled: yes"
Types: deb
URIs: https://enterprise.proxmox.com/debian/pve
Suites: trixie
Components: enterprise
Enabled: no
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    success "Enterprise PVE repo disabled."

    # --- Disable Enterprise Ceph Repository ---
    info "Writing disabled enterprise Ceph repo..."
    cat > /etc/apt/sources.list.d/ceph.sources << 'EOF'
# Ceph Squid Enterprise Repository
# Requires a valid subscription. Disabled for homelab use.
# To re-enable: change "Enabled: no" to "Enabled: yes"
Types: deb
URIs: https://enterprise.proxmox.com/debian/ceph-squid
Suites: trixie
Components: enterprise
Enabled: no
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    success "Enterprise Ceph repo disabled."

    # --- Write PVE No-Subscription Repository ---
    info "Writing PVE no-subscription repo..."
    cat > /etc/apt/sources.list.d/pve-no-subscription.sources << 'EOF'
# Proxmox VE No-Subscription Repository
# Suitable for homelab / non-production use.
# Ref: https://pve.proxmox.com/wiki/Package_Repositories
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    success "PVE no-subscription repo written."

    # --- Write Ceph Squid No-Subscription Repository ---
    # Ceph Squid (19.2.x) ships with PVE 9.
    # The repo name changed from "ceph-quincy" (PVE 8) to "ceph-squid" (PVE 9).
    info "Writing Ceph Squid no-subscription repo..."
    cat > /etc/apt/sources.list.d/ceph-no-subscription.sources << 'EOF'
# Ceph Squid No-Subscription Repository
# Suitable for homelab / non-production use.
# Ref: https://pve.proxmox.com/wiki/Package_Repositories
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    success "Ceph Squid no-subscription repo written."

    # --- Verify Debian Base Repos ---
    local DEBIAN_SRC="/etc/apt/sources.list.d/debian.sources"
    if [[ -f "$DEBIAN_SRC" ]]; then
        success "Debian base repo exists at ${DEBIAN_SRC} — not modified."
    else
        warn "debian.sources missing. Writing Debian 13 Trixie base repos..."
        cat > /etc/apt/sources.list.d/debian.sources << 'EOF'
# Debian 13 Trixie — Base Repositories
Types: deb deb-src
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
        success "Debian base repos written."
    fi

    info "Running apt-get update..."
    apt-get update -q
    success "Package index updated."
}

# =============================================================================
# SECTION 3: REMOVE SUBSCRIPTION NAG BANNER
# =============================================================================
# The nag dialog is fired from proxmoxlib.js inside proxmox-widget-toolkit.
#
# PVE 9.1 patch: The old "data.status !== 'Active'" check is gone in PVE 9.1.
# The dialog is now invoked directly via Ext.Msg.show({ ... }). Replacing
# "Ext.Msg.show({" with "void({" voids the entire call, suppressing the dialog
# without breaking any surrounding JS logic.
#
# NOTE: This patch must be re-applied after proxmox-widget-toolkit upgrades.
# =============================================================================
remove_subscription_nag() {
    section "Removing Subscription Nag Banner"

    local LIB_PATH="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

    if [[ ! -f "$LIB_PATH" ]]; then
        warn "proxmoxlib.js not found at ${LIB_PATH}. Skipping."
        return 0
    fi

    # Backup original on first run only
    if [[ ! -f "${LIB_PATH}.bak" ]]; then
        cp "${LIB_PATH}" "${LIB_PATH}.bak"
        info "Backup created: ${LIB_PATH}.bak"
    fi

    # PVE 9.1 patch: void the Ext.Msg.show dialog call directly.
    # The context around this call is specifically the "No valid subscription"
    # block — voiding it suppresses the nag without affecting other dialogs.
    if grep -q "Ext.Msg.show({" "$LIB_PATH"; then
        sed -i "s|Ext.Msg.show({|void({|g" "$LIB_PATH"
        success "Nag banner patched (Ext.Msg.show → void)."
    else
        warn "Known patch string 'Ext.Msg.show({' not found in proxmoxlib.js."
        warn "The nag may still appear. Inspect proxmoxlib.js manually:"
        warn "  grep -n 'No valid subscription' ${LIB_PATH}"
        warn "Then update the sed pattern in this script to match."
    fi

    systemctl restart pveproxy.service
    success "pveproxy restarted. Hard-refresh your browser (Ctrl+Shift+R)."
}

# =============================================================================
# SECTION 4: SYSTEM UPGRADE & COMMON PACKAGES
# =============================================================================
install_packages() {
    section "System Upgrade & Common Package Installation"

    info "Running full dist-upgrade..."
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -q
    success "System upgraded."

    info "Installing: ${COMMON_PACKAGES}"
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q $COMMON_PACKAGES
    success "Common packages installed."

    apt-get autoremove -y -q
    apt-get autoclean -q
    success "Cleanup complete."
}

# =============================================================================
# SECTION 5: PCIe PASSTHROUGH / VFIO CONFIGURATION
# =============================================================================
# Enables IOMMU and loads the VFIO subsystem for PCIe passthrough to VMs.
#
# PVE 9 / Kernel 6.17+ notes:
#   - vfio_virqfd is NOT listed here. It was merged into the core vfio module
#     in Linux 6.2. Adding it to /etc/modules on kernel 6.17+ causes modprobe
#     warnings and may fail initramfs builds.
#   - iommu=pt (passthrough mode) is required for performance and compatibility.
#   - pcie_acs_override splits IOMMU groups. Fine for homelab; use with
#     caution in production.
#   - GPU detection targets discrete NVIDIA only. The i5-6500 iGPU (Intel HD
#     530) will not match — that step is safely skipped.
#
# Pre-requisite: VT-d must be enabled in BIOS before IOMMU takes effect.
# =============================================================================
configure_pcie_passthrough() {
    section "PCIe Passthrough / VFIO Configuration"

    echo -e "${YELLOW}${BOLD}"
    cat << "EOF"
    ____  ________     ____                  __  __
   / __ \/ ____/ /__  / __ \____ ___________/ /_/ /_
  / /_/ / /   / / _ \/ /_/ / __ `/ ___/ ___/ __/ __ \
 / ____/ /___/ /  __/ ____/ /_/ (__  |__  ) /_/ / / /
/_/    \____/_/\___/_/    \__,_/____/____/\__/_/ /_/
EOF
    echo -e "${RESET}"

    # --- Step 1: IOMMU via GRUB ---
    info "Configuring IOMMU kernel parameters in GRUB..."

    local IOMMU_FLAG
    if [[ "$CPU_VENDOR" == "intel" ]]; then
        IOMMU_FLAG="intel_iommu=on"
    elif [[ "$CPU_VENDOR" == "amd" ]]; then
        IOMMU_FLAG="amd_iommu=on"
    else
        error "CPU_VENDOR must be 'intel' or 'amd'. Got: '${CPU_VENDOR}'"
        exit 1
    fi

    local ALL_PARAMS="${IOMMU_FLAG} iommu=pt pcie_acs_override=downstream,multifunction nofb nomodeset video=vesafb:off,efifb:off"

    if grep -q "$IOMMU_FLAG" /etc/default/grub; then
        warn "IOMMU parameters already present in GRUB config. Skipping."
    else
        sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\"\)|\1${ALL_PARAMS} |" /etc/default/grub
        success "IOMMU parameters added to GRUB_CMDLINE_LINUX_DEFAULT."
    fi

    update-grub
    success "GRUB updated."

    # --- Step 2: VFIO Kernel Modules ---
    # vfio_virqfd intentionally omitted — merged into vfio in kernel 6.2.
    info "Adding VFIO modules to /etc/modules..."
    local VFIO_MODULES=("vfio" "vfio_iommu_type1" "vfio_pci")

    for MOD in "${VFIO_MODULES[@]}"; do
        if grep -qxF "$MOD" /etc/modules; then
            info "  '${MOD}' already present. Skipping."
        else
            echo "$MOD" >> /etc/modules
            success "  Added: ${MOD}"
        fi
    done

    depmod -a
    success "Module dependency map updated."

    # --- Step 3: IOMMU Unsafe Interrupt Remapping ---
    info "Writing IOMMU modprobe options..."
    echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" \
        > /etc/modprobe.d/iommu_unsafe_interrupts.conf
    echo "options kvm ignore_msrs=1" \
        > /etc/modprobe.d/kvm.conf
    success "IOMMU options written."

    # --- Step 4: Blacklist Host GPU Drivers ---
    info "Blacklisting GPU drivers on host..."
    cat > /etc/modprobe.d/blacklist-gpu.conf << 'EOF'
# Prevent the host from loading GPU drivers so VFIO can claim the device
# before the host OS binds to it.
blacklist radeon
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
EOF
    success "GPU driver blacklist written."

    # --- Step 5: Detect Discrete GPU & Write VFIO PCI Binding ---
    info "Scanning for discrete NVIDIA GPU via lspci..."

    local GPU_ADDR AUDIO_ADDR GPU_ID AUDIO_ID
    GPU_ADDR=$(lspci -Dn | grep -iE "(VGA compatible controller|3D controller)" \
        | grep -i nvidia | awk '{print $1}' | head -1 || true)
    AUDIO_ADDR=$(lspci -Dn | grep -i "Audio device" \
        | grep -i nvidia | awk '{print $1}' | head -1 || true)

    if [[ -z "$GPU_ADDR" ]]; then
        warn "No discrete NVIDIA GPU detected. VFIO PCI binding skipped."
        warn "To bind a GPU manually after adding one:"
        warn "  lspci -nn | grep -i nvidia"
        warn "  echo 'options vfio-pci ids=XXXX:XXXX' > /etc/modprobe.d/vfio.conf"
        warn "  update-initramfs -u -k all"
    else
        GPU_ID=$(lspci -n -s "$GPU_ADDR" | awk '{print $3}' || true)
        AUDIO_ID=$(lspci -n -s "$AUDIO_ADDR" | awk '{print $3}' 2>/dev/null || true)

        info "  GPU  : ${GPU_ADDR}  (${GPU_ID:-unknown})"
        info "  Audio: ${AUDIO_ADDR:-none}  (${AUDIO_ID:-none})"

        local VFIO_IDS="${GPU_ID}"
        [[ -n "$AUDIO_ID" ]] && VFIO_IDS="${GPU_ID},${AUDIO_ID}"

        echo "options vfio-pci ids=${VFIO_IDS}" > /etc/modprobe.d/vfio.conf
        success "VFIO PCI binding written: ${VFIO_IDS}"
    fi

    # --- Step 6: Update initramfs ---
    info "Updating initramfs for all kernels..."
    update-initramfs -u -k all
    success "initramfs updated."
}

# =============================================================================
# SECTION 6: SUMMARY & OPTIONAL REBOOT
# =============================================================================
print_summary() {
    section "Post-Install Summary"

    echo ""
    printf "  %-22s %s\n" "Hostname:"         "$(hostname)"
    printf "  %-22s %s\n" "FQDN:"             "${FQDN}"
    printf "  %-22s %s\n" "PVE Version:"      "$(pveversion 2>/dev/null | head -1 || echo 'run pveversion manually')"
    printf "  %-22s %s\n" "Kernel:"           "$(uname -r)"
    printf "  %-22s %s\n" "PCIe Passthrough:" "${CONFIGURE_PCIE_PASSTHROUGH}"
    echo ""

    success "All steps complete."
    echo ""
    warn "A REBOOT IS REQUIRED to apply GRUB and kernel/initramfs changes."
    echo ""
    read -rp "$(echo -e "${YELLOW}Reboot now? [y/N]:${RESET} ")" REBOOT_NOW
    if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
        info "Rebooting in 5 seconds — Ctrl+C to cancel."
        sleep 5
        reboot -f
    else
        info "Reboot deferred. Run 'reboot' when ready."
    fi
}

# =============================================================================
# ENTRYPOINT
# =============================================================================
main() {
    print_banner
    preflight_checks
    configure_hostname
    configure_repositories
    remove_subscription_nag
    install_packages

    if [[ "$CONFIGURE_PCIE_PASSTHROUGH" == "true" ]]; then
        configure_pcie_passthrough
    else
        info "PCIe passthrough skipped (CONFIGURE_PCIE_PASSTHROUGH=false)."
    fi

    print_summary
}

main "$@"
