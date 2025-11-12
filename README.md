# Inception

A system administration project focused on containerization using Docker and Docker Compose. This project involves setting up a multi-container infrastructure with NGINX, WordPress, and MariaDB.

[![Tutorial](https://img.shields.io/badge/📚_Read_Complete-TUTORIAL-blue?style=for-the-badge)](./tutorial.md)

**👆 New to this project? Click above for step-by-step instructions from VM setup to deployment!**

</div>

## Table of Contents

- [Introduction](#introduction)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Services](#services)
- [Configuration](#configuration)
- [Testing](#testing)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Author](#author)

## Introduction

The Inception project implements a complete web infrastructure using Docker containers. Each service runs in its own isolated container, communicating through a custom Docker network. The infrastructure includes SSL/TLS encryption, automated WordPress installation, and persistent data storage.

### Key Features

- Custom Dockerfiles based on Debian Bullseye
- NGINX with SSL/TLS 1.2/1.3 encryption
- WordPress with PHP-FPM and WP-CLI
- MariaDB database server
- Docker Compose orchestration
- Persistent volumes for data storage
- Automatic container restart on failure
- Two WordPress users (administrator and author)

## Project Structure
```
inception/
├── Makefile
├── README.md
├── docs/
│   └── TUTORIAL.md
└── srcs/
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── init_db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── setup.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup.sh
```

## Prerequisites

### System Requirements

- Operating System: Debian 11 (Bullseye)
- Memory: 4GB RAM minimum
- Storage: 30GB available disk space
- Docker: Version 20.10 or higher
- Docker Compose: Version 2.0 or higher

### Required Knowledge

- Linux command line operations
- Basic Docker concepts
- Understanding of web server architecture
- Network configuration basics

## Installation

### Clone the Repository
```bash
git clone <repository-url> inception
cd inception
```

### Create Environment File
```bash
cp srcs/.env.example srcs/.env
```

Edit the `.env` file with your configuration:
```bash
vim srcs/.env
```

Required variables:
- `DOMAIN_NAME`: Your domain (e.g., login.42.fr)
- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `MYSQL_DATABASE`: Database name (wordpress)
- `MYSQL_USER`: Database user
- `MYSQL_PASSWORD`: Database password
- `WP_ADMIN_USER`: WordPress admin username (must NOT contain 'admin')
- `WP_ADMIN_PASSWORD`: WordPress admin password
- `WP_ADMIN_EMAIL`: WordPress admin email
- `WP_USER`: Second WordPress user
- `WP_USER_PASSWORD`: Second user password
- `WP_USER_EMAIL`: Second user email

### Configure Hosts File

Add your domain to the system hosts file:
```bash
echo "127.0.0.1 your_login.42.fr" | sudo tee -a /etc/hosts
```

## Usage

### Build and Start Services
```bash
make
```

Wait approximately 2-3 minutes for all services to initialize.

### Verify Installation

Check that all containers are running:
```bash
docker ps
```

Expected output: Three containers (nginx, wordpress, mariadb) with status "Up".

### Access the Website

Open a web browser and navigate to:
```
https://your_login.42.fr
```

Note: You will see a security warning due to the self-signed SSL certificate. This is expected behavior. Click "Advanced" and accept the security exception.

### Available Commands
```bash
make          # Build and start all services
make down     # Stop all services
make stop     # Stop containers without removing them
make start    # Start stopped containers
make status   # Display container status
make logs     # View container logs
make clean    # Remove containers and images
make fclean   # Full cleanup including data volumes
make re       # Rebuild everything from scratch
```

## Architecture

The infrastructure consists of three primary services:
```
Internet (HTTPS:443)
    ↓
NGINX (Reverse Proxy + SSL/TLS)
    ↓ (FastCGI:9000)
WordPress (PHP-FPM)
    ↓ (MySQL:3306)
MariaDB (Database)
    ↓
Persistent Volumes (/home/login/data/)
```

### Network Configuration

All containers communicate through a custom Docker bridge network named "inception". Services reference each other by container name rather than IP address.

### Data Persistence

Two volumes ensure data persistence:
- MariaDB data: `/home/<login>/data/mariadb`
- WordPress files: `/home/<login>/data/wordpress`

Data persists even when containers are removed or rebuilt.

## Services

### NGINX

**Purpose**: Web server and reverse proxy with SSL/TLS encryption

**Configuration**:
- Listens on port 443 (HTTPS only)
- Uses self-signed SSL certificate
- Supports TLS 1.2 and TLS 1.3
- Proxies PHP requests to WordPress via FastCGI
- Serves static files directly

**Files**:
- `Dockerfile`: Based on Debian Bullseye, installs NGINX and OpenSSL
- `nginx.conf`: Server configuration
- `setup.sh`: Generates SSL certificate on first run

### WordPress

**Purpose**: Content management system with PHP processing

**Configuration**:
- Runs PHP-FPM on port 9000
- Installed automatically via WP-CLI
- Creates two users: administrator and author
- Connects to MariaDB for data storage

**Files**:
- `Dockerfile`: Based on Debian Bullseye, installs PHP 7.4-FPM and dependencies
- `www.conf`: PHP-FPM pool configuration
- `setup.sh`: Handles WordPress installation and user creation

### MariaDB

**Purpose**: Database server for WordPress

**Configuration**:
- Listens on port 3306 (internal network only)
- Creates database and users automatically
- Configured to accept remote connections from WordPress container

**Files**:
- `Dockerfile`: Based on Debian Bullseye, installs MariaDB server
- `init_db.sh`: Initializes database, creates users, sets permissions

## Configuration

### Environment Variables

The `.env` file contains all configuration variables. This file is not committed to version control for security reasons.

### SSL Certificate

A self-signed SSL certificate is generated automatically on first startup. The certificate is valid for 365 days and uses RSA 2048-bit encryption.

### WordPress Users

Two users are created automatically:
1. Administrator: Full site management capabilities
2. Author: Can create and publish posts

The administrator username must not contain the word "admin" or "administrator" per project requirements.

### Database

MariaDB creates:
- Database: wordpress
- Root user: Full privileges (localhost and remote)
- WordPress user: Privileges limited to wordpress database

## Testing

### Verify Containers
```bash
docker ps
```

All three containers should show status "Up".

### Check Logs
```bash
# All logs
docker compose -f srcs/docker-compose.yml logs

# Specific container
docker logs <container_name>
```

### Test SSL/TLS
```bash
# Verify TLS protocols
docker exec nginx nginx -T 2>/dev/null | grep ssl_protocols

# Test TLS 1.2 connection
openssl s_client -connect localhost:443 -tls1_2 </dev/null 2>/dev/null | grep "Protocol"

# Test TLS 1.3 connection
openssl s_client -connect localhost:443 -tls1_3 </dev/null 2>/dev/null | grep "Protocol"
```

### Test Database Connection
```bash
# From WordPress container
docker exec wordpress mysqladmin ping -h mariadb -u wpuser -p<password>

# Access database
docker exec -it mariadb mysql -u root -p<password>
```

### Test WordPress
```bash
# List WordPress users
docker exec wordpress wp user list --allow-root

# Check WordPress installation
docker exec wordpress wp core version --allow-root
```

### Test Network Connectivity
```bash
# NGINX to WordPress
docker exec nginx ping -c 3 wordpress

# WordPress to MariaDB
docker exec wordpress ping -c 3 mariadb
```

### Test Persistence

1. Create content in WordPress
2. Stop containers: `make down`
3. Restart containers: `make`
4. Verify content still exists

### Test Auto-Restart

Reboot the system:
```bash
sudo reboot
```

After system restart, containers should start automatically. Verify with:
```bash
docker ps
```

## Documentation

Complete documentation is available in the `docs/` directory:

- [TUTORIAL.md](docs/TUTORIAL.md): Step-by-step implementation guide

## Troubleshooting

### WordPress Configuration Page Appears

If the WordPress installation page appears instead of the configured site:
```bash
# Check WordPress logs
docker logs wordpress

# Verify database connection
docker exec wordpress mysqladmin ping -h mariadb -u wpuser -p<password>

# Restart WordPress container
docker restart wordpress
```

### Database Connection Errors
```bash
# Check MariaDB status
docker logs mariadb

# Verify user exists
docker exec mariadb mysql -u root -p<password> -e "SELECT User, Host FROM mysql.user;"

# Recreate user if necessary
docker exec -it mariadb mysql -u root -p<password>
# Then run: GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%' IDENTIFIED BY 'password';
```

### Port 443 Already in Use
```bash
# Find process using port 443
sudo lsof -i :443

# Stop conflicting service
sudo systemctl stop <service-name>
```

### Containers Not Starting
```bash
# View detailed logs
docker compose -f srcs/docker-compose.yml logs

# Rebuild without cache
make fclean
make
```

### Permission Issues
```bash
# Fix data directory permissions
sudo chown -R $USER:$USER /home/$USER/data
chmod -R 755 /home/$USER/data
```
