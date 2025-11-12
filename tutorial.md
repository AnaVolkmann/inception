# Inception - Complete Tutorial

[![Tutorial](https://img.shields.io/badge/📚_Read_Complete-TUTORIAL-blue?style=for-the-badge)](./tutorial.md)

**👆 New to this project? Click above for complete step-by-step instructions!**

</div>
## Table of Contents

1. [Virtual Machine Setup](#1-virtual-machine-setup)
2. [System Configuration](#2-system-configuration)
3. [Docker Installation](#3-docker-installation)
4. [Project Structure](#4-project-structure)
5. [MariaDB Container](#5-mariadb-container)
6. [WordPress Container](#6-wordpress-container)
7. [NGINX Container](#7-nginx-container)
8. [Docker Compose](#8-docker-compose)
9. [Makefile](#9-makefile)
10. [Testing](#10-testing)
11. [Final Verification](#11-final-verification)

---

## 1. Virtual Machine Setup

### Download Debian 11

Download the Debian 11 (Bullseye) network installation ISO:
```bash
cd ~/Downloads
wget https://cdimage.debian.org/cdimage/archive/11.11.0/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso
```

### Create Virtual Machine

Using VirtualBox:

1. Click "New"
2. Name: inception
3. Type: Linux
4. Version: Debian (64-bit)
5. Memory: 4096 MB
6. Hard disk: Create new VDI, Dynamically allocated, 30 GB

Additional configuration:
- System > Processor: 2 CPUs
- Storage > Controller IDE: Select the Debian ISO
- Network > Adapter 1: Bridged Adapter

### Install Debian 11

Boot the VM and follow the installation:

1. Select "Install" (not graphical install)
2. Language: English
3. Location: Your location
4. Keyboard: American English
5. Hostname: inception
6. Domain name: Leave empty
7. Root password: Create and record a strong password
8. Full name: Your name
9. Username: Your 42 login
10. User password: Create and record a strong password
11. Partitioning: Guided - use entire disk
12. Partition scheme: All files in one partition
13. Confirm partitioning: Yes
14. Additional CD: No
15. Mirror country: Your country
16. Mirror: Default (deb.debian.org)
17. HTTP proxy: Leave empty
18. Participate in survey: No
19. Software selection: Uncheck all, leave only "standard system utilities"
20. Install GRUB: Yes, select /dev/sda
21. Finish installation and reboot

---

## 2. System Configuration

### Configure sudo

Log in with your username and password.

Switch to root:
```bash
su -
```

Enter root password.

Update system and install sudo:
```bash
apt update
apt upgrade -y
apt install -y sudo
```

Add your user to sudo group:
```bash
usermod -aG sudo <your_username>
```

Exit root and log out:
```bash
exit
exit
```

Log in again with your user account.

### Install Basic Tools
```bash
sudo apt update
sudo apt install -y vim git curl wget make ca-certificates gnupg lsb-release tree
```

Verify installations:
```bash
which vim git make
```

---

## 3. Docker Installation

### Add Docker Repository

Create keyring directory:
```bash
sudo mkdir -p /etc/apt/keyrings
```

Add Docker GPG key:
```bash
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

Add Docker repository:
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker

Update package index:
```bash
sudo apt update
```

Install Docker packages:
```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Add user to docker group:
```bash
sudo usermod -aG docker $USER
```

Log out and log in again for group changes to take effect:
```bash
exit
```

Log in again.

### Verify Docker Installation

Test Docker:
```bash
docker run hello-world
```

Check versions:
```bash
docker --version
docker compose version
```

---

## 4. Project Structure

### Create Directory Structure
```bash
cd ~
mkdir -p inception/srcs/requirements/{mariadb,wordpress,nginx}/{conf,tools}
```

Create data directories:
```bash
sudo mkdir -p /home/$USER/data/{mariadb,wordpress}
sudo chown -R $USER:$USER /home/$USER/data
```

Verify structure:
```bash
cd inception
tree -L 3
```

### Create Environment File
```bash
cd ~/inception/srcs
```

Create `.env` file:
```bash
cat > .env << 'EOF'
# Domain
DOMAIN_NAME=your_login.42.fr

# MariaDB
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_wp_password

# WordPress Admin
WP_ADMIN_USER=boss
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@student.42.fr

# WordPress User
WP_USER=author
WP_USER_PASSWORD=your_author_password
WP_USER_EMAIL=author@student.42.fr

# WordPress
WP_TITLE=Inception Project
WP_URL=https://your_login.42.fr
EOF
```

Replace `your_login` and passwords with actual values.

Set appropriate permissions:
```bash
chmod 600 .env
```

Create `.env.example`:
```bash
cp .env .env.example
```

Edit `.env.example` and replace actual values with placeholders:
```bash
vim .env.example
```

### Create .gitignore
```bash
cd ~/inception
cat > .gitignore << 'EOF'
.env
srcs/.env
data/
*.log
.DS_Store
Thumbs.db
.vscode/
.idea/
*.swp
*.swo
*~
EOF
```

---

## 5. MariaDB Container

### Create Dockerfile
```bash
cd ~/inception/srcs/requirements/mariadb
```

Create Dockerfile:
```bash
cat > Dockerfile << 'EOF'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["init_db.sh"]
EOF
```

### Create Initialization Script
```bash
cd tools
```

Create `init_db.sh`:
```bash
cat > init_db.sh << 'EOF'
#!/bin/bash

if [ ! -d "/var/lib/mysql/wordpress" ]; then
    echo "Initializing MariaDB..."
    
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    mysqld --user=mysql --bootstrap << MYSQL_SCRIPT
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
MYSQL_SCRIPT

    echo "MariaDB initialized!"
fi

sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/mysql/mariadb.conf.d/50-server.cnf

echo "Starting MariaDB..."
exec mysqld --user=mysql --console
EOF
```

Make script executable:
```bash
chmod +x init_db.sh
```

### Test Build
```bash
cd ~/inception/srcs/requirements/mariadb
docker build -t mariadb_test .
```

Verify image was created:
```bash
docker images | grep mariadb_test
```

Remove test image:
```bash
docker rmi mariadb_test
```

---

## 6. WordPress Container

### Create Dockerfile
```bash
cd ~/inception/srcs/requirements/wordpress
```

Create Dockerfile:
```bash
cat > Dockerfile << 'EOF'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4 \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-cli \
    php7.4-curl \
    php7.4-gd \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    php7.4-intl \
    wget \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html /run/php && \
    chown -R www-data:www-data /var/www/html

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["setup.sh"]
EOF
```

### Create PHP-FPM Configuration
```bash
cd conf
```

Create `www.conf`:
```bash
cat > www.conf << 'EOF'
[www]
user = www-data
group = www-data
listen = 9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
clear_env = no
EOF
```

### Create Setup Script
```bash
cd ../tools
```

Create `setup.sh`:
```bash
cat > setup.sh << 'EOF'
#!/bin/bash

cd /var/www/html

echo "Waiting for database..."
RETRY_COUNT=0
MAX_RETRIES=30

until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: Database not ready after $MAX_RETRIES attempts!"
        exit 1
    fi
    echo "Database not ready... attempt $RETRY_COUNT/$MAX_RETRIES"
    sleep 5
done
echo "Database ready!"

if [ ! -f "wp-config.php" ]; then
    echo "Installing WordPress..."
    
    wp core download --allow-root
    
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root
    
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
    
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    
    chown -R www-data:www-data /var/www/html
    
    echo "WordPress installed!"
else
    echo "WordPress already installed."
fi

echo "Starting PHP-FPM..."
exec /usr/sbin/php-fpm7.4 -F
EOF
```

Make script executable:
```bash
chmod +x setup.sh
```

---

## 7. NGINX Container

### Create Dockerfile
```bash
cd ~/inception/srcs/requirements/nginx
```

Create Dockerfile:
```bash
cat > Dockerfile << 'EOF'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 443

ENTRYPOINT ["setup.sh"]
CMD ["nginx", "-g", "daemon off;"]
EOF
```

### Create NGINX Configuration
```bash
cd conf
```

Create `nginx.conf`:
```bash
cat > nginx.conf << 'EOF'
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
```

### Create SSL Setup Script
```bash
cd ../tools
```

Create `setup.sh`:
```bash
cat > setup.sh << 'EOF'
#!/bin/bash

if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then
    echo "Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=PT/ST=Porto/L=Porto/O=42Porto/CN=${DOMAIN_NAME}"
    
    chmod 600 /etc/nginx/ssl/nginx.key
    chmod 644 /etc/nginx/ssl/nginx.crt
    echo "SSL certificate generated!"
fi

exec "$@"
EOF
```

Make script executable:
```bash
chmod +x setup.sh
```

---

## 8. Docker Compose

### Create docker-compose.yml
```bash
cd ~/inception/srcs
```

Create `docker-compose.yml`:
```bash
cat > docker-compose.yml << 'EOF'
services:
  mariadb:
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    container_name: mariadb
    image: mariadb
    restart: always
    networks:
      - inception
    volumes:
      - mariadb_data:/var/lib/mysql
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 5s
      timeout: 3s
      retries: 10

  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    image: wordpress
    restart: always
    depends_on:
      mariadb:
        condition: service_healthy
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    env_file:
      - .env

  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    image: nginx
    restart: always
    depends_on:
      - wordpress
    ports:
      - "443:443"
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    env_file:
      - .env

networks:
  inception:
    name: inception
    driver: bridge

volumes:
  mariadb_data:
    name: mariadb_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/YOUR_USERNAME/data/mariadb

  wordpress_data:
    name: wordpress_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/YOUR_USERNAME/data/wordpress
EOF
```

Replace `YOUR_USERNAME` with your actual username:
```bash
sed -i "s/YOUR_USERNAME/$USER/g" docker-compose.yml
```

Verify the configuration:
```bash
docker compose config
```

---

## 9. Makefile

### Create Makefile
```bash
cd ~/inception
```

Create `Makefile`:
```bash
cat > Makefile << 'EOF'
NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/YOUR_USERNAME/data

all: up

up:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "Starting containers..."
	@docker compose -f $(COMPOSE_FILE) up -d --build

down:
	@echo "Stopping containers..."
	@docker compose -f $(COMPOSE_FILE) down

stop:
	@docker compose -f $(COMPOSE_FILE) stop

start:
	@docker compose -f $(COMPOSE_FILE) start

status:
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

clean: down
	@echo "Removing Docker resources..."
	@docker system prune -af
	@docker volume rm -f mariadb_data wordpress_data 2>/dev/null || true

fclean: clean
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)/mariadb
	@sudo rm -rf $(DATA_PATH)/wordpress
	@docker network rm inception 2>/dev/null || true
	@echo "Full cleanup complete!"

re: fclean all

.PHONY: all up down stop start status logs clean fclean re
EOF
```

Replace `YOUR_USERNAME`:
```bash
sed -i "s/YOUR_USERNAME/$USER/g" Makefile
```

---

## 10. Testing

### Configure Hosts File

Add domain to hosts file:
```bash
echo "127.0.0.1 your_login.42.fr" | sudo tee -a /etc/hosts
```

Replace `your_login` with your actual login.

Verify:
```bash
grep your_login.42.fr /etc/hosts
```

### Build and Start
```bash
cd ~/inception
make
```

Wait 2-3 minutes for initialization.

### Verify Containers
```bash
docker ps
```

Expected output: Three containers (mariadb, wordpress, nginx) with status "Up".

### Check Logs
```bash
# All logs
make logs

# Specific container
docker logs mariadb
docker logs wordpress
docker logs nginx
```

### Test Database
```bash
# Ping database
docker exec wordpress mysqladmin ping -h mariadb -u wpuser -p<password>

# Access database
docker exec -it mariadb mysql -u root -p<password>
```

Inside MySQL:
```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT User, Host FROM mysql.user;
exit
```

### Test WordPress
```bash
# Check WordPress version
docker exec wordpress wp core version --allow-root

# List users
docker exec wordpress wp user list --allow-root
```

Expected output: Two users (administrator and author).

### Test SSL/TLS
```bash
# Check SSL configuration
docker exec nginx nginx -T 2>/dev/null | grep ssl_protocols

# Test TLS 1.2
openssl s_client -connect localhost:443 -tls1_2 </dev/null 2>/dev/null | grep "Protocol"

# Test TLS 1.3
openssl s_client -connect localhost:443 -tls1_3 </dev/null 2>/dev/null | grep "Protocol"
```

### Test Network
```bash
# NGINX to WordPress
docker exec nginx ping -c 3 wordpress

# WordPress to MariaDB
docker exec wordpress ping -c 3 mariadb
```

### Access Website

Open web browser:
```bash
firefox https://your_login.42.fr
```

Accept security warning for self-signed certificate.

Expected: WordPress site loads successfully.

### Test Login

Navigate to: `https://your_login.42.fr/wp-admin`

Login with administrator credentials:
- Username: boss (or as configured in .env)
- Password: your_admin_password

Verify access to WordPress dashboard.

Logout and login with author credentials:
- Username: author (or as configured in .env)
- Password: your_author_password

Verify limited access appropriate for author role.

---

## 11. Final Verification

### Test Persistence

Create a post in WordPress:
1. Login as administrator
2. Posts > Add New
3. Create a post titled "Persistence Test"
4. Publish

Stop containers:
```bash
make down
```

Restart containers:
```bash
make
```

Wait 2-3 minutes.

Verify post still exists at `https://your_login.42.fr`.

### Test Auto-Restart

Reboot the virtual machine:
```bash
sudo reboot
```

After system restart, log in and verify:
```bash
docker ps
```

All three containers should be running.

Access website to confirm functionality:
```bash
firefox https://your_login.42.fr
```
