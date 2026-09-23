# Server setup (Ubuntu)

Connect with Session Manager or ssh. Then, in this order.

## Packages

```sh
sudo apt update && sudo apt install -y docker.io docker-compose-v2 postgresql nginx certbot python3-certbot-nginx awscli
```

## Database

Create the role and the database with the role as owner. On Postgres 15 and newer the `public` schema is not writable by other roles, so a database created without `OWNER` makes the first migration fail with "permission denied for schema public".

```sh
sudo -u postgres psql -c "CREATE ROLE <app> LOGIN PASSWORD '<password>'" -c "CREATE DATABASE <app> OWNER <app>"
```

If it was already created the other way: `ALTER DATABASE <app> OWNER TO <app>` and, inside the database, `ALTER SCHEMA public OWNER TO <app>`.

## Files

```sh
sudo mkdir -p /opt/<app>
# copy docker-compose.yml deploy.sh nginx.conf app.env.example into /opt/<app>
# (backup.sh comes from the postgres-s3-backup skill)
cd /opt/<app>
sudo chmod +x deploy.sh backup.sh          # copies through scp or paste lose the bit
sudo mv app.env.example <app>.env && sudo chmod 600 <app>.env
python3 -c "import secrets; print(secrets.token_hex(32))"   # for the secret key
sudo nano <app>.env                         # fill every value; reading it needs sudo
```

Session Manager has no file transfer. Paste with heredocs or scp once from a machine with a key.

## nginx and TLS

```sh
sudo cp nginx.conf /etc/nginx/sites-available/<app>
sudo ln -s /etc/nginx/sites-available/<app> /etc/nginx/sites-enabled/<app>
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

Only after DNS resolves to this box:

```sh
sudo certbot --nginx -d <api-hostname> --agree-tos -m <email> --redirect
```

certbot rewrites the site for HTTPS and installs its own renewal timer. It registers an ACME account under the email, so ask before running it on someone's behalf.

## Backup cron

The `postgres-s3-backup` skill owns the script and the restore drill; the cron line is repeated here so the setup order is complete.

```sh
echo '0 3 * * * root /opt/<app>/backup.sh' | sudo tee /etc/cron.d/<app>-backup
sudo /opt/<app>/backup.sh    # once, to prove the bucket write works
```

The clock is UTC.

## Reading the curl results

Checks from outside or from the box with a `Host:` header:

| `curl -H 'Host: <api-hostname>' http://127.0.0.1/api/health` | Meaning |
|---|---|
| 404 with nginx welcome page | Site file not enabled, or the default site is still answering |
| 502 | Site enabled and proxying; nothing listening on the backend port yet |
| 200 with the health body | Backend up behind nginx |
| https fails, http works | certbot not run yet |
| https 200, http 301 | Done |
