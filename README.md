#  On-Chain Tournament Prize Vault

> Bringing transparency and automation to eSports prize pools! 🏆

## Overview

The On-Chain Tournament Prize Vault is a decentralized solution for managing and distributing eSports tournament prizes using smart contracts on the Stacks blockchain.

### ✨ Key Features

- 🔒 Secure prize pool management
- 🎯 Automated prize distribution
- 🏅 NFT participation badges
- 💰 Community staking
- 🎲 Game proposal system
- 🎁 Tournament sponsorship system
- 📊 Player statistics tracking

## Smart Contract Functions

### Tournament Management
- `create-tournament`: Create new tournaments
- `register-player`: Register players for tournaments
- `stake-tokens`: Add tokens to prize pool
- `declare-winner`: Distribute prizes to winners
- `cancel-tournament`: Cancel active tournaments
- `refund-stakes`: Refund stakes for cancelled tournaments

### Community Features
- `propose-game`: Suggest new games
- `vote-game-proposal`: Vote on game proposals
- `sponsor-tournament`: Enable external sponsorships to boost prize pools

### Read-Only Functions
- `get-tournament-info`: View tournament details
- `get-participant-status`: Check player registration
- `get-sponsor-contribution`: Track sponsorship amounts per tournament
- `get-player-stats`: Retrieve player performance metrics

## Usage

1. Deploy the contract
2. Create a tournament using `create-tournament`
3. Players register using `register-player`
4. Community members can stake tokens
5. External sponsors can contribute to prize pools via `sponsor-tournament`
6. Owner declares winner and prizes are distributed automatically
7. Owner can cancel tournaments if needed and refund stakes

## Development

Built with Clarinet and Clarity for the Stacks blockchain.
```

Git commit message:
```
feat: Implement MVP for On-Chain Tournament Prize Vault with core functionality 🎮
```

PR Title:
```
[MVP] On-Chain Tournament Prize Vault Implementation
```

PR Description:
```
This PR introduces the initial MVP for the On-Chain Tournament Prize Vault:

Key additions:
- Tournament creation and management
- Player registration system
- Prize pool staking functionality
- Automated winner distribution
- Game proposal voting system

The implementation focuses on core functionality while maintaining security and simplicity. Ready for initial testing and feedback.

