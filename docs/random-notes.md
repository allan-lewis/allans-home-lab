# Miscellaneous Notes

## Restore a Postgres DB Dump (Authentik - PG 16)

```bash
docker run --rm \
  --network authentik_default \
  -v "/path/to/backups:/backups:ro" \
  -e PGPASSWORD='YOUR_DB_PASSWORD' \
  postgres:16 \
  pg_restore \
    -h <postgres_service_name_or_container_name> \
    -U <db_user> \
    -d <db_name> \
    --clean --if-exists \
    --no-owner --no-privileges \
    --exit-on-error \
    /backups/authentik.dump
```

## Run Node Exporter on Asustor NAS

Cleanup any stale Docker containers

```bash
sudo docker rm node_exporter
```

Run Node Exporter

```bash
sudo docker run -d --name node_exporter -p 9100:9100 --restart unless-stopped prom/node-exporter
```
