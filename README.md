# CryptoBank 🏦

Decentralized banking protocol on Ethereum. Supply, borrow, swap, and govern.

## Features

- **Lending & Borrowing** - Supply assets to earn interest, borrow against collateral
- **Token Swap** - Trade tokens with minimal slippage
- **DAO Governance** - Participate in protocol decisions
- **Yield Tokens** - aTokens that grow with interest

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) ^18.0.0
- [Foundry](https://book.getfoundry.sh/) (for smart contracts)

### Installation

```bash
# Clone repo
git clone https://github.com/your-org/cryptobank.git
cd cryptobank

# Install dependencies
forge install
cd frontend && npm install && cd ..
```

### Development

```bash
# Run smart contract tests
forge test

# Start frontend
cd frontend
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## Architecture

```
cryptobank/
├── src/                    # Smart Contracts
│   ├── tokens/            # CBToken, AToken
│   ├── lending/           # LendingPool, InterestRate
│   ├── governance/        # DAO Governor
│   └── infrastructure/    # PriceFeed (Chainlink)
│
├── test/                  # Tests
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   ├── invariant/         # Security invariants
│   └── e2e/               # End-to-end tests
│
├── frontend/              # Next.js Frontend
│   ├── app/               # Pages
│   ├── components/        # React components
│   └── lib/               # Utilities
│
└── audit/                 # Security audit docs
```

## Smart Contracts

| Contract | Description |
|----------|-------------|
| CBToken | Governance token (100M supply) |
| AToken | Yield-bearing deposit token |
| LendingPool | Core lending/borrowing logic |
| InterestRateStrategy | Dynamic interest rate model |
| CryptoBankGovernor | DAO voting system |
| PriceFeed | Chainlink oracle adapter |

## Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific suite
forge test --match-contract LendingPoolTest

# Run coverage
forge test --coverage
```

**Test Coverage:** 39 tests, 100% passing

## Frontend

- **Framework:** Next.js 14
- **Wallet:** RainbowKit
- **Styling:** Tailwind CSS

### Pages

- `/` - Landing page
- `/dashboard` - User portfolio
- `/lending` - Supply & borrow
- `/swap` - Token exchange
- `/governance` - DAO voting

## Deployment

See [Deployment Guide](docs/DEPLOYMENT.md)

```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --verify
```

## Security

- ReentrancyGuard on all external calls
- Pausable for emergency shutdown
- Access control with roles
- Invariant testing
- Static analysis with Slither

See [Security Audit](docs/SECURITY_AUDIT.md)

## Documentation

- [Frontend Docs](docs/FRONTEND.md)
- [Advanced Tests](docs/TESTS_ADVANCED.md)
- [Security Audit](docs/SECURITY_AUDIT.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [User Guide](docs/USER_GUIDE.md)
- [Current Status](ESTADO_ACTUAL.md)

## Contributing

1. Fork the repo
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open PR

## License

MIT © 2026 CryptoBank
