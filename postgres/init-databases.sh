#!/bin/bash
# Create databases and users for each service
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER metabase WITH PASSWORD '${METABASE_DB_PASSWORD}';
    CREATE DATABASE metabase OWNER metabase;

    CREATE USER mattermost WITH PASSWORD '${MATTERMOST_DB_PASSWORD}';
    CREATE DATABASE mattermost OWNER mattermost;
EOSQL
