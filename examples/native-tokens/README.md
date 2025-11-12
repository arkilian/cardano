# Native Tokens on Cardano

Learn how to create and manage native tokens on Cardano without smart contracts!

## 🎯 What You'll Learn

- Understanding native tokens vs ERC-20
- Creating custom tokens
- Minting and burning tokens
- Token metadata
- Multi-asset transactions

## 💡 What are Native Tokens?

Unlike Ethereum's ERC-20 tokens (which require smart contracts), Cardano native tokens are first-class citizens on the blockchain. They:

- Don't require smart contracts for basic operations
- Have the same transaction costs as ADA
- Can be sent in the same transaction as ADA
- Support multi-asset outputs
- Have built-in security features

## 🔑 Key Concepts

### Policy ID
A unique identifier for your token, derived from the minting policy script.

### Asset Name
The human-readable name of your token (optional).

### Minting Policy
Script that controls who can mint or burn tokens:
- **Time-locked**: Can only mint within a time range
- **Signature-based**: Requires specific signatures
- **Always succeeds**: Anyone can mint (dangerous!)
- **Never succeeds**: Fixed supply

## 🚀 Creating Your First Token

### Step 1: Generate Policy Keys

```bash
cd ~/cardano/tokens
mkdir my-token && cd my-token

# Generate policy key pair
cardano-cli address key-gen \
  --verification-key-file policy.vkey \
  --signing-key-file policy.skey

# Get key hash
cardano-cli address key-hash \
  --payment-verification-key-file policy.vkey \
  --out-file policy.hash
```

### Step 2: Create Minting Policy

**Simple policy (anyone with key can mint)**:

```bash
# Create policy script
cat > policy.script << EOF
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "$(cat policy.hash)"
    }
  ]
}
EOF

# Calculate policy ID
cardano-cli transaction policyid \
  --script-file policy.script > policy.id

cat policy.id
```

**Time-locked policy (can only mint before deadline)**:

```bash
# Get current slot
CURRENT_SLOT=$(cardano-cli query tip --testnet-magic 1 | jq -r '.slot')

# Set deadline (e.g., 1 million slots from now)
DEADLINE=$((CURRENT_SLOT + 1000000))

# Create time-locked policy
cat > policy-time.script << EOF
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "$(cat policy.hash)"
    },
    {
      "type": "before",
      "slot": ${DEADLINE}
    }
  ]
}
EOF

cardano-cli transaction policyid \
  --script-file policy-time.script > policy-time.id
```

### Step 3: Mint Your Tokens

```bash
# Token details
POLICY_ID=$(cat policy.id)
TOKEN_NAME="MyToken"
TOKEN_NAME_HEX=$(echo -n ${TOKEN_NAME} | xxd -ps | tr -d '\n')
AMOUNT=1000000  # 1 million tokens

# Your wallet address
MY_ADDR=$(cat ~/cardano/keys/payment.addr)

# Get a UTXO for transaction fee
cardano-cli query utxo --address ${MY_ADDR} --testnet-magic 1

# Set TX_IN to a UTXO from above
TX_IN="<txhash>#<index>"

# Build minting transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in ${TX_IN} \
  --tx-out "${MY_ADDR}+2000000+${AMOUNT} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
  --mint "${AMOUNT} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
  --mint-script-file policy.script \
  --change-address ${MY_ADDR} \
  --out-file mint-tx.raw

# Sign transaction
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file mint-tx.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --signing-key-file policy.skey \
  --out-file mint-tx.signed

# Submit transaction
cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file mint-tx.signed

# Wait and check your balance
cardano-cli query utxo --address ${MY_ADDR} --testnet-magic 1
```

### Step 4: Send Tokens

```bash
# Recipient address
RECIPIENT_ADDR="addr_test1..."

# Token amount to send
SEND_AMOUNT=1000

# Build transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in <YOUR_UTXO_WITH_TOKENS> \
  --tx-out "${RECIPIENT_ADDR}+2000000+${SEND_AMOUNT} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
  --change-address ${MY_ADDR} \
  --out-file send-tx.raw

# Sign and submit
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file send-tx.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --out-file send-tx.signed

cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file send-tx.signed
```

### Step 5: Burn Tokens

```bash
# Amount to burn
BURN_AMOUNT=-500000  # Negative value to burn

# Build burn transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in <YOUR_UTXO_WITH_TOKENS> \
  --tx-out "${MY_ADDR}+2000000+500000 ${POLICY_ID}.${TOKEN_NAME_HEX}" \
  --mint "${BURN_AMOUNT} ${POLICY_ID}.${TOKEN_NAME_HEX}" \
  --mint-script-file policy.script \
  --change-address ${MY_ADDR} \
  --out-file burn-tx.raw

# Sign and submit
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file burn-tx.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --signing-key-file policy.skey \
  --out-file burn-tx.signed

cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file burn-tx.signed
```

## 📋 Adding Token Metadata

Token metadata is stored off-chain but registered on-chain through the Cardano Token Registry.

### Create Metadata JSON

```json
{
  "721": {
    "<policy_id>": {
      "<token_name>": {
        "name": "My Token",
        "description": "My first Cardano native token",
        "ticker": "MTK",
        "decimals": 6,
        "url": "https://mytoken.io",
        "logo": "data:image/png;base64,..."
      }
    }
  }
}
```

### Submit to Token Registry

1. Fork the [Cardano Token Registry](https://github.com/cardano-foundation/cardano-token-registry)
2. Add your metadata to `mappings/`
3. Create a pull request
4. Wait for approval

## 💻 Using Mesh SDK (TypeScript)

```typescript
import { MeshWallet, Transaction, ForgeScript } from '@meshsdk/core';
import { BlockfrostProvider } from '@meshsdk/core';

const wallet = new MeshWallet({
  networkId: 0,
  fetcher: new BlockfrostProvider('your_project_id'),
  submitter: new BlockfrostProvider('your_project_id'),
  key: {
    type: 'mnemonic',
    words: ['your', 'seed', 'phrase', ...]
  }
});

// Mint tokens
async function mintToken() {
  const usedAddress = await wallet.getUsedAddresses();
  const address = usedAddress[0];
  
  // Define minting policy
  const forgingScript = ForgeScript.withOneSignature(address);
  
  const tx = new Transaction({ initiator: wallet });
  
  // Mint 1000 tokens
  tx.mintAsset(
    forgingScript,
    {
      assetName: 'MyToken',
      assetQuantity: '1000',
    }
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('Minted tokens:', txHash);
  return txHash;
}

// Send tokens
async function sendToken(recipientAddress: string, amount: string) {
  const tx = new Transaction({ initiator: wallet });
  
  tx.sendAssets(
    recipientAddress,
    [
      {
        unit: '<policy_id><token_name_hex>',
        quantity: amount,
      },
    ]
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('Sent tokens:', txHash);
  return txHash;
}

// Burn tokens
async function burnToken(amount: string) {
  const usedAddress = await wallet.getUsedAddresses();
  const address = usedAddress[0];
  
  const forgingScript = ForgeScript.withOneSignature(address);
  
  const tx = new Transaction({ initiator: wallet });
  
  // Negative amount to burn
  tx.mintAsset(
    forgingScript,
    {
      assetName: 'MyToken',
      assetQuantity: `-${amount}`,
    }
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('Burned tokens:', txHash);
  return txHash;
}
```

## 🎓 Advanced Topics

### Multi-Signature Policies

Require multiple keys to mint:

```json
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "key_hash_1"
    },
    {
      "type": "sig",
      "keyHash": "key_hash_2"
    },
    {
      "type": "before",
      "slot": 50000000
    }
  ]
}
```

### One-Time Minting (Fixed Supply)

Create a policy that can only be used once:

```json
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "<your_key_hash>"
    },
    {
      "type": "before",
      "slot": <slot_plus_1_hour>
    }
  ]
}
```

After minting, the time expires and no more tokens can be created.

### Fractional Tokens

Use the `decimals` field in metadata to specify decimal places:

```json
{
  "decimals": 6
}
```

This means 1,000,000 base units = 1 display unit.

## 🔍 Querying Token Information

```bash
# View all assets at an address
cardano-cli query utxo --address <address> --testnet-magic 1

# Check specific token balance
cardano-cli query utxo \
  --address <address> \
  --testnet-magic 1 \
  | grep <policy_id>
```

Using Blockfrost API:
```bash
curl "https://cardano-preview.blockfrost.io/api/v0/assets/${POLICY_ID}${TOKEN_NAME_HEX}" \
  -H "project_id: your_project_id"
```

## 📊 Use Cases

1. **Utility Tokens**: Access to services or platforms
2. **Governance Tokens**: DAO voting rights
3. **Reward Points**: Loyalty programs
4. **Stablecoins**: Pegged to fiat currencies
5. **Gaming Assets**: In-game currencies
6. **Real-world Assets**: Tokenized commodities

## 🛡️ Best Practices

1. **Secure Your Policy Keys**: Loss = permanent loss of minting rights
2. **Use Time Locks**: Prevent unlimited minting
3. **Test on Testnet**: Always test before mainnet
4. **Document Metadata**: Provide clear token information
5. **Consider Multi-sig**: For important tokens
6. **Plan Token Economics**: Supply, distribution, use case

## 🚀 Next Steps

- Create your own token on testnet
- Add custom metadata and logo
- Build a token faucet dApp
- Create an NFT (see [NFT Minting Example](../nft-minting/))
- Integrate tokens into a frontend application

## 📖 Resources

- [Native Tokens Documentation](https://docs.cardano.org/native-tokens/learn/)
- [Token Registry](https://github.com/cardano-foundation/cardano-token-registry)
- [CIP-25: NFT Metadata Standard](https://cips.cardano.org/cips/cip25/)
- [Mesh SDK Docs](https://meshjs.dev/)

---

**Start creating your own tokens today!** 🪙

Native tokens are one of Cardano's most powerful features, and now you know how to use them!
