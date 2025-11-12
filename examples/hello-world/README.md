# Hello World Smart Contract

Your first smart contract on Cardano! This example demonstrates the simplest possible validator that always succeeds.

## 🎯 What You'll Learn

- Basic smart contract structure
- How to compile a validator
- Deploying to testnet
- Interacting with your contract

## 📋 Prerequisites

- Cardano node and CLI installed
- Aiken installed (recommended) or Plutus setup
- Test ADA from faucet
- Basic understanding of UTXO model

## 🔷 Aiken Version (Recommended)

### Step 1: Create the Project

```bash
aiken new hello-world
cd hello-world
```

### Step 2: Write the Validator

Create `validators/hello.ak`:

```aiken
use aiken/transaction.{ScriptContext}

// The simplest validator - always succeeds
validator {
  fn hello_world(_datum: Data, _redeemer: Data, _context: ScriptContext) -> Bool {
    True
  }
}
```

### Step 3: Build the Contract

```bash
aiken check  # Type check
aiken build  # Compile to Plutus
```

This generates:
- `plutus.json` - Compiled Plutus script
- Blueprint for off-chain code

### Step 4: Test the Validator

Create `validators/hello.ak` with test:

```aiken
use aiken/transaction.{ScriptContext}

validator {
  fn hello_world(_datum: Data, _redeemer: Data, _context: ScriptContext) -> Bool {
    True
  }
}

test always_succeeds() {
  let datum = ""
  let redeemer = ""
  let ctx = placeholder_context()
  
  hello_world(datum, redeemer, ctx) == True
}
```

Run tests:
```bash
aiken test
```

## 🔶 Plutus Version

### Create the Validator

Create `HelloWorld.hs`:

```haskell
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module HelloWorld where

import           Plutus.V2.Ledger.Api
import           PlutusTx
import           PlutusTx.Prelude

-- The validator function
{-# INLINABLE mkValidator #-}
mkValidator :: BuiltinData -> BuiltinData -> BuiltinData -> ()
mkValidator _ _ _ = ()

-- Compile to Plutus Core
validator :: Validator
validator = mkValidatorScript $$(PlutusTx.compile [|| mkValidator ||])

-- Serialized script
validatorScript :: Script
validatorScript = unValidatorScript validator

-- Script address
validatorAddress :: Address
validatorAddress = scriptAddress validator
```

### Compile

```bash
cabal build
cabal run write-validator
```

## 💻 Deploying to Testnet

### Step 1: Get the Script Address

From Aiken output:
```bash
cat plutus.json | jq -r '.validators[0].compiledCode'
```

Or calculate from Plutus:
```bash
cardano-cli address build \
  --payment-script-file hello.plutus \
  --testnet-magic 1 \
  --out-file hello.addr
```

### Step 2: Send Funds to the Script

```bash
# Your address (change this)
MY_ADDR=$(cat ~/cardano/keys/payment.addr)

# Script address
SCRIPT_ADDR=$(cat hello.addr)

# Build transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in <YOUR_UTXO> \
  --tx-out "${SCRIPT_ADDR}+5000000" \
  --tx-out-datum-hash <DATUM_HASH> \
  --change-address ${MY_ADDR} \
  --out-file tx.raw

# Sign transaction
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file tx.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --out-file tx.signed

# Submit transaction
cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file tx.signed
```

### Step 3: Query the Script UTXO

```bash
cardano-cli query utxo \
  --address ${SCRIPT_ADDR} \
  --testnet-magic 1
```

### Step 4: Spend from the Script

```bash
# Get script UTXO
SCRIPT_UTXO="<txhash>#<index>"

# Build spending transaction
cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in ${SCRIPT_UTXO} \
  --tx-in-script-file hello.plutus \
  --tx-in-datum-value '{}' \
  --tx-in-redeemer-value '{}' \
  --tx-in-collateral <YOUR_COLLATERAL_UTXO> \
  --change-address ${MY_ADDR} \
  --out-file spend-tx.raw

# Sign and submit
cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file spend-tx.raw \
  --signing-key-file ~/cardano/keys/payment.skey \
  --out-file spend-tx.signed

cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file spend-tx.signed
```

## 🧪 Testing with Mesh (TypeScript)

Create `test.ts`:

```typescript
import { MeshWallet, Transaction, BlockfrostProvider } from '@meshsdk/core';
import fs from 'fs';

// Load compiled script
const script = JSON.parse(fs.readFileSync('plutus.json', 'utf8'));

// Initialize wallet
const wallet = new MeshWallet({
  networkId: 0, // 0 for testnet
  fetcher: new BlockfrostProvider('your_project_id'),
  submitter: new BlockfrostProvider('your_project_id'),
  key: {
    type: 'mnemonic',
    words: ['your', 'seed', 'phrase', ...]
  }
});

// Lock funds to script
async function lockFunds() {
  const tx = new Transaction({ initiator: wallet });
  
  tx.sendLovelace(
    {
      address: script.validators[0].address,
      datum: { value: "" }
    },
    "5000000"
  );
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('Locked funds at:', txHash);
}

// Unlock funds from script
async function unlockFunds() {
  const tx = new Transaction({ initiator: wallet });
  
  tx.redeemValue({
    value: script.validators[0],
    redeemer: { data: "" }
  });
  
  const unsignedTx = await tx.build();
  const signedTx = await wallet.signTx(unsignedTx);
  const txHash = await wallet.submitTx(signedTx);
  
  console.log('Unlocked funds:', txHash);
}

// Run
lockFunds()
  .then(() => console.log('Success!'))
  .catch(console.error);
```

## 📝 Key Concepts

### Datum
The data stored with the UTXO at the script address. In this simple example, we use empty data.

### Redeemer
The data provided when spending from the script. Also empty in this example.

### ScriptContext
Contains transaction information:
- Transaction inputs and outputs
- Signatories
- Validity range
- Other transaction metadata

### Why It Always Succeeds
The validator returns `True` without any checks, meaning anyone can spend the locked funds. This is just for learning - never use in production!

## 🎓 Learning Exercises

1. **Modify the validator** to only succeed if the redeemer is a specific number
2. **Add a signature check** to require a specific public key
3. **Implement time locking** using the validity range
4. **Create a datum** with custom data structure

## 🚀 Next Steps

- Try the [Native Tokens Example](../native-tokens/)
- Learn about [NFT Minting](../nft-minting/)
- Build a more complex validator with conditions
- Read the [Smart Contracts Guide](../../docs/02-smart-contracts.md)

## 🔗 Resources

- [Aiken Documentation](https://aiken-lang.org/)
- [Plutus Documentation](https://plutus.readthedocs.io/)
- [Cardano Developer Portal](https://developers.cardano.org/)
- [Cardano Stack Exchange](https://cardano.stackexchange.com/)

## ⚠️ Important Notes

- This validator has NO security - anyone can spend from it
- Always test on testnet first
- Never send real funds to test contracts
- Use collateral UTXOs for script transactions

---

**Congratulations on your first smart contract!** 🎉

You've learned the basics of validator structure and deployment. Now you're ready for more complex contracts!
