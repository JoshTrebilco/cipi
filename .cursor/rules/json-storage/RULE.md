---
description: "JSON storage patterns for data persistence in Faber"
globs:
  - "lib/storage.sh"
  - "lib/*.sh"
alwaysApply: false
---

# JSON Storage Pattern

## Storage Location

All data is stored in JSON files at `/etc/faber/`:

- `apps.json` - App configurations
- `domains.json` - Domain configurations
- `databases.json` - Database credentials
- `config.json` - Global configuration
- `webhooks.json` - Webhook secrets
- `version.json` - Version info

## Helper Functions

Use these functions from `storage.sh` for JSON operations:

```bash
# Read/write
json_read "$file"
json_write "$file" "$content"

# CRUD operations
json_get "$file" "$key"
json_set "$file" "$key" "$value"
json_delete "$file" "$key"

# Utilities
json_keys "$file"
json_has_key "$file" "$key"
```

## Entity-Specific Helpers

```bash
# Apps
get_app "$username"
get_app_field "$username" "$field"
set_app_field "$username" "$field" "$value"
check_app_exists "$username"

# Domains
get_domain "$domain"
get_domain_field "$domain" "$field"
get_domain_by_app "$username"
get_app_by_domain "$domain"

# Databases
get_db "$dbname"
get_db_field "$dbname" "$field"

# Config
get_config "$key" "$default"
set_config "$key" "$value"
```

## File Permissions

All JSON files should have `chmod 600` (owner read/write only).
