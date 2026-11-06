# votesecure-infra

Notes for running votesecure-fullstack on AWS.

## VM
- Region eu-north-1, t3.small (2 vCPU, 2 GiB), Ubuntu 24.04, 20 GB gp3, IMDSv2 required
- Key pair votesecure-key (ed25519); the private key lives only in ~/.ssh and never in Git
- Security group votesecure-sg: SSH (22) only from my own IP /32, HTTP (80) and HTTPS (443) open

## Hardening (done by hand on the VM)
1. apt update and upgrade
2. /etc/ssh/sshd_config.d/10-hardening.conf: root login off, password login off, MaxAuthTries 3
3. ufw: deny incoming by default, allow 22, 80 and 443
4. fail2ban sshd jail: 5 failures in 10 minutes means a 1 hour ban
5. Docker Engine and Compose plugin from Docker's official apt repo, used with sudo

## Verification
- Key login works; password login is refused with "Permission denied (publickey)"
- ufw is active; the fail2ban sshd jail is running

## Limits and notes
- Ports published by Docker bypass ufw, so only nginx will publish a port and the security group is the outer wall
- The SSH rule is tied to my home IP; if the IP changes, update the rule instead of opening port 22 to everyone
- Private key and any .env files stay out of Git
