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

#DNF
alias dnfu='dnf upgrade'
alias dnfi='dnf install'
alias dnfp='dnf provides'

#FIREWALL
alias fwlist='firewall-cmd --info-zone public'
function fwaddport(){
        firewall-cmd --add-port=${1} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
function fwaddportfrom(){
        firewall-cmd --add-port=${1} --add-source=${2} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
function fwremport(){
        firewall-cmd --remove-port=${1} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
function fwremportfrom(){
        firewall-cmd --remove-port=${1} --remove-source=${2} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
function fwaddservice(){
        firewall-cmd --add-service=${1} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
function fwremservice(){
        firewall-cmd --remove-service=${1} --permanent && firewall-cmd --reload
        firewall-cmd --info-zone public
}
