# Getting Started with Cardano Development

This guide will help you set up your Cardano development environment and get ready to build on the blockchain.

## 📋 Prerequisites

### System Requirements

#### For Testnet Development (Minimum)
- **CPU**: 2+ cores
- **RAM**: 4GB
- **Storage**: 20GB free space
- **OS**: Linux (preferred), macOS, or Windows with WSL

#### For Mainnet Node (Recommended)
- **CPU**: 4+ cores
- **RAM**: 24GB
- **Storage**: 350GB+ free space
- **Network**: Stable broadband connection

### Knowledge Prerequisites

Before diving into Cardano development, you should have:
- Basic understanding of blockchain concepts
- Familiarity with command-line interface (CLI)
- Programming experience (Haskell, Rust, or JavaScript helpful)
- Understanding of cryptography basics (keys, addresses, signatures)

## 🔧 Development Environment Setup

### Step 1: Install System Dependencies

#### On Ubuntu/Debian Linux:
```bash
sudo apt-get update -y
sudo apt-get install -y \
    automake build-essential pkg-config libffi-dev libgmp-dev \
    libssl-dev libncurses-dev libsystemd-dev zlib1g-dev \
    make g++ tmux git jq wget libtool autoconf liblmdb-dev
```

#### On macOS:
```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install jq libtool autoconf automake pkg-config openssl
```

#### On Windows:
Use Windows Subsystem for Linux (WSL2) and follow Ubuntu instructions:
```powershell
# In PowerShell as Administrator
wsl --install
```

### Step 2: Install Haskell Tools (GHCup)

GHCup is the recommended way to install Haskell tools:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

During installation, when prompted:
- Press ENTER to proceed with default installation
- Prepend GHCup to PATH
- Install HLS (Haskell Language Server) - recommended for IDE support

After installation, configure your shell:
```bash
source ~/.ghcup/env
```

Install required versions:
```bash
ghcup install ghc 9.6.7
ghcup set ghc 9.6.7
ghcup install cabal 3.10.2.0
ghcup set cabal 3.10.2.0
```

Verify installation:
```bash
ghc --version    # Should show 9.6.7
cabal --version  # Should show 3.10.2.0
```

### Step 3: Install Cardano Node and CLI

You have three options for installing cardano-node and cardano-cli:

#### Option A: Pre-built Binaries (Fastest)

Download from the official releases:
```bash
# Visit https://github.com/IntersectMBO/cardano-node/releases
# Download the latest release for your platform
# Extract and add to PATH
```

#### Option B: Build with Nix (Recommended for Consistency)

First, install Nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Configure IOG binary cache for faster builds:
```bash
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf << EOF
substituters = https://cache.nixos.org https://cache.iog.io
trusted-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
EOF
```

Clone and build:
```bash
git clone https://github.com/IntersectMBO/cardano-node
cd cardano-node
git tag | sort -V  # List available versions
git checkout tags/8.12.2  # Use latest stable version
nix build .#cardano-node .#cardano-cli
```

#### Option C: Build with Cabal (Traditional)

Clone the repository:
```bash
git clone https://github.com/IntersectMBO/cardano-node
cd cardano-node
git checkout tags/8.12.2  # Use latest stable version
```

Update Cabal and build:
```bash
cabal update
cabal build cardano-node cardano-cli
```

The binaries will be in:
```bash
$(find dist-newstyle -name cardano-node -type f)
$(find dist-newstyle -name cardano-cli -type f)
```

Copy them to a location in your PATH:
```bash
cp -p "$(find dist-newstyle -name cardano-node -type f)" ~/.local/bin/
cp -p "$(find dist-newstyle -name cardano-cli -type f)" ~/.local/bin/
```

Verify installation:
```bash
cardano-cli --version
cardano-node --version
```

### Step 4: Set Up Your Wallet

#### Install a Wallet

For beginners, use one of these wallets:

1. **Daedalus** - Full node wallet (downloads entire blockchain)
   - Download from: https://daedaluswallet.io/
   - Most secure, requires ~350GB storage

2. **Yoroi** - Light wallet (browser extension)
   - Chrome/Firefox extension
   - Easy to use, no blockchain download

3. **Lace** - Modern light wallet
   - Download from: https://www.lace.io/
   - User-friendly interface

#### Get Test ADA

For development, you'll need test ADA (tADA) from a testnet faucet:

1. **Preprod Testnet Faucet**: https://docs.cardano.org/cardano-testnets/tools/faucet/
2. **Preview Testnet Faucet**: https://faucet.preview.world.dev.cardano.org/

Steps:
1. Create a wallet on testnet
2. Copy your wallet address
3. Visit the faucet website
4. Request test ADA (usually 1000 tADA)
5. Wait for confirmation (1-2 minutes)

### Step 5: Configure Your Development Environment

Create environment variables:

```bash
# Add to ~/.bashrc or ~/.zshrc
export CARDANO_NODE_SOCKET_PATH="$HOME/cardano/node.socket"

# For testnet (preprod)
export CARDANO_NODE_NETWORK_ID="1"
export CARDANO_TESTNET_MAGIC="1"

# For mainnet (when ready)
# export CARDANO_NODE_NETWORK_ID="mainnet"
```

Create a working directory:
```bash
mkdir -p ~/cardano/{config,db,logs,keys}
cd ~/cardano
```

Download network configuration files for testnet:
```bash
# For Preprod testnet
wget -O config/config.json https://book.world.dev.cardano.org/environments/preprod/config.json
wget -O config/topology.json https://book.world.dev.cardano.org/environments/preprod/topology.json
wget -O config/byron-genesis.json https://book.world.dev.cardano.org/environments/preprod/byron-genesis.json
wget -O config/shelley-genesis.json https://book.world.dev.cardano.org/environments/preprod/shelley-genesis.json
wget -O config/alonzo-genesis.json https://book.world.dev.cardano.org/environments/preprod/alonzo-genesis.json
wget -O config/conway-genesis.json https://book.world.dev.cardano.org/environments/preprod/conway-genesis.json
```

### Step 6: Run Your First Node

Start a testnet node:
```bash
cardano-node run \
  --topology config/topology.json \
  --database-path db \
  --socket-path node.socket \
  --host-addr 0.0.0.0 \
  --port 3001 \
  --config config/config.json
```

The node will start syncing. This can take several hours for testnet.

To run in the background:
```bash
nohup cardano-node run \
  --topology config/topology.json \
  --database-path db \
  --socket-path node.socket \
  --host-addr 0.0.0.0 \
  --port 3001 \
  --config config/config.json > logs/node.log 2>&1 &
```

Check sync status:
```bash
cardano-cli query tip --testnet-magic 1
```

## ✅ Verify Your Setup

Test that everything is working:

```bash
# Check CLI version
cardano-cli --version

# Query the blockchain tip
cardano-cli query tip --testnet-magic 1

# Check protocol parameters
cardano-cli query protocol-parameters --testnet-magic 1 --out-file /tmp/protocol.json
```

## 🎯 First CLI Operations

### Generate Payment Keys

```bash
cd ~/cardano/keys

# Generate payment key pair
cardano-cli address key-gen \
  --verification-key-file payment.vkey \
  --signing-key-file payment.skey

# Generate stake key pair (for staking)
cardano-cli stake-address key-gen \
  --verification-key-file stake.vkey \
  --signing-key-file stake.skey

# Build payment address
cardano-cli address build \
  --payment-verification-key-file payment.vkey \
  --stake-verification-key-file stake.vkey \
  --out-file payment.addr \
  --testnet-magic 1

# View your address
cat payment.addr
```

### Query Address Balance

```bash
cardano-cli query utxo \
  --address $(cat payment.addr) \
  --testnet-magic 1
```

## 🚀 Alternative: Quick Start with Demeter.run

If you want to skip local setup, use Demeter.run - a cloud-based Cardano development environment:

1. Visit: https://demeter.run/
2. Sign up for free account
3. Create a new workspace
4. Get instant access to cardano-node, cardano-cli, and development tools

Perfect for:
- Quick experimentation
- Learning without local setup
- Workshop environments

## 📚 Next Steps

Now that your environment is set up:

1. ✅ Read the [Smart Contracts Guide](./02-smart-contracts.md)
2. ✅ Explore the [Tools and Resources](./03-tools-and-resources.md)
3. ✅ Try the [Hello World example](../examples/hello-world/)
4. ✅ Join the Cardano community on Discord
5. ✅ Start building!

## 🆘 Troubleshooting

### Node Won't Sync
- Check internet connection
- Ensure firewall allows port 3001
- Verify config files are correct
- Check disk space

### CLI Commands Fail
- Verify CARDANO_NODE_SOCKET_PATH is set
- Ensure node is running and synced
- Check you're using correct network magic

### Out of Memory
- Increase swap space
- Close other applications
- Consider using a cloud instance

### Build Errors
- Update GHC and Cabal to required versions
- Install all system dependencies
- Check for sufficient disk space
- Try using Nix instead

## 📖 Additional Resources

- [Official Installation Guide](https://developers.cardano.org/docs/operate-a-stake-pool/node-operations/installing-cardano-node/)
- [Cardano Node Documentation](https://docs.cardano.org/cardano-components/cardano-node/)
- [CLI Reference](https://developers.cardano.org/docs/get-started/cardano-cli/)
- [Cardano Stack Exchange](https://cardano.stackexchange.com/)

---

**You're now ready to start developing on Cardano!** 🎉
