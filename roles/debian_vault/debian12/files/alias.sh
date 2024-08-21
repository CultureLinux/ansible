#SYSTEM
alias ll='ls -lrt'
alias lla='ls -alrt'
alias dfg='df -h'
alias dus='du -ms $(ls -A)'
alias dusx='du -xms $(ls -A)'
alias mkdir='mkdir -pv'
alias h='history'
alias j='jobs -l'
alias sbin='cd /usr/local/sbin'
alias vcron='vi /etc/crontab'
alias swd='watch -n1 df -m'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

#NETWORK
alias nets='netstat -tnlpv'
alias swn='watch -n1 netstat -tnlpv'
alias pingg='ping -c 1 8.8.8.8'
alias pingf='ping -c 1 free.fr'
alias swn='watch -n1 netstat -tnlpv'

#APT
alias aptu='apt update && apt upgrade'
alias apti='apt install'
alias apts='apt-cache search'
alias aptp='apt-file find'