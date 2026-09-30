#DOCKER
alias drt='docker compose down && docker compose up -d && docker compose logs -f'
alias dcs='docker ps'
alias dlogs='docker compose logs -f'
alias dcd='docker compose down'
alias dcu='docker compose up -d'
alias dcic="docker rm -f $(docker ps -a -q) ; docker rmi -f $(docker images -q)"
alias dckill="docker kill $(docker ps -q) && docker rm $(docker ps -a -q) && docker rmi $(docker images -q)"
