# 🌊 ZK Mixer

<div align="center">

![ZK Mixer Banner](https://img.shields.io/badge/Privacy-Guaranteed-purple?style=for-the-badge)
![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?style=for-the-badge&logo=solidity)
![Noir](https://img.shields.io/badge/Noir-ZK_Circuits-000000?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A trustless, privacy-preserving cryptocurrency mixer powered by Zero-Knowledge Proofs**

[Features](#-features) • [Architecture](#-architecture) • [Installation](#-installation) • [Usage](#-usage) • [Documentation](#-documentation)

</div>

---

## 🎯 Overview

ZK Mixer is a decentralized privacy solution that enables users to break on-chain transaction links using zero-knowledge proofs. Built with Noir circuits and Solidity smart contracts, it ensures complete anonymity while maintaining cryptographic verifiability.

### ✨ Key Highlights

- 🔒 **Complete Privacy**: Break the link between deposit and withdrawal addresses
- 🛡️ **Zero-Knowledge Proofs**: Prove ownership without revealing identity using Noir
- 🌳 **Merkle Tree Privacy Set**: Anonymous set membership verification
- ⚡ **Gas Optimized**: Efficient on-chain verification with UltraHonk proofs
- 🔐 **Nullifier Protection**: Prevent double-spending with cryptographic nullifiers

---

## 🚀 Features

### Privacy Features
- **Anonymous Deposits**: Commit funds using a cryptographic hash
- **Unlinkable Withdrawals**: Withdraw to any address with zero-knowledge proofs
- **Merkle Tree Anonymity**: Your transaction hides in a set of all deposits
- **Nullifier System**: Ensures each deposit can only be withdrawn once

### Technical Features
- **Noir ZK Circuits**: Industry-standard zero-knowledge proof system
- **Poseidon2 Hashing**: ZK-friendly cryptographic hash function
- **UltraHonk Backend**: Efficient proof generation and verification
- **Incremental Merkle Tree**: Gas-efficient privacy set management
- **EVM Compatible**: Deployable on any Ethereum-compatible chain

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         USER FLOW                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  1. Generate    │
                    │  Commitment     │
                    │  (nullifier +   │
                    │   secret)       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  2. Deposit ETH │
                    │  with Commitment│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  3. Commitment  │
                    │  Added to       │
                    │  Merkle Tree    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  4. Generate ZK │
                    │  Proof (Noir)   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  5. Withdraw to │
                    │  New Address    │
                    └─────────────────┘
```

### Components

#### 🔷 Smart Contracts (`contracts/src/`)
- **Mixer.sol**: Main contract handling deposits, withdrawals, and proof verification
- **Verifier.sol**: UltraHonk proof verifier (auto-generated from Noir circuit)
- **IncrementalMerkleTree.sol**: Gas-efficient Merkle tree for anonymity set

#### ⚫ Noir Circuits (`circuits/src/`)
- **main.nr**: Core ZK circuit proving valid withdrawal
- **merkle_tree.nr**: Merkle proof verification logic

#### 🟦 Scripts (`js-scripts/`)
- **generateCommitment.ts**: Creates deposit commitments
- **generateProof.ts**: Generates zero-knowledge proofs
- **merkleTree.ts**: Builds and manages the Merkle tree

---

## 📦 Installation

### Prerequisites

```bash
# Node.js & npm
node --version  # v18+
npm --version   # v9+

# Foundry (Solidity development)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Noir (ZK circuit compiler)
curl -L https://noirup.dev | bash
noirup
```

### Setup

```bash
# Clone the repository
git clone https://github.com/Napcalx/ZK_Mixer.git
cd ZK_Mixer

# Install dependencies
npm install

# Compile Noir circuits
cd circuits
nargo compile
cd ..

# Compile Solidity contracts
cd contracts
forge install
forge build
cd ..
```

---

## 🎮 Usage

### 1️⃣ Generate Commitment

```bash
node js-scripts/generateCommitment.js
```

**Output:**
```
Commitment: 0x1a2b3c...
Nullifier: 0x4d5e6f...
Secret: 0x7a8b9c...
```

⚠️ **Save these values securely! You'll need them to withdraw.**

### 2️⃣ Deposit

```solidity
// Deposit 1 ETH with your commitment
mixer.deposit{value: 1 ether}(commitment);
```

Or using cast:
```bash
cast send <MIXER_ADDRESS> "deposit(bytes32)" <COMMITMENT> \
  --value 1ether \
  --private-key <YOUR_PRIVATE_KEY>
```

### 3️⃣ Generate Proof

```bash
node js-scripts/generateProof.js \
  <NULLIFIER> \
  <SECRET> \
  <RECIPIENT_ADDRESS> \
  <LEAF_1> <LEAF_2> ... <LEAF_N>
```

**Output:**
```
Proof: 0xaabbcc...
```

### 4️⃣ Withdraw

```bash
cast send <MIXER_ADDRESS> "withdraw(bytes,bytes32,address)" \
  <PROOF> \
  <NULLIFIER_HASH> \
  <RECIPIENT_ADDRESS> \
  --private-key <YOUR_PRIVATE_KEY>
```

🎉 **Congratulations!** You've successfully anonymized your transaction.

---

## 🧪 Testing

```bash
# Run all tests
cd contracts
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testDeposit

# Gas report
forge test --gas-report
```

---

## 🔐 Security Considerations

### ⚠️ Important Warnings

1. **Save Your Secrets**: Loss of nullifier/secret means loss of funds
2. **Anonymity Set Size**: Privacy increases with more deposits
3. **Network Privacy**: Use a VPN/Tor when withdrawing
4. **Timing Analysis**: Wait random intervals between deposit/withdrawal
5. **Amount Obfuscation**: Mix common denominations (0.1, 1, 10 ETH)

### 🛡️ Best Practices

- Never reuse deposit addresses
- Withdraw to fresh addresses
- Use different RPC endpoints for deposit/withdrawal
- Consider multiple mixing rounds for maximum privacy
- Clear browser cache after operations

---

## 📊 Gas Costs

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Deposit | ~100k | Includes Merkle tree insertion |
| Withdraw | ~350k | Includes ZK proof verification |
| Proof Generation | Off-chain | ~5-10 seconds |

---

## 🗺️ Roadmap

- [x] Core privacy mixer functionality
- [x] Noir circuit implementation
- [x] Solidity contracts
- [ ] Multi-denomination support
- [ ] Relayer network for gas-less withdrawals
- [ ] Frontend UI
- [ ] Compliance tool (selective disclosure)
- [ ] Cross-chain privacy bridge
- [ ] Audit by reputable firm

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Write tests for all new features
- Follow Solidity style guide
- Document all functions
- Run `forge fmt` before committing

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Resources

- **Noir Documentation**: https://noir-lang.org
- **Foundry Book**: https://book.getfoundry.sh
- **Poseidon Hash**: https://www.poseidon-hash.info
- **ZK Proofs Intro**: https://zkp.science

---

## 📧 Contact

**Napcalx** - [@Napcalx](https://github.com/Napcalx)

Project Link: [https://github.com/Napcalx/ZK_Mixer](https://github.com/Napcalx/ZK_Mixer)

---

<div align="center">

**⭐ Star this repo if you find it useful! ⭐**

Made with 💜 using Noir & Solidity

</div>
