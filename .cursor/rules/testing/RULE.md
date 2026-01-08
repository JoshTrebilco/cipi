---
description: "Testing rules for the Cipi project Docker-based test framework"
globs: 
  - "tests/**"
alwaysApply: false
---

# Cipi Testing Rules

## Test Environment

- Tests run inside Docker containers with systemd
- The local code is mounted at `/cipi/` in the container
- Installed cipi runs from `/opt/cipi/lib/`

## Local Installation

- Use `install_cipi_local()` helper to install from local `/cipi/` directory
- Never run full `install.sh` in tests as it clones from GitHub and overwrites local code
- The test framework verifies checksums to ensure fresh code is used

## Test Structure

- Unit tests: `tests/unit/` - no Docker required
- Integration tests: `tests/integration/` - require Docker with systemd
- Helper functions: `tests/helpers/test_helper.bash`
