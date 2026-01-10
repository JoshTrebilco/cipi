---
description: "Bash scripting conventions used throughout the Faber codebase"
globs:
  - "*.sh"
  - "faber"
  - "install.sh"
alwaysApply: false
---

# Bash Scripting Conventions

## File Structure

Every bash script follows this structure:

```bash
#!/bin/bash

#############################################
# Section Name
#############################################

# Function description
function_name() {
    local var1=""
    local var2=""

    # Implementation
}
```

## Variables

- Always use `local` for function variables
- Use uppercase for constants and globals
- Use lowercase with underscores for local variables

## Color Output

Use these predefined color variables:

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
```

Output with colors: `echo -e "${RED}Error message${NC}"`

## Argument Parsing

Use this pattern for parsing `--key=value` arguments:

```bash
for arg in "$@"; do
    case $arg in
        --user=*)
            username="${arg#*=}"
            ;;
        --force)
            force=true
            ;;
    esac
done
```

## Error Handling

- Errors: `echo -e "${RED}Error: message${NC}"` then `exit 1`
- Warnings: `echo -e "${YELLOW}Warning: message${NC}"`
- Success: `echo -e "${GREEN}✓ message${NC}"`
- Info: `echo -e "${CYAN}message${NC}"`

## Progress Indicators

Use arrows for steps: `echo "  → Doing something..."`
