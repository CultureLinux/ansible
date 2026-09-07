# Ansible 
## Installation

```
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.crypto
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.general
```

### Pre-requis

#### Rocky9 webstack ENVVARS

```
export MARIADB_VERSION="10.11"
export MARIADB_ROOT_PASS="password"
export MARIADB_BIND_ADDRESS="0.0.0.0"
```

