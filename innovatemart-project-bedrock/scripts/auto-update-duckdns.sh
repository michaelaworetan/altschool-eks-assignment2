#!/bin/bash

# Auto DuckDNS Update Script
# Runs continuously and updates DuckDNS when IP changes

DUCKDNS_DOMAIN="innovatemarts"
DUCKDNS_TOKEN="${DUCKDNS_TOKEN:-}"
CHECK_INTERVAL=300  # Check every 5 minutes

if [ -z "$DUCKDNS_TOKEN" ]; then
    echo "Error: Set DUCKDNS_TOKEN environment variable"
    exit 1
fi

LAST_IP=""

while true; do
    # Get current node IP
    CURRENT_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)
    
    if [ -n "$CURRENT_IP" ] && [ "$CURRENT_IP" != "$LAST_IP" ]; then
        echo "$(date): IP changed from $LAST_IP to $CURRENT_IP"
        
        # Update DuckDNS
        RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=$CURRENT_IP")
        
        if [ "$RESPONSE" = "OK" ]; then
            echo "$(date): DuckDNS updated successfully"
            LAST_IP="$CURRENT_IP"
        else
            echo "$(date): DuckDNS update failed: $RESPONSE"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done