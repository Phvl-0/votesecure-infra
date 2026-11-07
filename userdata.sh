#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
cat > /etc/ssh/sshd_config.d/10-hardening.conf << 'CONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
CONF
sshd -t && systemctl reload ssh
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
apt-get install -y fail2ban ca-certificates curl unzip
cat > /etc/fail2ban/jail.local << 'CONF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
CONF
systemctl enable --now fail2ban
systemctl restart fail2ban
# Docker engine metrics on loopback, written before Docker is installed so the first start picks it up
mkdir -p /etc/docker
echo '{"metrics-addr":"127.0.0.1:9323"}' > /etc/docker/daemon.json
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# 1 GB swap file as a safety net for the 2 GB instance
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
# AWS CLI v2, so the VM can read Parameter Store with its role
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip
mkdir -p /home/ubuntu/votesecure/backups /home/ubuntu/votesecure/monitoring
chown -R ubuntu:ubuntu /home/ubuntu/votesecure
echo done > /var/lib/votesecure-bootstrap-done
