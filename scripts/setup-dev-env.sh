#!/bin/bash

# Cardano Development Environment Setup Script
# This script helps you quickly set up a Cardano development environment

set -e

echo "=================================="
echo "Cardano Dev Environment Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

# Check if running on supported OS
print_info "Checking operating system..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    print_status "Detected Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_status "Detected macOS"
else
    print_error "Unsupported OS. Please use Linux or macOS (or WSL on Windows)"
    exit 1
fi

# Create directory structure
print_info "Creating directory structure..."
mkdir -p ~/cardano/{config,db,logs,keys,scripts,tokens,nft}
print_status "Directories created"

# Check for required tools
print_info "Checking for required tools..."

# Check for git
if command -v git &> /dev/null; then
    print_status "git is installed"
else
    print_error "git is not installed. Please install git first."
    exit 1
fi

# Check for curl
if command -v curl &> /dev/null; then
    print_status "curl is installed"
else
    print_error "curl is not installed. Please install curl first."
    exit 1
fi

# Check for jq
if command -v jq &> /dev/null; then
    print_status "jq is installed"
else
    print_info "jq not found. Installing..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt-get install -y jq
    else
        brew install jq
    fi
    print_status "jq installed"
fi

# Check for cardano-cli
if command -v cardano-cli &> /dev/null; then
    print_status "cardano-cli is installed ($(cardano-cli --version | head -n1))"
else
    print_error "cardano-cli is not installed."
    print_info "Please install cardano-node and cardano-cli first."
    print_info "See: https://developers.cardano.org/docs/operate-a-stake-pool/node-operations/installing-cardano-node/"
    exit 1
fi

# Check for cardano-node
if command -v cardano-node &> /dev/null; then
    print_status "cardano-node is installed ($(cardano-node --version | head -n1))"
else
    print_error "cardano-node is not installed."
    exit 1
fi

# Set up environment variables
print_info "Setting up environment variables..."

ENV_FILE=~/.cardano-env
cat > $ENV_FILE << 'EOF'
# Cardano Development Environment Variables

# Node socket path
export CARDANO_NODE_SOCKET_PATH="$HOME/cardano/node.socket"

# Network configuration (change as needed)
export CARDANO_NETWORK="preprod"
export CARDANO_NODE_NETWORK_ID="1"  # 1 for preprod, 2 for preview
export CARDANO_TESTNET_MAGIC="1"

# Aliases for convenience
alias cardano-node-start='cardano-node run --topology ~/cardano/config/topology.json --database-path ~/cardano/db --socket-path ~/cardano/node.socket --config ~/cardano/config/config.json'
alias cardano-query-tip='cardano-cli query tip --testnet-magic $CARDANO_TESTNET_MAGIC'
alias cardano-query-utxo='cardano-cli query utxo --testnet-magic $CARDANO_TESTNET_MAGIC'
alias cardano-balance='cardano-cli query utxo --address $(cat ~/cardano/keys/payment.addr) --testnet-magic $CARDANO_TESTNET_MAGIC'
EOF

# Add to shell profile
SHELL_PROFILE=""
if [ -f ~/.bashrc ]; then
    SHELL_PROFILE=~/.bashrc
elif [ -f ~/.zshrc ]; then
    SHELL_PROFILE=~/.zshrc
fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q "source $ENV_FILE" "$SHELL_PROFILE"; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Cardano Development Environment" >> "$SHELL_PROFILE"
        echo "source $ENV_FILE" >> "$SHELL_PROFILE"
        print_status "Environment variables added to $SHELL_PROFILE"
    else
        print_info "Environment variables already configured"
    fi
fi

# Download network configuration files
print_info "Downloading network configuration files..."
cd ~/cardano/config

NETWORK="preprod"  # Change to "preview" if you prefer

case $NETWORK in
    preprod)
        BASE_URL="https://book.world.dev.cardano.org/environments/preprod"
        ;;
    preview)
        BASE_URL="https://book.world.dev.cardano.org/environments/preview"
        ;;
esac

for file in config.json topology.json byron-genesis.json shelley-genesis.json alonzo-genesis.json conway-genesis.json; do
    if [ ! -f "$file" ]; then
        print_info "Downloading $file..."
        curl -s -o "$file" "${BASE_URL}/${file}"
        print_status "$file downloaded"
    else
        print_info "$file already exists, skipping"
    fi
done

echo ""
echo "=================================="
print_status "Setup Complete!"
echo "=================================="
echo ""
print_info "Next steps:"
echo "1. Source your environment: source $ENV_FILE"
echo "2. Generate wallet keys: cd ~/cardano/keys && cardano-cli address key-gen --verification-key-file payment.vkey --signing-key-file payment.skey"
echo "3. Build an address: cardano-cli address build --payment-verification-key-file ~/cardano/keys/payment.vkey --testnet-magic 1 --out-file ~/cardano/keys/payment.addr"
echo "4. Get test ADA: Visit https://faucet.preprod.world.dev.cardano.org/"
echo "5. Start the node: cardano-node-start"
echo ""
print_info "For more information, see the documentation in the docs/ directory"
echo ""
