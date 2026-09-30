# dg_vault/gitlab

Installe GitLab CE sur Rocky/EL 9 depuis le depot officiel GitLab, avec une version explicite.

## Variables

- `gitlab_ce_version` : version RPM complete a installer, par exemple `19.3.2-ce.0.el9`.
- `gitlab_external_url` : URL publique de GitLab, par defaut `http://{{ ansible_fqdn | default(inventory_hostname) }}`.
- `gitlab_manage_firewalld` : ouvre `http`, `https` et `ssh` via firewalld si `true`.
- `gitlab_versionlock_enabled` : verrouille la version GitLab installee si `true`.
- `gitlab_repo_gpgkeys` : cles GPG du depot et des paquets RPM GitLab CE.
- `gitlab_additional_config` : bloc libre ajoute a `/etc/gitlab/gitlab.rb`.

## GPG RPM

GitLab utilise une cle pour signer les metadonnees du depot et une autre cle pour signer les paquets Omnibus. Le role importe donc plusieurs cles :

- `https://packages.gitlab.com/gpgkey/gpg.key` : metadonnees du depot.
- `https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-CB947AD886C8E8FD.pub.gpg` : paquets GitLab CE recents.
- `https://packages.gitlab.com/gitlab/gitlab-ce/gpgkey/gitlab-gitlab-ce-3D645A26AB9FBD22.pub.gpg` : anciens paquets GitLab CE.

## Exemple

```yaml
- hosts: gitlab
  become: true
  roles:
    - role: dg_vault/gitlab
      vars:
        gitlab_ce_version: "19.3.2-ce.0.el9"
        gitlab_external_url: "https://gitlab.example.com"
```

## Migration Sameersbn vers GitLab CE Omnibus

Objectif : migrer une instance Docker Sameersbn vers une instance GitLab CE Omnibus Rocky 9 avec la meme version GitLab, par exemple `19.3.2-ce.0`.

Points importants :

- Le restore GitLab doit se faire vers exactement la meme version GitLab et le meme type CE/EE que la source.
- Prevoir une fenetre de maintenance : pendant l'export, bloquer les push et les jobs CI.
- Les backups contiennent des donnees sensibles : repositories, base PostgreSQL, uploads, artifacts, LFS, packages et parfois secrets.
- Pour 150 repos, verifier l'espace disque disponible sur la source, la cible et le repertoire de transfert.

### 1. Identifier la version source

Sur l'hote Docker Sameersbn :

```bash
docker ps --format 'table {{.Names}}\t{{.Image}}'
docker exec -it <gitlab_container> gitlab-rake gitlab:env:info
```

Noter la version GitLab exacte. La variable Ansible cible doit correspondre :

```yaml
gitlab_ce_version: "19.3.2-ce.0.el9"
```

### 2. Preparer la cible Rocky 9

Installer GitLab avec ce role :

```bash
ansible-playbook -i inventory <playbook>.yml -l gitlab-shiva
```

Verifier la version installee :

```bash
sudo gitlab-rake gitlab:env:info
sudo gitlab-ctl status
```

Si la cible a deja ete initialisee et contient des donnees de test, ne rien garder dessus avant le restore.

### 3. Figer la source

Sur la source Sameersbn, annoncer la maintenance puis empecher les changements applicatifs :

```bash
docker stop <gitlab_runner_container>
docker exec -it <gitlab_container> gitlab-ctl stop sidekiq
docker exec -it <gitlab_container> gitlab-ctl stop puma
```

Si l'image Sameersbn utilise Unicorn au lieu de Puma :

```bash
docker exec -it <gitlab_container> gitlab-ctl stop unicorn
```

Verifier que PostgreSQL et Redis restent demarres, car le backup en a besoin :

```bash
docker exec -it <gitlab_container> gitlab-ctl status
```

### 4. Exporter l'application GitLab

Selon la version de l'image Sameersbn, la commande disponible peut etre `gitlab-backup` ou `gitlab-rake`.

Essayer d'abord :

```bash
docker exec -t <gitlab_container> gitlab-backup create
```

Si la commande n'existe pas :

```bash
docker exec -t <gitlab_container> gitlab-rake gitlab:backup:create
```

Le backup genere un fichier de type :

```text
<timestamp>_<version>_gitlab_backup.tar
```

Le repertoire depend du montage Sameersbn. Chercher le fichier :

```bash
docker exec -it <gitlab_container> find / -name '*_gitlab_backup.tar' 2>/dev/null
```

Copier le backup sur l'hote Docker :

```bash
docker cp <gitlab_container>:/home/git/data/backups/<backup_file> ./<backup_file>
```

Adapter le chemin si le `find` retourne un autre repertoire.

### 5. Exporter la configuration et les secrets

Copier les fichiers de configuration utiles depuis la source. Les chemins Sameersbn varient selon les montages, donc verifier les volumes du conteneur :

```bash
docker inspect <gitlab_container> --format '{{json .Mounts}}'
```

Sauvegarder au minimum :

```bash
docker cp <gitlab_container>:/home/git/gitlab/config/secrets.yml ./sameersbn-secrets.yml
docker cp <gitlab_container>:/home/git/gitlab/config/gitlab.yml ./sameersbn-gitlab.yml
```

Si ces fichiers ne sont pas a ces chemins, les rechercher :

```bash
docker exec -it <gitlab_container> find /home/git -name secrets.yml -o -name gitlab.yml
```

Garder aussi une copie du `docker-compose.yml`, du `.env`, et de la configuration SMTP/LDAP/OAuth/registry/pages si utilisee.

### 6. Transferer vers la cible

Depuis l'hote source :

```bash
scp <backup_file> root@gitlab-shiva:/var/opt/gitlab/backups/
scp sameersbn-secrets.yml sameersbn-gitlab.yml root@gitlab-shiva:/root/
```

Sur la cible :

```bash
sudo chown git:git /var/opt/gitlab/backups/<backup_file>
sudo chmod 0600 /var/opt/gitlab/backups/<backup_file>
```

### 7. Adapter les secrets sur Omnibus

Sur GitLab Omnibus, les secrets sont dans :

```text
/etc/gitlab/gitlab-secrets.json
```

Sameersbn utilise souvent `secrets.yml`. Ne pas l'ecraser aveuglement dans Omnibus. Il faut reporter les valeurs importantes, notamment `secret_key_base`, `otp_key_base`, `db_key_base` et les secrets CI/JWT si presents, dans le format attendu par la version Omnibus cible.

Avant modification :

```bash
sudo cp -a /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.before-restore
sudo cp -a /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.before-restore
```

Puis ajuster `/etc/gitlab/gitlab-secrets.json` prudemment. Si cette etape est mauvaise, les tokens, variables CI chiffrees, integrations et 2FA peuvent etre inutilisables apres restore.

### 8. Restaurer le backup sur Omnibus

Extraire l'identifiant du backup sans le suffixe `_gitlab_backup.tar`.

Exemple :

```text
1724242424_2026_09_21_19.3.2-ce_gitlab_backup.tar
```

donne :

```text
1724242424_2026_09_21_19.3.2-ce
```

Sur la cible :

```bash
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl status
sudo gitlab-backup restore BACKUP=<backup_id>
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

Si GitLab demande confirmation, repondre `yes`.

### 9. Controles apres restore

Verifier l'etat general :

```bash
sudo gitlab-rake gitlab:check SANITIZE=true
sudo gitlab-rake gitlab:env:info
sudo gitlab-ctl status
```

Verifier fonctionnellement :

- Connexion admin et utilisateurs.
- Nombre de groupes et projets.
- Acces web a plusieurs projets.
- Clone SSH et HTTPS.
- Push sur un depot de test.
- Issues, merge requests, wiki, snippets.
- Artifacts, LFS, uploads et packages si utilises.
- Runners, webhooks, deploy keys, variables CI/CD.
- Envoi mail et integrations externes.

Pour comparer rapidement les repositories :

```bash
sudo gitlab-rails runner 'puts Project.count'
sudo gitlab-rails runner 'puts Namespace.count'
```

### 10. Redemarrer ou rebrancher les runners

Quand la cible est validee :

```bash
docker stop <ancien_gitlab_container>
docker start <gitlab_runner_container>
```

Si les runners pointent vers l'ancien hostname ou un token obsolete, les reenregistrer.

### 11. Bascule DNS et surveillance

Basculer le DNS ou le reverse proxy vers la nouvelle cible, puis surveiller :

```bash
sudo gitlab-ctl tail
sudo gitlab-ctl status
df -h
free -m
```

Conserver l'ancien serveur arrete mais intact jusqu'a validation complete.

### 12. Rollback

Si la migration echoue avant ouverture aux utilisateurs :

```bash
sudo gitlab-ctl stop
```

Puis redemarrer l'ancien GitLab Sameersbn et remettre DNS/reverse proxy vers la source :

```bash
docker start <ancien_gitlab_container>
docker start <gitlab_runner_container>
```

Ne pas faire de rollback simple si des utilisateurs ont deja travaille sur la nouvelle instance, sinon les nouvelles donnees seront perdues.

## References

- Backup GitLab : https://docs.gitlab.com/administration/backup_restore/backup_gitlab/
- Restore GitLab : https://docs.gitlab.com/administration/backup_restore/restore_gitlab/
- GitLab Docker backup : https://docs.gitlab.com/install/docker/backup/
- GitLab package signatures : https://docs.gitlab.com/omnibus/update/package_signatures/
