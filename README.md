# Homelab Project

## About
Welcome to my Homelab Project! This repository showcases the setup, configuration, and management of my personal homelab environment. The goal of this project is to build a versatile and scalable infrastructure for testing, learning, and experimentation with various technologies. (Let's be honest I'm trying to de-Google my life) 

The homelab includes a range of systems, services, and tools to simulate real-world IT scenarios/training, experiment with new technologies in a safe environment, and automate mundane day-to-day tasks.

## Key Technologies

### 1. Virtualization & Containers
- **Proxmox**: Virtualization platform for managing VMs and containers.
- **Docker**: Containerization for isolating applications and services.
- **Kubernetes**: Container orchestration for automating deployment, scaling, and management of containerized applications.
- **Hyper-V**: Test environment and basic Windows Domain Lab

### 2. Networking
- **TwinGate**: Open-source ZTNA system deployed across all devices for home network access and provide network logs.
- **NGINX Reverse Proxy**: Dynamic reverse proxy and load balancer for managing containerized services.
- **Cloudflare DDNS**: Serve as a Dynamic DNS updater for publicly accessible resources

### 3. Cyber/Systems Security
- **Wazuh**: Open-source SIEM and XDR tool handling monitoring and incident response.
- **ShuffleSOAR**:
- **Suricata**:
- **TheHIVE**:
- **MISP**:
- **Eramba CE**:
- **OpenControl**:

### 4. Monitoring & Automation
- **Prometheus**: Monitoring and alerting toolkit for services and infrastructure.
- **Grafana**: Dashboard and visualization tool for Prometheus metrics.
- **Ansible**: Automation tool for configuration management and deployments.

### 5. File Storage & Cloud Services
- **Nextcloud**: Self-hosted cloud like file sync and sharing platform similar to OneDrive and/or Google G-Suite.
- **Immich**: Self-hosted image library like Google Photos.
- **Plex**: Self-hosted media server and streaming service.
- **Monetr**: Self-hosted household budgeting application similar to something like RocketMoney

### 6. Development & Collaboration
- **Gitea**: Self-hosted Git repository management.
- **Drone**: Self-hosted CI/CD pipline.
- **Plane**: Open-Source project management tool.
- **NGINX**: Test deployment system.
- **MySQL**: RDBMS for homelab data.
- **PostgreSQL**: DBMS for coding projects

### 7. AI and Local LLMs
- **Ollama**: Self-hosted generative AI service using Meta's Llama models (3.2) and an UI similar to ChatGPT with WebSearch, Image Generation, and TTS, STT capabilities.
- **OpenCode**: Open-source tool for building and using AI Agents with Ollama or external services like Codex or ClaudeCode.
- **Automatic1111**: Self-hosted generative AI service for creating images using GPU acceleration.
- **PyTorch**: Python based library and framework for tuning and developing neural networks and LLMs.

### 8. Other Services
- **Home Assistant**: Smart home automation platform to control IoT devices.
- **Frigate**: AI-powered Network Video Reorder (NVR) for locally installed security cameras.
- **VaultWarden**: Self hosted password manager that works with most browsers.

## Architecture Overview
This homelab is built with the following components:
1. **Host Hardware**: Servers (physical or virtualized) running Proxmox, this includes a Xeon based Dell workstation, a few Raspberry Pi's clustered together, my desktop and, my laptop.
2. **Virtualization Layer**: Proxmox manages most VMs, and LXC containers, Docker handles most services on the VMs, the VMs are running mostly RHEL and Ubuntu Server, a Windows Server instance simulates AD and Group Policy.
4. **Networking**: TwinGate secures and manages traffic to/from the lab, firewalls and access control lists are done through my router (Xfinity base router with plans to move to Ubiquiti in the next year)
5. **Databases**: Every service that requires a database will be using one built in to the docker stack that is running the service. Most use SQLite, certain high criticality services use PostgreSQL or MariaDB.
6. **Monitoring & Logging**: Prometheus, Grafana, Wazuh and ELK stack to monitor and visualize metrics and logs.

