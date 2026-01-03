#!/bin/bash

#############################################
# Webhook Management Functions
#############################################

WEBHOOK_HANDLER="/opt/cipi/webhook.php"
WEBHOOK_LOG="/var/log/cipi/webhook.log"

# Generate webhook secret for an app
generate_webhook_secret() {
    openssl rand -hex 32
}

# Regenerate webhook secret for an app
webhook_regenerate_secret() {
    local username=$1
    
    if [ -z "$username" ]; then
        echo -e "${RED}Error: Username required${NC}"
        echo "Usage: cipi webhook regenerate <username>"
        exit 1
    fi
    
    check_app_exists "$username"
    
    echo -e "${YELLOW}${BOLD}Warning: This will invalidate the current webhook secret!${NC}"
    read -p "Type the username to confirm: " confirm
    
    if [ "$confirm" != "$username" ]; then
        echo "Regeneration cancelled."
        exit 0
    fi
    
    echo ""
    echo -e "${CYAN}Regenerating webhook secret...${NC}"
    
    local new_secret=$(generate_webhook_secret)
    set_webhook "$username" "$new_secret"
    echo ""
    echo -e "${GREEN}${BOLD}Webhook secret regenerated!${NC}"
    echo "─────────────────────────────────────"
    echo -e "New webhook secret: ${CYAN}$new_secret${NC}"
    echo ""
}

# Show webhook information for an app
webhook_show() {
    local username=$1
    local webhook_domain=$(get_config "webhook_domain")
    local secret=$(get_webhook_secret "$username")
    
    if [ -z "$secret" ]; then
        echo -e "${YELLOW}No webhook secret configured for this app.${NC}"
        echo -e "Run: ${CYAN}cipi webhook regenerate $username${NC}"
        return
    fi
    
    echo ""
    echo -e "${BOLD}GitHub Webhook Configuration:${NC}"
    echo "─────────────────────────────────────"
    if [ -n "$webhook_domain" ]; then
        echo -e "Payload URL:   ${CYAN}https://$webhook_domain/webhook/$username${NC}"
    else
        echo -e "${YELLOW}Warning: Webhook domain not configured${NC}"
        echo -e "Payload URL:   ${CYAN}(webhook domain required)${NC}"
    fi
    echo -e "Content type:  ${CYAN}application/json${NC}"
    echo -e "Secret:        ${CYAN}$secret${NC}"
    echo -e "Events:        ${CYAN}Just the push event${NC}"
    echo ""
}

# Webhook logs
webhook_logs() {
    tail -f "$WEBHOOK_LOG"
}

# Automatically setup webhook on GitHub using Device Flow
webhook_setup() {
    local username=$1
    
    if [ -z "$username" ]; then
        echo -e "${RED}Error: Username required${NC}"
        echo "Usage: cipi webhook setup <username>"
        exit 1
    fi
    
    check_app_exists "$username"
    
    # Get GitHub Client ID from config
    local github_client_id=$(get_config "github_client_id")
    
    if [ -z "$github_client_id" ]; then
        echo -e "${RED}Error: GitHub OAuth Client ID not configured${NC}"
        echo "Run the installer again or set it manually:"
        echo "  ${CYAN}cipi config set github_client_id <your_client_id>${NC}"
        exit 1
    fi
    
    # Get repository info
    local repository=$(get_app_field "$username" "repository")
    
    if [ -z "$repository" ]; then
        echo -e "${RED}Error: Repository not found for app '$username'${NC}"
        exit 1
    fi
    
    # Parse owner/repo from git URL
    local owner_repo=""
    if [[ "$repository" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo -e "${RED}Error: Could not parse GitHub repository from: $repository${NC}"
        echo "Repository must be a GitHub URL (e.g., https://github.com/owner/repo or git@github.com:owner/repo.git)"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}Setting up GitHub webhook for ${BOLD}$owner_repo${NC}"
    echo ""
    
    # Step 1: Request device code
    local device_response=$(curl -s -X POST \
        "https://github.com/login/device/code" \
        -H "Accept: application/json" \
        -d "client_id=$github_client_id&scope=admin:repo_hook")
    
    local device_code=$(echo "$device_response" | jq -r '.device_code // empty')
    local user_code=$(echo "$device_response" | jq -r '.user_code // empty')
    local verification_uri=$(echo "$device_response" | jq -r '.verification_uri // empty')
    local interval=$(echo "$device_response" | jq -r '.interval // 5')
    local expires_in=$(echo "$device_response" | jq -r '.expires_in // 900')
    
    if [ -z "$device_code" ] || [ "$device_code" = "null" ]; then
        local error=$(echo "$device_response" | jq -r '.error // "Unknown error"')
        local error_desc=$(echo "$device_response" | jq -r '.error_description // ""')
        echo -e "${RED}Error: Failed to get device code from GitHub${NC}"
        if [ -n "$error_desc" ]; then
            echo -e "${YELLOW}$error: $error_desc${NC}"
        fi
        exit 1
    fi
    
    # Step 2: Prompt user to authorize
    echo "─────────────────────────────────────"
    echo -e "${YELLOW}${BOLD}GitHub Authorization Required${NC}"
    echo ""
    echo -e "  1. Open: ${CYAN}${BOLD}$verification_uri${NC}"
    echo -e "  2. Enter code: ${GREEN}${BOLD}$user_code${NC}"
    echo ""
    echo "Waiting for authorization..."
    echo "─────────────────────────────────────"
    
    # Step 3: Poll for authorization
    local access_token=""
    local elapsed=0
    local poll_count=0
    
    while [ $elapsed -lt $expires_in ]; do
        sleep "$interval"
        elapsed=$((elapsed + interval))
        poll_count=$((poll_count + 1))
        
        # Show progress every 5 polls
        if [ $((poll_count % 5)) -eq 0 ]; then
            printf "."
        fi
        
        local token_response=$(curl -s -X POST \
            "https://github.com/login/oauth/access_token" \
            -H "Accept: application/json" \
            -d "client_id=$github_client_id&device_code=$device_code&grant_type=urn:ietf:params:oauth:grant-type:device_code")
        
        local error=$(echo "$token_response" | jq -r '.error // empty')
        
        if [ "$error" = "authorization_pending" ]; then
            continue
        elif [ "$error" = "slow_down" ]; then
            interval=$((interval + 5))
            continue
        elif [ -n "$error" ] && [ "$error" != "null" ]; then
            echo ""
            local error_desc=$(echo "$token_response" | jq -r '.error_description // ""')
            echo -e "${RED}Error: $error${NC}"
            if [ -n "$error_desc" ]; then
                echo -e "${YELLOW}$error_desc${NC}"
            fi
            exit 1
        fi
        
        access_token=$(echo "$token_response" | jq -r '.access_token // empty')
        if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
            break
        fi
    done
    
    if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
        echo ""
        echo -e "${RED}Error: Authorization timed out${NC}"
        echo "Please try again: ${CYAN}cipi webhook setup $username${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Authorized!${NC}"
    
    # Step 4: Create webhook
    local webhook_domain=$(get_config "webhook_domain")
    local webhook_secret=$(get_webhook_secret "$username")
    
    if [ -z "$webhook_domain" ]; then
        echo -e "${RED}Error: Webhook domain not configured${NC}"
        echo "Please configure the webhook domain first."
        exit 1
    fi
    
    if [ -z "$webhook_secret" ]; then
        echo -e "${YELLOW}No webhook secret found, generating one...${NC}"
        webhook_secret=$(generate_webhook_secret)
        set_webhook "$username" "$webhook_secret"
    fi
    
    local webhook_url="https://$webhook_domain/webhook/$username"
    
    echo -e "${CYAN}Creating webhook on GitHub...${NC}"
    
    local webhook_response=$(curl -s -X POST \
        "https://api.github.com/repos/$owner_repo/hooks" \
        -H "Authorization: Bearer $access_token" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -d "{
            \"name\": \"web\",
            \"active\": true,
            \"events\": [\"push\"],
            \"config\": {
                \"url\": \"$webhook_url\",
                \"content_type\": \"application/json\",
                \"secret\": \"$webhook_secret\",
                \"insecure_ssl\": \"0\"
            }
        }")
    
    # Token is now out of scope and will be garbage collected
    # (In bash, variables are cleared when function ends)
    unset access_token
    
    local webhook_id=$(echo "$webhook_response" | jq -r '.id // empty')
    local error_msg=$(echo "$webhook_response" | jq -r '.message // empty')
    
    if [ -z "$webhook_id" ] || [ "$webhook_id" = "null" ]; then
        if [ -n "$error_msg" ] && [ "$error_msg" != "null" ]; then
            echo -e "${RED}Error: Failed to create webhook: $error_msg${NC}"
        else
            echo -e "${RED}Error: Failed to create webhook${NC}"
            echo "Response: $webhook_response"
        fi
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}✓ Webhook created successfully!${NC}"
    echo "─────────────────────────────────────"
    echo -e "Webhook ID: ${CYAN}$webhook_id${NC}"
    echo -e "URL:        ${CYAN}$webhook_url${NC}"
    echo ""
    echo -e "${GREEN}Pushes to $owner_repo will now auto-deploy!${NC}"
    echo ""
}

