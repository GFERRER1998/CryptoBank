# Contributing to CryptoBank

Thank you for your interest in contributing to CryptoBank! This document provides guidelines and information for contributors.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Pull Requests](#pull-requests)
- [Style Guidelines](#style-guidelines)
- [Security](#security)

---

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment
- No tolerance for harassment or discrimination

---

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) ^18.0.0
- [Foundry](https://book.getfoundry.sh/)
- [Git](https://git-scm.com/)
- [VS Code](https://code.visualstudio.com/) (recommended)

### Fork and Clone

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/cryptobank.git
   cd cryptobank
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/cryptobank/cryptobank.git
   ```

---

## Development Setup

### Install Dependencies

```bash
# Smart contracts
forge install

# Frontend
cd frontend
npm install
cd ..
```

### Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

### Run Tests

```bash
forge test
```

### Start Frontend

```bash
cd frontend
npm run dev
```

---

## Making Changes

### Branch Naming

Use descriptive branch names:

```
feature/add-flash-loans
fix/health-factor-calculation
docs/update-deployment-guide
refactor/optimize-gas
test/add-invariant-tests
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add flash loan support
fix: correct health factor calculation
docs: update deployment guide
refactor: optimize storage layout
test: add invariant tests for lending pool
```

### Development Workflow

1. Create feature branch:
   ```bash
   git checkout -b feature/your-feature
   ```

2. Make changes

3. Run tests:
   ```bash
   forge test -vvv
   ```

4. Run linter (if configured):
   ```bash
   forge fmt
   ```

5. Commit changes:
   ```bash
   git add .
   git commit -m "feat: your feature"
   ```

6. Push to fork:
   ```bash
   git push origin feature/your-feature
   ```

7. Create Pull Request

---

## Testing

### Test Categories

| Type | Location | Purpose |
|------|----------|---------|
| Unit | `test/unit/` | Individual function tests |
| Integration | `test/integration/` | Multi-contract flows |
| Invariant | `test/invariant/` | Security properties |
| E2E | `test/e2e/` | Complete user journeys |

### Writing Tests

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/YourContract.sol";

contract YourContractTest is Test {
    YourContract public contract;

    function setUp() public {
        contract = new YourContract();
    }

    function test_YourFunction() public {
        // Arrange
        uint256 expected = 100;

        // Act
        uint256 result = contract.yourFunction();

        // Assert
        assertEq(result, expected);
    }
}
```

### Running Specific Tests

```bash
# By contract
forge test --match-contract YourContractTest

# By function
forge test --match-test test_YourFunction

# With verbosity
forge test -vvvv
```

### Coverage

```bash
forge test --coverage
```

Target: >80% coverage

---

## Pull Requests

### PR Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] New tests added (if applicable)

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. All PRs require at least 1 review
2. CI must pass
3. No merge conflicts
4. Documentation updated if needed

---

## Style Guidelines

### Solidity

```solidity
// 1. Pragma
pragma solidity ^0.8.24;

// 2. Imports
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 3. Contract
contract MyContract is ERC20 {
    // Constants
    uint256 public constant MAX_SUPPLY = 1000;

    // State variables
    uint256 public totalDeposits;

    // Events
    event Deposit(address user, uint256 amount);

    // Errors
    error InsufficientBalance();

    // Modifiers
    modifier onlyOwner() {
        _;
    }

    // Constructor
    constructor() ERC20("Token", "TKN") {}

    // Functions
    function deposit() external {}
}
```

### NatSpec Documentation

```solidity
/**
 * @notice Brief description
 * @dev Detailed explanation
 * @param paramName Description
 * @return Description
 */
function myFunction(uint256 paramName) public view returns (uint256) {
    return paramName;
}
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Contracts | PascalCase | `LendingPool` |
| Functions | camelCase | `getUserBalance` |
| Variables | camelCase | `totalDeposits` |
| Constants | UPPER_SNAKE_CASE | `MAX_SUPPLY` |
| Events | PascalCase | `Deposit` |
| Errors | PascalCase | `InsufficientBalance` |

---

## Security

### Reporting Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead, email security@cryptobank.finance with:

1. Description of vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

### Security Checklist

- [ ] No reentrancy vulnerabilities
- [ ] Proper access control
- [ ] Input validation
- [ ] Overflow protection (Solidity 0.8+)
- [ ] Safe external calls
- [ ] Gas limit considerations

---

## Questions?

- Discord: discord.gg/cryptobank
- Twitter: @CryptoBank
- Email: dev@cryptobank.finance

---

Thank you for contributing!
