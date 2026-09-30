#!/bin/bash

# Charger manuellement les variables d'environnement
source /etc/default/minio

# Fallback si non défini
MINIO_OPTS=${MINIO_OPTS:-""}

exec /usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES