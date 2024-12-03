#!/bin/sh
# Issues https://1024.day

if [[ $EUID -ne 0 ]]; then
    clear
    echo "Error: This script must be run as root!"
    exit 1
fi

timedatectl set-timezone Asia/Shanghai

apt update && apt upgrade -y

# bashrc config
cat >/root/.bashrc<<EOF
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS -F'
alias ll='ls $LS_OPTIONS -lAF'
alias l='ls $LS_OPTIONS -lF'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'
alias mkdir='mkdir -p'
alias h='history'
EOF

# vim config
apt install vim git curl wget net-tools -y

echo "set mouse-=a" > /root/.vimrc

cat >/etc/vim/vimrc<<EOF
set mouse-=a

set number

set autoindent

set background=dark

set showmatch

set hlsearch

set incsearch

set ignorecase

set showcmd

set smartcase

set compatible

let g:skip_defaults_vim = 1

runtime! debian.vim

if has("syntax")
  syntax on
endif

if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif
EOF

# filelimits
cat >/etc/security/limits.conf<<EOF
* soft     nproc          655360
* hard     nproc          655360
* soft     nofile         655360
* hard     nofile         655360

root soft     nproc          655360
root hard     nproc          655360
root soft     nofile         655360
root hard     nofile         655360

bro soft     nproc          655360
bro hard     nproc          655360
bro soft     nofile         655360
bro hard     nofile         655360
EOF

echo "session required pam_limits.so" >> /etc/pam.d/common-session

echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive

echo "DefaultLimitNOFILE=655360" >> /etc/systemd/system.conf

# tcp window config
cat >/etc/sysctl.conf<<EOF
fs.file-max = 655360
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_slow_start_after_idle = 0
#net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rmem = 8192 262144 167772160
net.ipv4.tcp_wmem = 4096 16384 83886080
#net.ipv4.udp_rmem_min = 8192
#net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_notsent_lowat = 131072
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

# ssh key config
mkdir /root/.ssh

cat >/root/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmEa21AfBeBXPqEh7iP+ftQi9+eSIrQJVR2k3qxU3NdWLcTfVrH6FR1QP7DO01sIxdPcLdnahSW/PF+G/Wkr8dgY8kjBAkP1wD/5AJ8LLqMoYYC0FbrhD00lRDCxmJO/dgOEEHrELNkbLfn0Q8MQvUp/fHwq8L/uadWRrNPou3SKUfvAm20Ah4jz44MZeIueOJE6ZchQUuxh/sS7fwdbTnAm6aPzJGH30B5BFp4Ayf5lU76bDIgUeVPYt0YG9LXDRxBHrXFBklxloblhD9IhWPMs1r7jRsaeNJhvMTSfHSA/zeNT7xHIJO8AVMO0H2MB7qlIVpnSf5Ku61Yn5dqSr1 yeahwu404@gmail.com
EOF

sed -ri 's/^#?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -ri 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config;
sed -ri 's/^#?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config;
sed -ri 's/^#?AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys .ssh\/authorized_keys2/g' /etc/ssh/sshd_config;

# dns resolv.conf
echo -e "nameserver 8.8.8.8\search ." > /etc/resolv.conf

# remove excess
apt purge nftables apache2 fail2ban -y
rm -f linux-config.sh

sleep 3 && reboot >/dev/null 2>&1
