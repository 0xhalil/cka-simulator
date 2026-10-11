#!/usr/bin/env bash
# The "base" host the candidate lands on (like [candidate@base] in the real exam):
# web terminal (ttyd), ssh client, kubectl/helm binaries but NO cluster access by itself.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cloud-init status --wait >/dev/null 2>&1 || true
systemctl disable --now unattended-upgrades apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
echo 'DPkg::Lock::Timeout "600";' > /etc/apt/apt.conf.d/99lock-timeout
TTYD_VERSION=${TTYD_VERSION:-1.7.7}

echo "preserve_hostname: true" > /etc/cloud/cloud.cfg.d/99-cka.cfg
hostnamectl set-hostname base
grep -q "127.0.1.1 base" /etc/hosts || echo "127.0.1.1 base" >> /etc/hosts
apt-get update -qq
apt-get install -y -qq vim tmux jq bash-completion curl netcat-openbsd dnsutils >/dev/null

id candidate >/dev/null 2>&1 || useradd -m -s /bin/bash candidate
echo "candidate ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/candidate

ARCH=$(uname -m)   # aarch64 | x86_64
if [ ! -x /usr/local/bin/ttyd ]; then
  curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ARCH}" -o /usr/local/bin/ttyd
  chmod +x /usr/local/bin/ttyd
fi

cat > /etc/systemd/system/ttyd.service <<'EOF'
[Unit]
Description=CKA simulator web terminal
After=network.target
[Service]
User=candidate
WorkingDirectory=/home/candidate
Environment=TERM=xterm-256color
ExecStart=/usr/local/bin/ttyd -W -p 7681 -t fontSize=15 -t 'theme={"background":"#1e1e1e"}' -t titleFixed=Terminal /bin/bash -l
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now ttyd >/dev/null
systemctl restart ttyd

cat > /home/candidate/.bash_aliases <<'EOF'
alias k=kubectl
EOF
cat > /home/candidate/.vimrc <<'EOF'
set tabstop=2 shiftwidth=2 expandtab
EOF
chown candidate: /home/candidate/.bash_aliases /home/candidate/.vimrc
echo "base ready"

# quiet ssh logins (no MOTD), closer to the exam terminal
chmod -x /etc/update-motd.d/* 2>/dev/null || true
