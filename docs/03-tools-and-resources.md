# Tools and Resources for Cardano Development

A comprehensive reference guide for all the tools, libraries, and resources you'll need for Cardano development.

## 🛠️ Core Development Tools

### Cardano Node
The core node implementation that powers the Cardano network.

**Installation**: See [Getting Started Guide](./01-getting-started.md)

**Key Commands**:
```bash
# Run node
cardano-node run --config config.json --topology topology.json

# Check version
cardano-node --version

# Get node status
cardano-cli query tip --testnet-magic 1
```

**Use Cases**:
- Running a full node
- Validating transactions
- Stake pool operations
- Local development environment

**Resources**:
- [GitHub Repository](https://github.com/IntersectMBO/cardano-node)
- [Official Documentation](https://docs.cardano.org/cardano-components/cardano-node/)

### Cardano CLI
Command-line interface for interacting with the Cardano blockchain.

**Key Operations**:
```bash
# Address operations
cardano-cli address key-gen
cardano-cli address build

# Transaction operations
cardano-cli transaction build
cardano-cli transaction sign
cardano-cli transaction submit

# Query operations
cardano-cli query utxo
cardano-cli query protocol-parameters

# Stake operations
cardano-cli stake-address key-gen
cardano-cli stake-address registration-certificate
```

**Common Workflows**:
1. Generate keys and addresses
2. Build transactions
3. Submit transactions
4. Query blockchain state
5. Manage stake pools

**Resources**:
- [CLI Reference](https://developers.cardano.org/docs/get-started/cardano-cli/)
- [Command Examples](https://github.com/cardano-foundation/developer-portal/tree/main/docs)

### Cardano Wallet
Backend service providing a REST API for wallet operations.

**Installation**:
```bash
# Via Nix
nix build github:IntersectMBO/cardano-wallet

# Via Docker
docker pull inputoutput/cardano-wallet
```

**API Examples**:
```bash
# Create wallet
curl -X POST http://localhost:8090/v2/wallets \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Wallet",
    "mnemonic_sentence": ["word1", "word2", ...],
    "passphrase": "secure_passphrase"
  }'

# Get wallet balance
curl http://localhost:8090/v2/wallets/{walletId}

# Create transaction
curl -X POST http://localhost:8090/v2/wallets/{walletId}/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "payments": [{
      "address": "addr_test...",
      "amount": { "quantity": 1000000, "unit": "lovelace" }
    }],
    "passphrase": "secure_passphrase"
  }'
```

**Resources**:
- [Wallet Documentation](https://cardano-foundation.github.io/cardano-wallet/)
- [API Reference](https://cardano-foundation.github.io/cardano-wallet/api/edge/)

## 🔷 Smart Contract Development

### Plutus Platform

**Components**:
- **Plutus Core**: Low-level language (compilation target)
- **Plutus Tx**: Haskell library for writing contracts
- **Plutus Application Framework**: Off-chain code framework

**Development Tools**:
```bash
# Plutus Playground (Online IDE)
# https://playground.plutus.iohkdev.io/

# Local setup
cabal install plutus-core plutus-ledger-api plutus-tx plutus-script-utils
```

**Useful Libraries**:
- `plutus-core`: Core language implementation
- `plutus-ledger-api`: On-chain types and functions
- `plutus-tx`: Template Haskell for compilation
- `plutus-script-utils`: Common validator patterns

**Resources**:
- [Plutus Documentation](https://plutus.readthedocs.io/)
- [Plutus Pioneer Program](https://github.com/input-output-hk/plutus-pioneer-program)
- [Plutus Community Docs](https://plutus-community.readthedocs.io/)

### Aiken

**Installation**:
```bash
curl -sSfL https://install.aiken-lang.org | bash
```

**Project Setup**:
```bash
aiken new my_project
cd my_project
aiken check  # Type check
aiken build  # Compile
aiken test   # Run tests
```

**VS Code Extension**: Search for "Aiken" in VS Code marketplace

**Resources**:
- [Official Website](https://aiken-lang.org/)
- [Language Tour](https://aiken-lang.org/language-tour/primitive-types)
- [GitHub](https://github.com/aiken-lang/aiken)
- [Standard Library Docs](https://aiken-lang.org/stdlib/)

### Marlowe

**Access Points**:
- **Marlowe Playground**: https://marlowe.iohk.io/
- **Marlowe CLI**: Command-line tooling
- **Marlowe Runtime**: Production deployment

**CLI Installation**:
```bash
# Part of cardano-node release or separate build
nix build github:input-output-hk/marlowe-cardano#marlowe-cli
```

**TypeScript SDK**:
```bash
npm install @marlowe.io/runtime-lifecycle
npm install @marlowe.io/language-core-v1
```

**Resources**:
- [Marlowe Documentation](https://docs.marlowe.iohk.io/)
- [Marlowe Tutorial](https://developers.cardano.org/docs/smart-contracts/marlowe/)
- [Example Contracts](https://github.com/input-output-hk/marlowe-cardano)

## 🌐 Off-Chain Development

### Mesh SDK (JavaScript/TypeScript)
Modern SDK for building Cardano dApps.

**Installation**:
```bash
npm install @meshsdk/core @meshsdk/react
```

**Features**:
- Transaction building
- Wallet integration
- Smart contract interaction
- Asset minting

**Example**:
```typescript
import { MeshWallet, BlockfrostProvider } from '@meshsdk/core';

const wallet = new MeshWallet({
  networkId: 0,
  fetcher: new BlockfrostProvider('project_id'),
  submitter: new BlockfrostProvider('project_id'),
  key: {
    type: 'mnemonic',
    words: ['word1', 'word2', ...]
  }
});

const address = wallet.getChangeAddress();
const assets = await wallet.getAssets();
```

**Resources**:
- [Mesh Website](https://meshjs.dev/)
- [Documentation](https://meshjs.dev/apis)
- [Examples](https://meshjs.dev/examples)

### Lucid (TypeScript)
Lightweight Cardano library for transaction building.

**Installation**:
```bash
npm install lucid-cardano
```

**Example**:
```typescript
import { Lucid, Blockfrost } from "lucid-cardano";

const lucid = await Lucid.new(
  new Blockfrost("https://cardano-preview.blockfrost.io/api/v0", "projectId"),
  "Preview"
);

lucid.selectWalletFromSeed("seed phrase here");

const tx = await lucid
  .newTx()
  .payToAddress("addr_test...", { lovelace: 5000000n })
  .complete();

const signedTx = await tx.sign().complete();
const txHash = await signedTx.submit();
```

**Resources**:
- [GitHub](https://github.com/spacebudz/lucid)
- [Documentation](https://lucid.spacebudz.io/)

### PyCardano (Python)
Python library for Cardano blockchain interaction.

**Installation**:
```bash
pip install pycardano
```

**Example**:
```python
from pycardano import *

# Create blockchain context
context = BlockFrostChainContext("project_id", network=Network.TESTNET)

# Create payment from signing key
payment_signing_key = PaymentSigningKey.load("payment.skey")
payment_verification_key = PaymentVerificationKey.from_signing_key(payment_signing_key)

# Build address
address = Address(payment_verification_key.hash(), network=Network.TESTNET)

# Build transaction
builder = TransactionBuilder(context)
builder.add_input_address(address)
builder.add_output(TransactionOutput(recipient_address, 5000000))

# Sign and submit
signed_tx = builder.build_and_sign([payment_signing_key], address)
context.submit_tx(signed_tx)
```

**Resources**:
- [GitHub](https://github.com/Python-Cardano/pycardano)
- [Documentation](https://pycardano.readthedocs.io/)

### CardanoSharp (.NET/C#)
.NET SDK for Cardano development.

**Installation**:
```bash
dotnet add package CardanoSharp.Wallet
dotnet add package CardanoSharp.Blockfrost.Sdk
```

**Resources**:
- [GitHub](https://github.com/CardanoSharp/cardanosharp-wallet)
- [Documentation](https://www.cardanosharp.com/)

## 🔗 Blockchain API Services

### Blockfrost
Most popular API service for Cardano.

**Features**:
- REST API
- WebSocket support
- IPFS gateway
- Free tier available

**Setup**:
```bash
# Get API key from https://blockfrost.io/
export BLOCKFROST_PROJECT_ID="your_project_id"
```

**Example**:
```bash
curl https://cardano-preview.blockfrost.io/api/v0/blocks/latest \
  -H "project_id: your_project_id"
```

**Pricing**:
- Free: 50,000 requests/day
- Paid plans: Higher limits

**Resources**:
- [Website](https://blockfrost.io/)
- [Documentation](https://docs.blockfrost.io/)

### Koios
Decentralized, community-driven API.

**Features**:
- Free to use
- Multiple endpoints
- No API key required for basic use
- GraphQL support

**Example**:
```bash
curl -X GET https://api.koios.rest/api/v1/tip
```

**Resources**:
- [Website](https://www.koios.rest/)
- [API Documentation](https://api.koios.rest/)

### Ogmios
Lightweight bridge between cardano-node and applications.

**Features**:
- WebSocket JSON-RPC
- Low latency
- Direct node access
- Self-hosted

**Installation**:
```bash
docker run -p 1337:1337 cardanosolutions/ogmios
```

**Example**:
```javascript
const WebSocket = require('ws');
const client = new WebSocket('ws://localhost:1337');

client.on('open', () => {
  client.send(JSON.stringify({
    type: "jsonwsl/request",
    version: "1.0",
    servicename: "ogmios",
    methodname: "Query",
    args: { query: "currentEpoch" }
  }));
});
```

**Resources**:
- [Website](https://ogmios.dev/)
- [Documentation](https://ogmios.dev/api/)

## 🎨 Frontend Development

### Wallet Connectors

**CIP-30 (Cardano Wallet Connector)**:
Standard browser wallet API.

```typescript
// Check if wallet is available
if (window.cardano && window.cardano.nami) {
  // Connect to wallet
  const api = await window.cardano.nami.enable();
  
  // Get network ID
  const networkId = await api.getNetworkId();
  
  // Get balance
  const balance = await api.getBalance();
  
  // Get change address
  const changeAddress = await api.getChangeAddress();
  
  // Sign transaction
  const signedTx = await api.signTx(tx, true);
}
```

**Supported Wallets**:
- Nami
- Eternl
- Flint
- Lace
- Yoroi
- Gero

### UI Component Libraries

**cardano-wallet-connect**:
```bash
npm install @cardano-wallet-connect/react
```

**use-cardano**:
```bash
npm install use-cardano
```

## 📊 Explorers and Monitoring

### Block Explorers
- **Cardanoscan**: https://cardanoscan.io/
- **Cardano Explorer**: https://explorer.cardano.org/
- **AdaStat**: https://adastat.net/
- **Pool.pm**: https://pool.pm/

### Analytics
- **Cardano Blockchain Insights**: https://datastudio.google.com/u/0/reporting/3136c55b-635e-4f46-8e4b-b8ab54f2d460
- **ADAex**: https://adaex.org/
- **Token Tool**: https://www.tokentool.app/

## 🧪 Testing Tools

### Testnets

**Preview Testnet** (Latest features):
```bash
export CARDANO_NODE_NETWORK_ID=2
# Config: https://book.world.dev.cardano.org/environments/preview/
```

**Preprod Testnet** (Stable):
```bash
export CARDANO_NODE_NETWORK_ID=1
# Config: https://book.world.dev.cardano.org/environments/preprod/
```

### Faucets
- Preview: https://faucet.preview.world.dev.cardano.org/
- Preprod: https://faucet.preprod.world.dev.cardano.org/

### Local Development

**Cardano Node in Docker**:
```bash
docker run -v node-data:/data \
  -p 3001:3001 \
  inputoutput/cardano-node
```

## 🔐 Security Tools

### Audit Tools
- **Plutus Static Analyzer**: Detect common vulnerabilities
- **Formal Verification**: Mathematical proofs of correctness
- **Manual Code Review**: Professional audit services

### Key Management
- **Hardware Wallets**: Ledger, Trezor
- **Key Derivation**: BIP39, BIP32, CIP-1852
- **Secure Storage**: Never commit keys to version control

## 📚 Learning Resources

### Official Documentation
- [Cardano Developer Portal](https://developers.cardano.org/)
- [Cardano Docs](https://docs.cardano.org/)
- [IOHK Blog](https://iohk.io/en/blog/)

### Community
- [Cardano Forum](https://forum.cardano.org/)
- [Cardano Discord](https://discord.gg/cardano)
- [Stack Exchange](https://cardano.stackexchange.com/)
- [Reddit r/CardanoDevelopers](https://reddit.com/r/CardanoDevelopers)

### Video Tutorials
- [IOHK YouTube](https://www.youtube.com/c/IohkIo)
- [Gimbalabs](https://www.youtube.com/c/gimbalabs)

### Courses
- [IOG Academy](https://www.iohk.io/en/academy/)
- [Emurgo Academy](https://education.emurgo.io/)
- [Plutus Pioneer Program](https://github.com/input-output-hk/plutus-pioneer-program)

## 🎯 Quick Reference

### Network Magic Numbers
- Mainnet: `--mainnet`
- Preview: `--testnet-magic 2`
- Preprod: `--testnet-magic 1`

### Common Ports
- Cardano Node: 3001
- Cardano Wallet: 8090
- Ogmios: 1337
- Kupo: 1442

### Useful Calculations
- 1 ADA = 1,000,000 Lovelace
- Minimum UTXO: ~1 ADA (varies with tokens)
- Transaction fee: ~0.17 ADA typical

### Environment Variables
```bash
export CARDANO_NODE_SOCKET_PATH=~/cardano/node.socket
export CARDANO_NODE_NETWORK_ID=1  # For preprod
```

## 🚀 Development Workflow

1. **Design**: Plan your smart contract logic
2. **Develop**: Write validators in Plutus/Aiken/Marlowe
3. **Test**: Unit tests and simulations
4. **Deploy**: Deploy to testnet
5. **Verify**: Test with real transactions
6. **Audit**: Security review
7. **Launch**: Deploy to mainnet

## 📖 Next Steps

- Explore the [Examples Directory](../examples/)
- Join the [Cardano Community](https://discord.gg/cardano)
- Start building your first dApp
- Contribute to open source projects

---

**Happy Building! 🎉**

Have questions? Check out [Cardano Stack Exchange](https://cardano.stackexchange.com/) or ask in the community Discord.
