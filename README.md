# Homelab Project

## About
Welcome to my Homelab Project! This repository showcases the setup, configuration, and management of my personal homelab environment. The goal of this project is to build a versatile and scalable infrastructure for testing, learning, and experimentation with various technologies. 

The homelab includes a range of systems, services, and tools to simulate real-world IT scenarios/training, experiment with new technologies in a safe environment, and automate mundane day-to-day tasks.

## Key Technologies

### 1. Virtualization & Containers
- **Proxmox**: Virtualization platform for managing VMs and containers.
- **Docker**: Containerization for isolating applications and services.
- **Kubernetes**: Container orchestration for automating deployment, scaling, and management of containerized applications.

### 2. Networking & Security
- **TwinGate**: Open-source ZTNA system deployed across all devices for home network access and provide network logs.
- **NGINX Reverse Proxy**: Dynamic reverse proxy and load balancer for managing containerized services.
- **Wazuh**: Open-source SIEM solution for monitoring and log aggregation using ElasticSearch, as well as handling vulnerabilty management.
- **R7 Velociraptor**: Digital Forensics and Incident Response (DFIR).
- **Shuffle SOAR**: Open-Source Security, Orchestration, Automation, And Response (SOAR) tool to automate Wazuh and Velociraptor.
- **Crowd-Sec**: Open-source Intrusion Prevention System (IPS) that uses crowd-sourced threat intelligence.

### 3. Monitoring & Automation
- **Prometheus**: Monitoring and alerting toolkit for services and infrastructure.
- **Grafana**: Dashboard and visualization tool for Prometheus metrics.
- **Ansible**: Automation tool for configuration management and deployments.

### 4. File Storage & Cloud Services
- **TrueNAS**: Self-hosted NAS to store backups and provide storage to VMs and services as well as a SMB server
- **Nextcloud**: Self-hosted cloud like file sync and sharing platform.
- **Plex**: Self-hosted media server and streaming service.
- **Monetr**: Self-hosted household budgeting application similar to something like RocketMoney

### 5. Development & Collaboration
- **Gitea**: Self-hosted Git repository management.
- **Drone**: Self-hosted CI/CD pipline.
- **Plane**: Open-Source project management tool.
- **NGINX**: Test deployment system.
- **MySQL**: RDBMS for homelab data.
- **PostgreSQL**: DBMS for coding projects

### 6. AI and Local LLMs
- **Ollama/OpenWebUI**: Self-hosted generative AI service using Meta's Llama models (3.2) and an UI similar to ChatGPT with WebSearch, Image Generation, and TTS, STT capabilities.
- **Automatic1111**: Self-hosted generative AI service for creating images.
- **PyTorch**: Python based library and framework for tuning and developing neural networks and LLMs.

### 7. Other Services
- **Home Assistant**: Smart home automation platform to control IoT devices.

## Architecture Overview
This homelab is built with the following components:
1. **Host Hardware**: Servers (physical or virtualized) running Proxmox, this includes a Xeon based Dell workstation, a few Raspberry Pi's clustered together, my desktop and, my laptop.
2. **Virtualization Layer**: Proxmox manages most VMs, and LXC containers, Docker handles most services on the VMs, the VMs are running mostly RHEL and Ubuntu Server, a Windows Server instance simulates AD and Group Policy.
4. **Networking**: TwinGate secures and manages traffic to/from the lab, firewalls and access control lists are done through my router (Xfinity base router with plans to move to Ubiquiti in the next year)
5. **Monitoring & Logging**: Prometheus, Grafana, Wazuh and ELK stack to monitor and visualize metrics and logs.
