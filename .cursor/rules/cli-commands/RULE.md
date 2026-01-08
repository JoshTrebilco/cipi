---
description: "CLI command structure and patterns"
globs:
  - "cipi"
  - "lib/commands.sh"
  - "lib/help.sh"
alwaysApply: false
---

# CLI Command Structure

## Command Hierarchy

Commands follow this pattern: `cipi {resource} {action} [options]`

Examples:

- `cipi app create --user=myapp --repository=git@github.com:user/repo.git`
- `cipi domain create --domain=example.com --app=myapp`
- `cipi database create --name=mydb`

## Main Resources

- `provision` - Full app setup (app + domain + database + deploy)
- `app` - App management (create, list, show, edit, delete, env, rollback)
- `domain` - Domain management (create, list, delete, ssl)
- `database` - Database management (create, list, delete)
- `php` - PHP version management
- `service` - Service management (restart, status)
- `webhook` - Webhook management
- `reverb` - WebSocket server management

## Command Function Naming

- Router: `cmd_{resource}()`
- Actions: `{resource}_{action}()`

Example:

```bash
cmd_app() {
    case $subcmd in
        create) app_create "$@" ;;
        list) app_list "$@" ;;
        # ...
    esac
}
```

## Interactive vs Non-Interactive

Commands support both modes:

- Interactive: Prompts user for missing values
- Non-interactive: All values provided via `--key=value` flags

Check with:

```bash
if [ -n "$username" ] && [ -n "$repository" ]; then
    interactive=false
fi
```

## Help Integration

Every command should support `--help`:

```bash
if check_help_requested "$@"; then
    show_help_command "app"
    exit 0
fi
```
