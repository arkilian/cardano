# Smart Contract Development on Cardano

Learn how to build smart contracts on Cardano using Plutus, Aiken, and Marlowe. This guide will help you choose the right platform and get started with development.

## 🎯 Overview

Cardano offers three main platforms for smart contract development:

| Platform | Language | Best For | Difficulty | Performance |
|----------|----------|----------|------------|-------------|
| **Plutus** | Haskell | Complex dApps, maximum flexibility | Advanced | High |
| **Aiken** | Rust-inspired | Modern development, speed | Beginner-Intermediate | Very High |
| **Marlowe** | Visual DSL | Financial contracts, non-developers | Easy | Good |

## 📖 Understanding Cardano Smart Contracts

### The Extended UTXO Model

Cardano uses an Extended UTXO (EUTXO) model, different from Ethereum's account model:

- **UTXO**: Unspent Transaction Output
- **Datum**: Data attached to a UTXO (contract state)
- **Redeemer**: Data provided to spend a UTXO
- **Validator**: Script that validates spending conditions

**Key Advantages**:
- Deterministic transaction validation
- Better parallelization
- Predictable fees
- Enhanced security

### Smart Contract Structure

A Cardano smart contract consists of:

1. **On-chain code** (Validator/Script):
   - Runs on the blockchain
   - Validates transactions
   - Compiled to Plutus Core

2. **Off-chain code**:
   - Builds transactions
   - Interacts with wallets
   - Handles user interface
   - Can be written in any language

## 🔷 Plutus: The Original Smart Contract Platform

### What is Plutus?

Plutus is Cardano's primary smart contract platform, built on Haskell. It provides:
- Full expressiveness for complex logic
- Strong type safety
- Formal verification capabilities
- Mature tooling and documentation

### Getting Started with Plutus

#### Prerequisites
- Strong Haskell knowledge
- Understanding of functional programming
- Familiarity with monads and type systems

#### Setup

Install Plutus dependencies:
```bash
# Plutus is built into cardano-node, but you'll need additional tools
cabal update
cabal install plutus-core plutus-ledger-api plutus-tx
```

#### Your First Plutus Contract

A simple "Always Succeeds" validator:

```haskell
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE TemplateHaskell     #-}

module AlwaysSucceeds where

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

-- Get validator hash
validatorHash :: ValidatorHash
validatorHash = validatorHash validator
```

#### A More Realistic Example: Simple Lock Contract

```haskell
{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE NoImplicitPrelude   #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module SimpleLock where

import           Plutus.V2.Ledger.Api
import           Plutus.V2.Ledger.Contexts
import           PlutusTx
import           PlutusTx.Prelude

-- Define the datum (contract state)
data LockDatum = LockDatum
    { beneficiary :: PubKeyHash
    , deadline    :: POSIXTime
    }
PlutusTx.unstableMakeIsData ''LockDatum

-- Define the redeemer (unlock action)
data LockRedeemer = Unlock
PlutusTx.unstableMakeIsData ''LockRedeemer

-- Validator logic
{-# INLINABLE mkValidator #-}
mkValidator :: LockDatum -> LockRedeemer -> ScriptContext -> Bool
mkValidator dat Unlock ctx =
    traceIfFalse "beneficiary's signature missing" signedByBeneficiary &&
    traceIfFalse "deadline not reached" deadlineReached
  where
    info :: TxInfo
    info = scriptContextTxInfo ctx

    signedByBeneficiary :: Bool
    signedByBeneficiary = txSignedBy info $ beneficiary dat

    deadlineReached :: Bool
    deadlineReached = contains (from $ deadline dat) $ txInfoValidRange info
```

### Plutus Resources

- [Plutus Pioneer Program](https://github.com/input-output-hk/plutus-pioneer-program)
- [Plutus Documentation](https://plutus.readthedocs.io/)
- [Plutus Playground](https://playground.plutus.iohkdev.io/)
- [Cardano Developer Portal - Plutus](https://developers.cardano.org/docs/smart-contracts/plutus/)

## 🦀 Aiken: Modern Smart Contract Development

### What is Aiken?

Aiken is a modern smart contract language for Cardano, inspired by Rust. It offers:
- Easier syntax and learning curve
- Faster compilation and execution
- Better developer experience
- Excellent tooling and error messages

### Getting Started with Aiken

#### Installation

```bash
# On Linux/macOS
curl -sSfL https://install.aiken-lang.org | bash

# Verify installation
aiken --version
```

Or using Cargo (Rust package manager):
```bash
cargo install aiken
```

#### Create Your First Project

```bash
# Create a new project
aiken new my_first_contract
cd my_first_contract

# Project structure:
# my_first_contract/
# ├── aiken.toml          # Project configuration
# ├── lib/                # Library code
# └── validators/         # Smart contract validators
```

#### Hello World Validator

Create `validators/hello_world.ak`:

```aiken
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext}
use aiken/transaction/credential.{VerificationKey}

// A simple validator that always succeeds
validator {
  fn hello_world(_datum: Data, _redeemer: Data, _context: ScriptContext) -> Bool {
    True
  }
}
```

#### A More Complex Example: Vesting Contract

```aiken
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{ScriptContext, Spend, ValidityRange}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value

// Define the datum
type VestingDatum {
  beneficiary: Hash<Blake2b_224, VerificationKey>,
  deadline: Int,
}

// Define the redeemer
type VestingRedeemer {
  Claim
}

// Validator function
validator {
  fn vesting(
    datum: VestingDatum,
    redeemer: VestingRedeemer,
    context: ScriptContext,
  ) -> Bool {
    when redeemer is {
      Claim -> {
        let must_be_signed_by_beneficiary =
          list.has(context.transaction.extra_signatories, datum.beneficiary)
        
        let must_be_after_deadline = {
          let ValidityRange { lower_bound, .. } = context.transaction.validity_range
          lower_bound.bound_type >= datum.deadline
        }
        
        must_be_signed_by_beneficiary && must_be_after_deadline
      }
    }
  }
}
```

#### Build and Test

```bash
# Check your code
aiken check

# Build the validator
aiken build

# Run tests
aiken test

# Generate blueprint (for off-chain code)
aiken blueprint
```

### Aiken Features

**Type System**:
- Strong static typing
- Type inference
- Pattern matching
- Generics support

**Testing**:
```aiken
test hello_test() {
  hello_world(Void, Void, placeholder_context()) == True
}
```

**Built-in Functions**:
- List operations: `list.map`, `list.filter`, `list.fold`
- Hash functions: `blake2b_256`, `sha2_256`
- Cryptography: signature verification
- Transaction inspection

### Aiken Resources

- [Aiken Official Website](https://aiken-lang.org/)
- [Aiken Documentation](https://aiken-lang.org/language-tour)
- [Aiken GitHub](https://github.com/aiken-lang/aiken)
- [Aiken Examples](https://github.com/aiken-lang/aiken/tree/main/examples)

## 🎼 Marlowe: Smart Contracts for Finance

### What is Marlowe?

Marlowe is a domain-specific language (DSL) for financial contracts on Cardano. Key features:
- Visual development with Blockly
- No programming required
- Built-in financial primitives
- Automatic contract verification

### Who Should Use Marlowe?

Perfect for:
- Business users creating financial agreements
- Simple escrow and payment contracts
- Automated financial products
- Learning smart contract concepts

### Getting Started with Marlowe

#### Access Marlowe Playground

Visit: https://marlowe.iohk.io/

The playground provides:
- Visual contract editor (Blockly)
- Marlowe code editor
- Haskell editor
- JavaScript editor
- Simulation tools

#### Create Your First Contract

**Example: Simple Payment**

In Marlowe DSL:
```haskell
When [
  Case (Deposit "alice" "alice" ada 100)
    (Pay "alice" (Party "bob") ada 100 Close)
] 1700000000000 Close
```

This contract:
1. Waits for Alice to deposit 100 ADA
2. Immediately pays Bob 100 ADA
3. Closes the contract
4. Timeout: January 2024

#### Using Marlowe Blockly

1. Drag "When" block
2. Add "Deposit" condition
3. Add "Pay" action
4. Set parties and amounts
5. Simulate the contract
6. Deploy to testnet

### Marlowe Contract Types

**1. Escrow**:
```haskell
-- Buyer deposits funds
-- Seller delivers goods
-- Buyer confirms or disputes
-- Funds released accordingly
```

**2. Swap**:
```haskell
-- Party A deposits Token X
-- Party B deposits Token Y
-- Tokens are swapped atomically
```

**3. Zero-Coupon Bond**:
```haskell
-- Investor lends money
-- Borrower receives funds
-- After time, borrower repays with interest
```

### Marlowe CLI

Install Marlowe CLI for advanced usage:
```bash
# Available in cardano-node or separate installation
marlowe-cli --version
```

Deploy a contract:
```bash
# Create the contract
marlowe-cli run initialize \
  --contract-file contract.json \
  --state-file state.json

# Submit to blockchain
marlowe-cli run execute \
  --tx-in <utxo> \
  --change-address <address> \
  --contract-file contract.json \
  --state-file state.json
```

### Marlowe Resources

- [Marlowe Playground](https://marlowe.iohk.io/)
- [Marlowe Documentation](https://docs.marlowe.iohk.io/)
- [Marlowe Tutorial](https://developers.cardano.org/docs/smart-contracts/marlowe/)
- [Marlowe Examples](https://github.com/input-output-hk/marlowe-cardano/tree/main/marlowe-contracts)

## 🔧 Development Tools & Libraries

### Off-Chain Development

#### Mesh SDK (JavaScript/TypeScript)
```bash
npm install @meshsdk/core
```

Example usage:
```typescript
import { Transaction, ForgeScript } from '@meshsdk/core';

const tx = new Transaction({ initiator: wallet });
tx.sendLovelace('addr_test...', '5000000');
const unsignedTx = await tx.build();
const signedTx = await wallet.signTx(unsignedTx);
await wallet.submitTx(signedTx);
```

#### PyCardano (Python)
```bash
pip install pycardano
```

#### Lucid (TypeScript)
```bash
npm install lucid-cardano
```

### Testing Frameworks

**Plutus Application Backend (PAB)**:
- Local testing environment
- Contract simulation
- Wallet integration

**Aiken Testing**:
```aiken
use aiken/list

test example_test() {
  let result = my_function(42)
  result == expected_value
}
```

### Debugging Tools

**Trace Debugging**:
```haskell
traceIfFalse "Error message" condition
```

**cardano-cli Debug Mode**:
```bash
cardano-cli transaction build --debug-mode
```

## 🎓 Learning Path

### Week 1-2: Foundations
- [ ] Understand UTXO model
- [ ] Learn about datums and redeemers
- [ ] Set up development environment
- [ ] Deploy a simple "always succeeds" validator

### Week 3-4: Basic Contracts
- [ ] Create a simple lock contract
- [ ] Implement basic token logic
- [ ] Test on testnet
- [ ] Build simple off-chain code

### Week 5-6: Intermediate
- [ ] Multi-signature contracts
- [ ] Time-locked contracts
- [ ] NFT minting validator
- [ ] Integrate with frontend

### Week 7-8: Advanced
- [ ] Complex state management
- [ ] Oracle integration
- [ ] Optimization techniques
- [ ] Security auditing

## 🔐 Security Best Practices

### General
1. **Always test on testnet first**
2. **Use formal verification when possible**
3. **Audit your contracts**
4. **Follow principle of least privilege**
5. **Handle edge cases**

### Common Vulnerabilities

**Double Satisfaction**:
```haskell
-- BAD: Validator can be satisfied twice
-- GOOD: Check for uniqueness
elem txOutRef inputs
```

**Incorrect Time Handling**:
```haskell
-- Ensure proper time range validation
contains validRange txInfoValidRange
```

**Missing Signature Checks**:
```haskell
-- Always verify required signatures
txSignedBy info requiredSigner
```

## 📚 Example Projects to Study

1. **Simple Vending Machine**: Basic state machine
2. **NFT Marketplace**: Token trading with royalties
3. **Auction Contract**: Time-based bidding
4. **DAO Governance**: Voting and treasury management
5. **DeFi Swap**: Automated market maker

## 🚀 Next Steps

1. Choose your platform (Aiken recommended for beginners)
2. Complete the "Hello World" example
3. Build a simple vesting contract
4. Deploy to testnet
5. Integrate with a frontend
6. Join the community for feedback

## 📖 Additional Resources

- [Cardano Developer Portal](https://developers.cardano.org/)
- [Plutus Community Documentation](https://plutus-community.readthedocs.io/)
- [Cardano Stack Exchange](https://cardano.stackexchange.com/)
- [IOG Technical Discord](https://discord.gg/inputoutput)

---

**Start building your first smart contract today!** 🚀

Choose your platform and dive into the examples in the `/examples` directory.
