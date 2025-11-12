# NFT Minting on Cardano

Learn how to create and mint NFTs (Non-Fungible Tokens) on Cardano following the CIP-25 standard.

## 🎯 What You'll Learn

- Understanding Cardano NFTs
- CIP-25 metadata standard
- Minting unique NFTs
- IPFS integration
- Royalty standards (CIP-27)

## 🎨 What Makes Cardano NFTs Special?

Cardano NFTs are native tokens with:
- Unique identification (policy ID + asset name)
- Rich metadata (CIP-25)
- No smart contracts needed for basic minting
- Lower fees than Ethereum
- Built-in royalty support (CIP-27)
- Environmentally friendly (PoS)

## 📋 CIP-25 Metadata Standard

NFT metadata follows the CIP-25 standard:

```json
{
  "721": {
    "<policy_id>": {
      "<asset_name>": {
        "name": "My NFT #001",
        "image": "ipfs://QmHash...",
        "mediaType": "image/png",
        "description": "This is my first NFT on Cardano",
        "files": [
          {
            "name": "High Resolution",
            "mediaType": "image/png",
            "src": "ipfs://QmHash..."
          }
        ],
        "attributes": {
          "Rarity": "Legendary",
          "Power": "9000",
          "Element": "Fire"
        }
      }
    }
  }
}
```

## 🚀 Minting Your First NFT

### Step 1: Prepare Your Artwork

```bash
cd ~/cardano/nft
mkdir artwork metadata
```

Create or add your artwork file (PNG, JPG, GIF, etc.) to the `artwork/` directory.

### Step 2: Upload to IPFS

**Option A: Using Pinata**

1. Sign up at https://pinata.cloud
2. Upload your artwork
3. Get the IPFS hash (e.g., `QmXxx...`)
4. Your IPFS URL: `ipfs://QmXxx...`

**Option B: Using NFT.Storage**

```bash
# Install NFT.Storage CLI
npm install -g nft.storage

# Upload file
nft.storage upload artwork/my-nft.png
```

**Option C: Local IPFS Node**

```bash
# Install IPFS
wget https://dist.ipfs.io/go-ipfs/v0.12.0/go-ipfs_v0.12.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.12.0_linux-amd64.tar.gz
cd go-ipfs
sudo ./install.sh

# Initialize and start
ipfs init
ipfs daemon &

# Add your file
ipfs add artwork/my-nft.png
# Returns: QmHash...
```

### Step 3: Create Minting Policy

```bash
# Generate policy keys
cardano-cli address key-gen \
  --verification-key-file nft-policy.vkey \
  --signing-key-file nft-policy.skey

# Get key hash
cardano-cli address key-hash \
  --payment-verification-key-file nft-policy.vkey \
  --out-file nft-policy.hash

# Get current slot for time lock
CURRENT_SLOT=$(cardano-cli query tip --testnet-magic 1 | jq -r '.slot')
DEADLINE=$((CURRENT_SLOT + 10000000))  # ~115 days

# Create one-time minting policy (for true NFTs)
cat > nft-policy.script << EOF
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "$(cat nft-policy.hash)"
    },
    {
      "type": "before",
      "slot": ${DEADLINE}
    }
  ]
}
EOF

# Calculate policy ID
cardano-cli transaction policyid \
  --script-file nft-policy.script > nft-policy.id

echo "Policy ID: $(cat nft-policy.id)"
```

### Step 4: Create Metadata File

```bash
# NFT details
POLICY_ID=$(cat nft-policy.id)
NFT_NAME="MyFirstNFT"
NFT_NAME_HEX=$(echo -n "${NFT_NAME}" | xxd -ps | tr -d '\n')
IPFS_HASH="QmYourIPFSHash..."

# Create metadata JSON
cat > metadata.json << EOF
{
  "721": {
    "${POLICY_ID}": {
      "${NFT_NAME}": {
        "name": "My First NFT #001",
        "image": "ipfs://${IPFS_HASH}",
        "mediaType": "image/png",
        "description": "This is my first NFT on Cardano! A beautiful piece of digital art.",
        "attributes": {
          "Artist": "Your Name",
          "Collection": "First Collection",
          "Edition": "1 of 1",
          "Rarity": "Legendary"
        },
        "files": [
          {
            "name": "Original",
            "mediaType": "image/png",
            "src": "ipfs://${IPFS_HASH}"
          }
        ]
      }
    }
  }
}
EOF
```

### Step 5: Mint the NFT

```bash
# Your wallet address
MY_ADDR=$(cat ~/cardano/keys/payment.addr)

# Get UTXO for fees
cardano-cli query utxo --address ${MY_ADDR} --testnet-magic 1

# Select a UTXO
TX_IN="<txhash>#<index>"

# Build minting transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in ${TX_IN} \
  --tx-out "${MY_ADDR}+2000000+1 ${POLICY_ID}.${NFT_NAME_HEX}" \
  --mint "1 ${POLICY_ID}.${NFT_NAME_HEX}" \
  --mint-script-file nft-policy.script \
  --metadata-json-file metadata.json \
  --invalid-hereafter ${DEADLINE} \
  --change-address ${MY_ADDR} \
  --out-file mint-nft.raw

# Sign transaction
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file mint-nft.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --signing-key-file nft-policy.skey \
  --out-file mint-nft.signed

# Submit transaction
cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file mint-nft.signed

echo "NFT minted! Transaction submitted."
echo "Policy ID: ${POLICY_ID}"
echo "Asset Name: ${NFT_NAME}"
echo "Check your wallet for: ${POLICY_ID}.${NFT_NAME_HEX}"
```

### Step 6: Verify Your NFT

```bash
# Check your balance
cardano-cli query utxo --address ${MY_ADDR} --testnet-magic 1

# View on explorer
echo "View on Cardanoscan:"
echo "https://preview.cardanoscan.io/token/${POLICY_ID}${NFT_NAME_HEX}"
```

## 💻 Minting NFTs with Mesh SDK

```typescript
import { MeshWallet, Transaction, ForgeScript, AssetMetadata } from '@meshsdk/core';
import { BlockfrostProvider } from '@meshsdk/core';
import fs from 'fs';

const wallet = new MeshWallet({
  networkId: 0,
  fetcher: new BlockfrostProvider('your_project_id'),
  submitter: new BlockfrostProvider('your_project_id'),
  key: {
    type: 'mnemonic',
    words: ['your', 'seed', 'phrase', ...]
  }
});

async function mintNFT() {
  const usedAddress = await wallet.getUsedAddresses();
  const address = usedAddress[0];
  
  // Create minting policy
  const forgingScript = ForgeScript.withOneSignature(address);
  
  // NFT metadata
  const assetMetadata: AssetMetadata = {
    name: 'My NFT #001',
    image: 'ipfs://QmYourHash...',
    mediaType: 'image/png',
    description: 'My first Cardano NFT',
    attributes: {
      'Rarity': 'Legendary',
      'Power': '9000',
    },
    files: [
      {
        name: 'High Resolution',
        mediaType: 'image/png',
        src: 'ipfs://QmYourHash...',
      },
    ],
  };
  
  const tx = new Transaction({ initiator: wallet });
  
  // Mint NFT
  tx.mintAsset(
    forgingScript,
    {
      assetName: 'MyFirstNFT',
      assetQuantity: '1',
      metadata: assetMetadata,
      label: '721',
      recipient: address,
    }
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('NFT Minted!');
  console.log('Transaction Hash:', txHash);
  console.log('Policy ID:', forgingScript.policyId);
  
  return {
    txHash,
    policyId: forgingScript.policyId,
    assetName: 'MyFirstNFT',
  };
}

// Send NFT to another address
async function sendNFT(recipientAddress: string, policyId: string, assetName: string) {
  const assetNameHex = Buffer.from(assetName).toString('hex');
  const assetId = policyId + assetNameHex;
  
  const tx = new Transaction({ initiator: wallet });
  
  tx.sendAssets(
    recipientAddress,
    [
      {
        unit: assetId,
        quantity: '1',
      },
    ]
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('NFT sent:', txHash);
  return txHash;
}

// Burn NFT
async function burnNFT(policyId: string, assetName: string) {
  const usedAddress = await wallet.getUsedAddresses();
  const address = usedAddress[0];
  
  const forgingScript = ForgeScript.withOneSignature(address);
  
  const tx = new Transaction({ initiator: wallet });
  
  tx.mintAsset(
    forgingScript,
    {
      assetName: assetName,
      assetQuantity: '-1',  // Negative to burn
    }
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('NFT burned:', txHash);
  return txHash;
}

// Run
mintNFT()
  .then(result => console.log('Success:', result))
  .catch(error => console.error('Error:', error));
```

## 🎭 NFT Collection

### Create a Collection

```bash
# Collection parameters
COLLECTION_NAME="MyArtCollection"
COLLECTION_SIZE=100

# For each NFT in collection
for i in $(seq 1 ${COLLECTION_SIZE}); do
  NFT_NUMBER=$(printf "%03d" $i)
  NFT_NAME="${COLLECTION_NAME}${NFT_NUMBER}"
  NFT_NAME_HEX=$(echo -n "${NFT_NAME}" | xxd -ps | tr -d '\n')
  
  # Create metadata for this NFT
  cat > "metadata-${NFT_NUMBER}.json" << EOF
{
  "721": {
    "${POLICY_ID}": {
      "${NFT_NAME}": {
        "name": "${COLLECTION_NAME} #${NFT_NUMBER}",
        "image": "ipfs://QmHash${i}...",
        "attributes": {
          "Collection": "${COLLECTION_NAME}",
          "Edition": "${NFT_NUMBER} of ${COLLECTION_SIZE}"
        }
      }
    }
  }
}
EOF
  
  # Mint this NFT (add proper transaction building here)
  echo "Prepared metadata for ${NFT_NAME}"
done
```

## 👑 Royalties (CIP-27)

Add royalty information to your NFT:

```json
{
  "721": {
    "<policy_id>": {
      "<asset_name>": {
        "name": "My NFT",
        "image": "ipfs://...",
        "files": [...],
        "attributes": {...}
      }
    }
  },
  "777": {
    "<policy_id>": {
      "<asset_name>": {
        "rate": "0.05",
        "addr": "addr1_royalty_address_here"
      }
    }
  }
}
```

This sets a 5% royalty to the specified address.

## 🔍 Query NFT Information

```bash
# Using cardano-cli
cardano-cli query utxo \
  --address ${MY_ADDR} \
  --testnet-magic 1

# Using Blockfrost API
curl "https://cardano-preview.blockfrost.io/api/v0/assets/${POLICY_ID}${NFT_NAME_HEX}" \
  -H "project_id: your_project_id"

# Get metadata
curl "https://cardano-preview.blockfrost.io/api/v0/assets/${POLICY_ID}${NFT_NAME_HEX}/metadata" \
  -H "project_id: your_project_id"
```

## 🎨 Advanced Features

### Animated NFTs (GIFs, Videos)

```json
{
  "name": "Animated NFT",
  "image": "ipfs://QmThumbHash...",
  "mediaType": "image/gif",
  "files": [
    {
      "name": "Animation",
      "mediaType": "video/mp4",
      "src": "ipfs://QmVideoHash..."
    }
  ]
}
```

### Music NFTs

```json
{
  "name": "My Song",
  "image": "ipfs://QmCoverArtHash...",
  "mediaType": "audio/mpeg",
  "files": [
    {
      "name": "Audio",
      "mediaType": "audio/mpeg",
      "src": "ipfs://QmAudioHash..."
    }
  ],
  "attributes": {
    "Artist": "Your Name",
    "Genre": "Electronic",
    "Duration": "3:45"
  }
}
```

### 3D NFTs

```json
{
  "name": "3D Model",
  "image": "ipfs://QmPreviewHash...",
  "mediaType": "model/gltf-binary",
  "files": [
    {
      "name": "3D Model",
      "mediaType": "model/gltf-binary",
      "src": "ipfs://QmModelHash..."
    }
  ]
}
```

## 🛡️ Best Practices

1. **Use Time-Locked Policies**: Ensure true scarcity
2. **High-Quality Artwork**: Resolution matters
3. **IPFS Pinning**: Keep your content available
4. **Detailed Metadata**: Rich descriptions and attributes
5. **Test on Testnet**: Always test minting first
6. **Verify on Explorer**: Check metadata display
7. **Collection Planning**: Think long-term
8. **Community Engagement**: Build before minting

## 📊 NFT Marketplaces

List your NFTs on:
- **jpg.store**: https://jpg.store
- **CNFT.io**: https://cnft.io
- **Epoch.art**: https://epoch.art
- **ArtanoNFT**: https://artano.io

## 🚀 Next Steps

1. Mint your first NFT on testnet
2. Create a small collection (5-10 pieces)
3. List on a marketplace
4. Build an NFT minting dApp
5. Explore generative art

## 📖 Resources

- [CIP-25: NFT Metadata Standard](https://cips.cardano.org/cips/cip25/)
- [CIP-27: Royalty Standard](https://cips.cardano.org/cips/cip27/)
- [Cardano NFT Guide](https://docs.cardano.org/native-tokens/minting-nfts/)
- [IPFS Documentation](https://docs.ipfs.io/)
- [Mesh NFT Examples](https://meshjs.dev/apis/transaction/minting)

## ⚠️ Important Notes

- Policy keys must be secured - loss means inability to burn/modify
- Time-lock your policy for true NFTs (one-time mint)
- Test metadata rendering on explorers
- IPFS files should be pinned permanently
- Consider gas fees when minting collections

---

**Start creating your NFT collection today!** 🎨

You now have all the knowledge to mint professional NFTs on Cardano!
