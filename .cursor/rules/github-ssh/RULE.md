---
description: "Enforce SSH URLs for all GitHub operations - never use HTTPS"
alwaysApply: true
---

# GitHub SSH Rule

Always use SSH URLs for GitHub repositories, never HTTPS.

## URL Formats

- **Use SSH**: `git@github.com:owner/repo.git`
- **Never HTTPS**: `https://github.com/owner/repo.git`

## When This Applies

- Cloning repositories
- Adding remotes
- Fetching or pushing
- Any git operations involving GitHub

## Authentication

- Use SSH keys for authentication
- Deploy keys are preferred for server deployments
- Never embed tokens or passwords in URLs
