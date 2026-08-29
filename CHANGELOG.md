# Changelog

All notable changes to CryptoBank will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2026-08-28

### Added

#### Smart Contracts
- **CBToken** - Governance token with 100M supply
  - ERC20 standard
  - ERC20Votes for governance
  - ERC20Permit for gasless approvals
  - Ownable for admin control
  - Mint function with supply cap
  - Burn function

- **AToken** - Yield-bearing deposit token
  - ERC20 standard
  - RayMath library for precision
  - Pool-only mint/burn
  - Underlying balance tracking

- **LendingPool** - Core lending protocol
  - Supply assets for yield
  - Borrow against collateral
  - Repay loans
  - Liquidate positions
  - Pause functionality
  - Access control roles

- **InterestRateStrategy** - Dynamic rate model
  - Two-slope interest curve
  - Configurable parameters
  - Owner-only updates

- **CryptoBankGovernor** - DAO governance
  - OpenZeppelin Governor
  - 7-day voting period
  - 4% quorum
  - Timelock integration

- **PriceFeed** - Oracle integration
  - Chainlink adapter
  - Stale price protection
  - Range validation
  - Pause per feed

#### Testing
- **Unit Tests** - 23 tests
  - CBToken: 9 tests
  - LendingPool: 9 tests
  - Governance: 5 tests

- **Integration Tests** - 7 tests
  - Full lending flow
  - Multiple users
  - Error conditions

- **Invariant Tests** - 5 tests
  - Supply cap invariant
  - Balance conservation
  - Access control
  - Burn protection

- **E2E Tests** - 4 tests
  - Complete user journeys
  - Emergency pause
  - Governance flow

#### Frontend
- **Next.js 14** application
- **RainbowKit** wallet connection
- **Tailwind CSS** styling
- **Pages:**
  - Landing page
  - Dashboard
  - Lending
  - Swap
  - Governance

#### Documentation
- README.md
- ESTADO_ACTUAL.md
- FRONTEND.md
- TESTS_ADVANCED.md
- SECURITY_AUDIT.md
- DEPLOYMENT.md
- USER_GUIDE.md
- GAS_REPORT.md
- API references for all contracts
- Test documentation

#### Security
- Audit report
- Security checklist
- Slither configuration
- Analysis scripts

### Fixed
- **CRITICAL-01:** Missing userReserves update in supply function
  - Users could not withdraw deposited funds
  - Added proper state tracking

### Changed
- Updated LendingPool to track user balances
- Improved test coverage from 25 to 34 tests

---

## [0.2.0] - 2026-08-27

### Added
- InterestRateStrategy contract
- PriceFeed contract
- Basic test suite
- Foundry configuration

### Changed
- Updated LendingPool with interest rate integration

---

## [0.1.0] - 2026-08-26

### Added
- Initial project structure
- CBToken contract
- AToken contract
- LendingPool contract
- CryptoBankGovernor contract
- Basic tests
- Deployment script

---

## [Unreleased]

### Planned
- Flash loan support
- Multi-collateral support
- Cross-chain deployment
- Mobile app
- Advanced analytics
- Rate limiting
- Health factor implementation
- Borrow tracking

---

## Version History

| Version | Date | Status |
|---------|------|--------|
| 1.0.0 | 2026-08-28 | Current |
| 0.2.0 | 2026-08-27 | Archived |
| 0.1.0 | 2026-08-26 | Archived |
