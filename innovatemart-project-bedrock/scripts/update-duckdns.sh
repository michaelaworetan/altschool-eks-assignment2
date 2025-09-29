#!/bin/bash

# DuckDNS Update Script
# Updates DuckDNS domain with current EKS node IP

set -e

DUCKDNS_DOMAIN="innovatemarts"
DUCKDNS_TOKEN="${DUCKDNS_TOKEN:-}"  # Set as environment variable

if [ -z "$DUCKDNS_TOKEN" ]; then
    echo "Error: DUCKDNS_TOKEN environment variable not set"
    echo "Usage: DUCKDNS_TOKEN=your_token ./update-duckdns.sh"
    exit 1
fi

# Get EKS node public IP
echo "Getting EKS node IP..."
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

if [ -z "$NODE_IP" ]; then
    echo "Error: Could not get node IP. Make sure kubectl is configured."
    exit 1
fi

echo "Node IP: $NODE_IP"

# Update DuckDNS
echo "Updating DuckDNS domain: $DUCKDNS_DOMAIN.duckdns.org"
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_DOMAIN&token=$DUCKDNS_TOKEN&ip=$NODE_IP")

if [ "$RESPONSE" = "OK" ]; then
    echo "✅ DuckDNS updated successfully!"
    echo "Domain: http://$DUCKDNS_DOMAIN.duckdns.org:30080"
else
    echo "❌ DuckDNS update failed: $RESPONSE"
    exit 1
fi

# Verify DNS resolution
echo "Verifying DNS resolution..."
sleep 5
RESOLVED_IP=$(nslookup $DUCKDNS_DOMAIN.duckdns.org | grep -A1 "Name:" | tail -1 | awk '{print $2}')
echo "Resolved IP: $RESOLVED_IP"

if [ "$RESOLVED_IP" = "$NODE_IP" ]; then
    echo "✅ DNS resolution verified!"
else
    echo "⚠️  DNS may take a few minutes to propagate"
fi