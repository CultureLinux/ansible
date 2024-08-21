#WEBSTACK
alias nginxconf='cd /etc/nginx/sites-available/'
alias nginxtest='nginx -c /etc/nginx/nginx.conf -t'
alias nginxrestart='nginx -c /etc/nginx/nginx.conf -t && systemctl restart nginx && systemctl status nginx '
alias nginxreload='nginx -c /etc/nginx/nginx.conf -t && systemctl reload nginx && systemctl status nginx '
