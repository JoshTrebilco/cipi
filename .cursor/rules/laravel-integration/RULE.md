---
description: "Laravel-specific patterns and integrations"
globs:
  - "lib/app.sh"
  - "lib/provision.sh"
  - "lib/release.sh"
  - "lib/reverb.sh"
alwaysApply: false
---

# Laravel Integration

## This project is specifically for Laravel applications

When working with app deployment and configuration, assume Laravel conventions.

## Artisan Commands

Run artisan commands as the app user:

```bash
sudo -u "$username" php "$home_dir/current/artisan" migrate --force
sudo -u "$username" php "$home_dir/current/artisan" config:cache
sudo -u "$username" php "$home_dir/current/artisan" queue:restart
```

## .env File Management

- Shared .env lives at `/home/{username}/.env`
- Symlinked into each release
- Use `set_env_var()` helper to update values:

```bash
set_env_var "$env_file" "APP_URL" "https://example.com"
set_env_var "$env_file" "DB_DATABASE" "$dbname"
```

## PHP-FPM Pools

Each app gets its own PHP-FPM pool at:
`/etc/php/{version}/fpm/pool.d/{username}.conf`

## Nginx Configuration

Use Laravel-specific nginx locations from `nginx_laravel_locations()`:

- `try_files` with query string passthrough
- PHP-FPM fastcgi pass
- Hidden file protection

## Queue Workers

Managed via Supervisor at:
`/etc/supervisor/conf.d/{username}-worker.conf`

## Scheduler

Crontab entry for Laravel scheduler:

```
* * * * * cd /home/{username}/current && php artisan schedule:run >> /dev/null 2>&1
```
