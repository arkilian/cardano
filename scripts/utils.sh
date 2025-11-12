#!/bin/bash

# Quick utilities for Cardano development
# Source this file or run specific functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if CARDANO_NODE_SOCKET_PATH is set
check_env() {
    if [ -z "$CARDANO_NODE_SOCKET_PATH" ]; then
        echo -e "${RED}Error: CARDANO_NODE_SOCKET_PATH not set${NC}"
        echo "Run: source ~/.cardano-env"
        return 1
    fi
    return 0
}

# Get blockchain tip
get_tip() {
    check_env || return 1
    echo -e "${BLUE}Querying blockchain tip...${NC}"
    cardano-cli query tip --testnet-magic ${CARDANO_TESTNET_MAGIC:-1}
}

# Get address balance
get_balance() {
    check_env || return 1
    local addr=$1
    
    if [ -z "$addr" ]; then
        if [ -f ~/cardano/keys/payment.addr ]; then
            addr=$(cat ~/cardano/keys/payment.addr)
        else
            echo -e "${RED}Error: No address provided and no default address found${NC}"
            echo "Usage: get_balance <address>"
            return 1
        fi
    fi
    
    echo -e "${BLUE}Querying balance for: ${addr}${NC}"
    cardano-cli query utxo --address "$addr" --testnet-magic ${CARDANO_TESTNET_MAGIC:-1}
}

# Generate new wallet keys
generate_wallet() {
    check_env || return 1
    local name=${1:-wallet}
    local dir=~/cardano/keys
    
    mkdir -p "$dir"
    
    echo -e "${BLUE}Generating wallet keys: ${name}${NC}"
    
    # Payment keys
    cardano-cli address key-gen \
        --verification-key-file "${dir}/${name}.vkey" \
        --signing-key-file "${dir}/${name}.skey"
    
    # Stake keys
    cardano-cli stake-address key-gen \
        --verification-key-file "${dir}/${name}-stake.vkey" \
        --signing-key-file "${dir}/${name}-stake.skey"
    
    # Build address
    cardano-cli address build \
        --payment-verification-key-file "${dir}/${name}.vkey" \
        --stake-verification-key-file "${dir}/${name}-stake.vkey" \
        --testnet-magic ${CARDANO_TESTNET_MAGIC:-1} \
        --out-file "${dir}/${name}.addr"
    
    echo -e "${GREEN}Wallet created successfully!${NC}"
    echo -e "${YELLOW}Address:${NC} $(cat ${dir}/${name}.addr)"
    echo -e "${YELLOW}Keys saved to:${NC} ${dir}/${name}.*"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT: Backup your keys securely!${NC}"
}

# Get protocol parameters
get_protocol_params() {
    check_env || return 1
    local output=${1:-/tmp/protocol-params.json}
    
    echo -e "${BLUE}Fetching protocol parameters...${NC}"
    cardano-cli query protocol-parameters \
        --testnet-magic ${CARDANO_TESTNET_MAGIC:-1} \
        --out-file "$output"
    
    echo -e "${GREEN}Protocol parameters saved to: ${output}${NC}"
}

# Calculate minimum UTXO for an output
calc_min_utxo() {
    echo -e "${YELLOW}Calculating minimum UTXO...${NC}"
    get_protocol_params /tmp/protocol-params.json
    
    local min_utxo=$(jq -r '.utxoCostPerByte' /tmp/protocol-params.json)
    echo -e "${GREEN}Minimum UTXO per byte: ${min_utxo} lovelace${NC}"
    echo -e "${GREEN}Typical minimum UTXO: ~1,000,000 lovelace (1 ADA)${NC}"
}

# Convert lovelace to ADA
lovelace_to_ada() {
    local lovelace=$1
    if [ -z "$lovelace" ]; then
        echo "Usage: lovelace_to_ada <amount>"
        return 1
    fi
    
    local ada=$(echo "scale=6; $lovelace / 1000000" | bc)
    echo "${ada} ADA"
}

# Convert ADA to lovelace
ada_to_lovelace() {
    local ada=$1
    if [ -z "$ada" ]; then
        echo "Usage: ada_to_lovelace <amount>"
        return 1
    fi
    
    local lovelace=$(echo "$ada * 1000000" | bc | cut -d'.' -f1)
    echo "${lovelace} lovelace"
}

# Get transaction details
get_tx() {
    check_env || return 1
    local tx_hash=$1
    
    if [ -z "$tx_hash" ]; then
        echo "Usage: get_tx <transaction_hash>"
        return 1
    fi
    
    echo -e "${BLUE}Querying transaction: ${tx_hash}${NC}"
    cardano-cli query utxo --tx-in "${tx_hash}#0" --testnet-magic ${CARDANO_TESTNET_MAGIC:-1}
}

# Generate policy ID from script
get_policy_id() {
    local script_file=$1
    
    if [ -z "$script_file" ] || [ ! -f "$script_file" ]; then
        echo "Usage: get_policy_id <script_file>"
        return 1
    fi
    
    echo -e "${BLUE}Calculating policy ID...${NC}"
    local policy_id=$(cardano-cli transaction policyid --script-file "$script_file")
    echo -e "${GREEN}Policy ID: ${policy_id}${NC}"
    echo "$policy_id"
}

# Convert text to hex
text_to_hex() {
    local text=$1
    if [ -z "$text" ]; then
        echo "Usage: text_to_hex <text>"
        return 1
    fi
    
    echo -n "$text" | xxd -ps | tr -d '\n'
}

# Convert hex to text
hex_to_text() {
    local hex=$1
    if [ -z "$hex" ]; then
        echo "Usage: hex_to_text <hex>"
        return 1
    fi
    
    echo -n "$hex" | xxd -r -ps
}

# Check node sync status
check_sync() {
    check_env || return 1
    
    echo -e "${BLUE}Checking node sync status...${NC}"
    
    local tip=$(cardano-cli query tip --testnet-magic ${CARDANO_TESTNET_MAGIC:-1})
    local sync_progress=$(echo "$tip" | jq -r '.syncProgress')
    local current_slot=$(echo "$tip" | jq -r '.slot')
    local block_no=$(echo "$tip" | jq -r '.block')
    local epoch=$(echo "$tip" | jq -r '.epoch')
    
    echo -e "${YELLOW}Sync Progress: ${sync_progress}${NC}"
    echo -e "${YELLOW}Current Slot: ${current_slot}${NC}"
    echo -e "${YELLOW}Block Number: ${block_no}${NC}"
    echo -e "${YELLOW}Epoch: ${epoch}${NC}"
    
    if [ "$sync_progress" == "100.00" ]; then
        echo -e "${GREEN}✓ Node is fully synced!${NC}"
    else
        echo -e "${YELLOW}⚠ Node is still syncing...${NC}"
    fi
}

# Display help
show_help() {
    echo -e "${BLUE}Cardano Development Utilities${NC}"
    echo ""
    echo "Available functions:"
    echo "  get_tip              - Get blockchain tip information"
    echo "  get_balance [addr]   - Get address balance"
    echo "  generate_wallet      - Generate new wallet keys"
    echo "  get_protocol_params  - Fetch protocol parameters"
    echo "  calc_min_utxo        - Calculate minimum UTXO"
    echo "  lovelace_to_ada      - Convert lovelace to ADA"
    echo "  ada_to_lovelace      - Convert ADA to lovelace"
    echo "  get_tx <hash>        - Get transaction details"
    echo "  get_policy_id <file> - Calculate policy ID from script"
    echo "  text_to_hex <text>   - Convert text to hexadecimal"
    echo "  hex_to_text <hex>    - Convert hexadecimal to text"
    echo "  check_sync           - Check node sync status"
    echo ""
    echo "Usage: source this file, then call any function"
    echo "Example: get_balance"
}

# If script is run directly (not sourced), show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_help
fi
