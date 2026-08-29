# CryptoBank - Banco Descentralizado de Criptomonedas

## Stack 100% Crypto - Plan de Desarrollo Completo

### Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Next.js 14+)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │   Wallet    │  │  Dashboard  │  │   Trading   │  │  DAO      │  │
│  │  Connection │  │   DeFi      │  │     DEX     │  │  Voting   │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘  │
│                          │                                          │
│              ethers.js / viem + wagmi + RainbowKit                  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     INDEXACIÓN (The Graph)                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Subgraph - Eventos on-chain                    │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│              SMART CONTRACTS (Solidity ^0.8.24)                     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    CORE PROTOCOL                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │  LendingPool │  │  SwapRouter │  │  LiquidityManager   │  │  │
│  │  │  (Aave V3)  │  │  (Uniswap)  │  │  (AMM Pools)        │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    TOKEN ECONOMY                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │  CBToken    │  │  aTokens    │  │  LP Tokens          │  │  │
│  │  │  (ERC20)    │  │  (Yield)    │  │  (Pooled)           │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    GOBERNANZA DAO                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │ Governor    │  │  Timelock   │  │  GovernorToken      │  │  │
│  │  │ (OpenZepp)  │  │  Controller │  │  (ERC20Votes)       │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    INFRAESTRUCTURA                            │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │  OracleHub  │  │  PriceFeed  │  │  AccessControl      │  │  │
│  │  │  (Chainlink)│  │  (Multi)    │  │  (Roles)            │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BLOCKCHAIN LAYER                                 │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Ethereum Mainnet / Sepolia Testnet             │   │
│  │                     (EVM Compatible)                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              External Integrations                           │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐               │   │
│  │  │ Uniswap   │  │   Aave    │  │  Chainlink│               │   │
│  │  │ V3        │  │   V3      │  │  Oracles  │               │   │
│  │  └───────────┘  └───────────┘  └───────────┘               │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. Stack Tecnológico

### Smart Contracts
| Componente | Tecnología | Versión |
|------------|------------|---------|
| Lenguaje | Solidity | ^0.8.24 |
| Framework | Foundry | Latest |
| Librerías Base | OpenZeppelin Contracts | v5.x |
| Testing | Foundry + Fork Tests | - |
| Deploy | Foundry Scripts + CREATE2 | - |
| Verificación | Etherscan Verify | - |

### Frontend
| Componente | Tecnología | Versión |
|------------|------------|---------|
| Framework | Next.js | 14+ |
| UI Library | Tailwind CSS + shadcn/ui | Latest |
| Web3 | ethers.js / viem | Latest |
| Wallet | wagmi + RainbowKit | Latest |
| State | Zustand / React Query | Latest |
| Graph | @apollo/client | Latest |

### Infraestructura
| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| Indexación | The Graph | Eventos on-chain |
| Oráculos | Chainlink Price Feeds | Precios |
| Storage | IPFS / Arweave | Metadata |
| Monitoreo | Tenderly + Forta | Alertas |
| CI/CD | GitHub Actions | Deploy automatizado |

---

## 2. Arquitectura de Smart Contracts

### 2.1 Módulo Lending (Préstamos DeFi)

**Inspiración: Aave V3**

```
contracts/
├── lending/
│   ├── LendingPool.sol          # Pool principal de liquidez
│   ├── LendingPoolConfigurator.sol  # Configuración de mercados
│   ├── ReserveLogic.sol         # Lógica de reservas
│   ├── LiquidationLogic.sol     # Motor de liquidaciones
│   ├── BorrowLogic.sol          # Préstamos
│   ├── SupplyLogic.sol          # Depósitos
│   ├── InterestRateStrategy.sol # Modelo de tasas
│   └── StableDebtToken.sol      # Tokens de deuda estable
```

**Funcionalidades:**
- Depósito de activos para earn yield (aTokens)
- Préstamos over-collateralized (colateral > 150%)
- Flash loans con fee de 0.09%
- Liquidaciones con bonus para keepers
- Interest rate model (linear utilización)
- Supply/borrow caps por activo

### 2.2 Módulo DEX (Exchange/Trading)

**Inspiración: Uniswap V3**

```
contracts/
├── dex/
│   ├── UniswapV3Factory.sol     # Factory de pools
│   ├── UniswapV3Pool.sol        # Pool de liquidez
│   ├── SwapRouter.sol           # Router de swaps
│   ├── NonfungiblePositionManager.sol  # NFTs de posición
│   ├── Oracle.sol               # TWAP Oracle
│   ├── TickMath.sol             # Matemáticas de ticks
│   ├── SqrtPriceMath.sol        # Precios
│   └── libraries/
│       ├── Tick.sol
│       ├── TickBitmap.sol
│       ├── Position.sol
│       └── SwapMath.sol
```

**Funcionalidades:**
- Liquidity concentrated (rangos personalizados)
- Multi-hop swaps
- Fee tiers (0.01%, 0.05%, 0.3%, 1%)
- TWAP Oracle integrado
- NFTs para posiciones de liquidez

### 2.3 Módulo Gobernanza DAO

**Inspiración: OpenZeppelin Governor**

```
contracts/
├── governance/
│   ├── CryptoBankGovernor.sol   # Contrato gobernor
│   ├── GovernorToken.sol        # Token de gobernanza (CB)
│   ├── TimelockController.sol   # Delay para ejecución
│   └── CryptoBankTimelock.sol   # Timelock custom
```

**Funcionalidades:**
- Creación de propuestas (mínimo 1% tokens)
- Período de votación: 7 días
- Quorum: 10% del supply
- Timelock: 48 horas antes de ejecución
- Voto: simple, con delegación
- Ejecución automática de propuestas aprobadas

### 2.4 Módulo Token Economy

```
contracts/
├── tokens/
│   ├── CBToken.sol              # Token de gobernanza ERC20
│   ├── CBTokenVotes.sol         # Extensión de votación
│   ├── aWETH.sol                # aToken para WETH
│   ├── aUSDC.sol                # aToken para USDC
│   ├── DebtToken.sol            # Token de deuda
│   └── LPToken.sol              # Token de LP (ERC721)
```

### 2.5 Módulo Infraestructura

```
contracts/
├── infrastructure/
│   ├── OracleHub.sol            # Oráculo centralizado
│   ├── PriceFeed.sol            # Chainlink adapter
│   ├── AccessControl.sol        # Roles y permisos
│   ├── Pausable.sol             # Emergency pause
│   └── Proxy.sol                # UUPS Proxy pattern
```

---

## 3. Estructura del Proyecto

```
cryptobank/
├── contracts/                    # Smart Contracts
│   ├── core/
│   │   ├── interfaces/
│   │   ├── libraries/
│   │   └── mocks/
│   ├── lending/
│   ├── dex/
│   ├── governance/
│   ├── tokens/
│   └── infrastructure/
│
├── script/                       # Foundry Scripts
│   ├── Deploy.s.sol
│   ├── DeployLending.s.sol
│   ├── DeployDEX.s.sol
│   ├── DeployGovernance.s.sol
│   └── Verify.s.sol
│
├── test/                         # Tests
│   ├── unit/
│   ├── integration/
│   ├── invariant/
│   ├── e2e/
│   └── helpers/
│
├── frontend/                     # Next.js Frontend
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── lending/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   ├── trading/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   ├── governance/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   └── dashboard/
│   │       ├── page.tsx
│   │       └── components/
│   │
│   ├── components/
│   │   ├── ui/
│   │   ├── wallet/
│   │   ├── charts/
│   │   └── shared/
│   │
│   ├── hooks/
│   │   ├── useLendingPool.ts
│   │   ├── useSwapRouter.ts
│   │   ├── useGovernance.ts
│   │   └── useTokenBalance.ts
│   │
│   ├── lib/
│   │   ├── contracts.ts         # Direcciones ABIs
│   │   ├── config.ts            # Chain config
│   │   └── utils.ts
│   │
│   └── abis/                    # ABIs de contratos
│
├── subgraph/                     # The Graph
│   ├── schema.graphql
│   ├── subgraph.yaml
│   └── src/
│
├── deploy/                       # Deploy artifacts
├── audit/                        # Auditorías
└── docs/                         # Documentación
```

---

## 4. Contratos Inteligentes - Especificación

### 4.1 CBToken (Token de Gobernanza)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract CBToken is ERC20, ERC20Votes {
    uint256 public constant MAX_SUPPLY = 100_000_000 * 1e18; // 100M tokens
    
    constructor() ERC20("CryptoBank Token", "CB") ERC20Permit("CryptoBank Token") {
        _mint(msg.sender, MAX_SUPPLY);
    }
    
    // Required overrides
    function _updateVotesFromIndexedBalanceChange(...) internal override {}
    function nonces(address owner) public view override returns (uint256) {}
}
```

### 4.2 LendingPool (Pool de Préstamos)

```solidity
// Estructuras de datos
struct ReserveData {
    uint256 configuration;
    uint128 liquidityIndex;
    uint128 currentLiquidityRate;
    uint128 variableBorrowIndex;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    uint16 id;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint256 accruedToTreasury;
    uint256 unbacked;
    uint256 isolationModeTotalDebt;
}

// Funciones principales
function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
function withdraw(address asset, uint256 amount, address to) external returns (uint256);
function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external returns (uint256);
function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
function liquidate(address collateralAsset, uint256 debtAsset, address user, uint256 debtToCover, bool receiveAToken) external returns (uint256);
```

### 4.3 UniswapV3Pool

```solidity
// Slot 0 del pool
struct Slot0 {
    uint160 sqrtPriceX96;
    int24 tick;
    uint16 observationIndex;
    uint16 observationCardinality;
    uint16 observationCardinalityNext;
    uint8 feeProtocol;
    uint8 unlocked;
}

// Funciones principales
function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data) external returns (int256 amount0, int256 amount1);
function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (int256 amount0, int256 amount1);
function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1);
function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
```

### 4.4 CryptoBankGovernor

```solidity
// Basado en OpenZeppelin Governor
contract CryptoBankGovernor is 
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    uint256 public constant VOTING_DELAY = 1; // 1 block
    uint256 public constant VOTING_PERIOD = 50400; // ~7 días (12s/block)
    uint256 public constant PROPOSAL_THRESHOLD = 10000 * 1e18; // 10k tokens
    
    constructor(IVotes _token, TimelockController _timelock)
        Governor("CryptoBank Governor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) // 4% quorum
        GovernorTimelockControl(_timelock)
    {}
    
    function votingDelay() public pure override returns (uint256) { return VOTING_DELAY; }
    function votingPeriod() public pure override returns (uint256) { return VOTING_PERIOD; }
    function quorum(uint256 blockNumber) public view override returns (uint256) {
        return super.quorum(blockNumber);
    }
}
```

---

## 5. Deployment Pipeline

### 5.1 Testnet (Sepolia)

```bash
# 1. Setup
forge install
forge build

# 2. Deploy contratos core
forge script script/Deploy.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

# 3. Verificar en Etherscan
forge verify-contract <address> <contract> --etherscan-api-key $ETHERSCAN_KEY

# 4. Configurar mercados
forge script script/ConfigureMarkets.s.sol --rpc-url sepolia
```

### 5.2 Mainnet

```bash
# 1. Audit finalizado
# 2. Deploy con CREATE2 para dirección determinística
# 3. Timelock activo
# 4. Ownership transferido a DAO
```

---

## 6. Testing Strategy

### 6.1 Unit Tests
```bash
# Cobertura mínima: 95%
forge test --coverage
```

### 6.2 Integration Tests
```bash
# Tests contra protocolos reales (fork)
forge test --fork-url $MAINNET_RPC
```

### 6.3 Invariant/Fuzz Tests
```bash
# Property-based testing
forge test --match-contract InvariantTest
```

### 6.4 E2E Tests
```bash
# Flujo completo de usuario
forge test --match-path "test/e2e/*"
```

### 6.5 Auditorías Requeridas
- [ ] Slither analysis
- [ ] Mythril analysis  
- [ ] Manual audit (Trail of Bits / OpenZeppelin / Consensys)
- [ ] Bug bounty program ( Immunefi )

---

## 7. Frontend - Componentes Clave

### 7.1 Lending Dashboard
- Supply balance por activo
- Borrow capacity y health factor
- Interest rates (supply/borrow APR)
- Withdraw/Repay modals
- Transaction history

### 7.2 Trading Interface
- Token swap (multi-hop)
- Price impact calculator
- Liquidity pool creation
- LP position management
- Price charts (TradingView)

### 7.3 Governance Portal
- Active proposals
- Voting interface
- Proposal creation wizard
- Voting history
- Delegate management

### 7.4 Portfolio Overview
- Total balance USD
- Asset allocation pie chart
- PnL tracking
- Transaction history
- Risk metrics

---

## 8. Seguridad

### 8.1 Patrones de Seguridad
- Checks-Effects-Interactions pattern
- ReentrancyGuard en funciones críticas
- Pull over Push para transfers
- Rate limiting en oráculos
- Emergency pause functionality
- Timelock en cambios de parámetros

### 8.2 Auditorías
- Análisis estático (Slither)
- Fuzzing (Foundry)
- Formal verification (opcional)
- Audit externo profesional
- Bug bounty (Immunefi - $100K+ pool)

### 8.3 Monitoreo
- Tenderly para alertas
- Forta para detección de ataques
- Custom bots para liquidaciones
- Dashboard de métricas on-chain

---

## 9. Roadmap

### Fase 1: Core (Semanas 1-4)
- [ ] Setup proyecto Foundry
- [ ] LendingPool básico
- [ ] aTokens y DebtTokens
- [ ] Interest rate model
- [ ] Oracle integration (Chainlink)
- [ ] Tests unitarios (95%+ coverage)

### Fase 2: DEX (Semanas 5-8)
- [ ] Uniswap V3 fork/custom
- [ ] Concentrated liquidity
- [ ] SwapRouter
- [ ] Fee tiers
- [ ] TWAP Oracle
- [ ] LP NFTs

### Fase 3: Governance (Semanas 9-10)
- [ ] CBToken (ERC20Votes)
- [ ] Governor (OpenZeppelin)
- [ ] TimelockController
- [ ] Proposal flow completo

### Fase 4: Frontend (Semanas 11-16)
- [ ] Wallet connection
- [ ] Dashboard principal
- [ ] Lending interface
- [ ] Trading interface
- [ ] Governance portal
- [ ] Responsive design

### Fase 5: Testing & Audit (Semanas 17-20)
- [ ] Integration tests
- [ ] Fork tests
- [ ] Invariant tests
- [ ] Slither/Mythril
- [ ] External audit
- [ ] Bug bounty setup

### Fase 6: Launch (Semanas 21-24)
- [ ] Testnet deployment
- [ ] Community testing
- [ ] Bug fixes
- [ ] Mainnet deployment
- [ ] Documentation final
- [ ] Marketing launch

---

## 10. Dependencias

### foundry.toml
```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200
via_ir = false

[profile.default.fuzz]
runs = 256
max_test_rejects = 65536

[profile.default.invariant]
runs = 256
depth = 15
```

---

## 11. Comandos de Desarrollo

```bash
# Instalación
forge install

# Build
forge build

# Tests
forge test
forge test -vvv  # verbose
forge test --coverage

# Lint
solhint 'contracts/**/*.sol'

# Formateo
forge fmt

# Deploy (ejemplo)
forge script script/Deploy.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify

# Indexar eventos (The Graph)
graph codegen
graph deploy crypto-bank
```

---

## 12. Métricas de Éxito

| Métrica | Objetivo |
|---------|----------|
| Test Coverage | > 95% |
| Gas Optimization | < 200k gas/swap |
| Audit Score | 0 vulnerabilities criticos |
| Uptime | 99.9% |
| TVL (6 meses) | $10M+ |
| Users (1 año) | 10,000+ |
| DAO Proposals | 50+ activas |

---

*Última actualización: 2026*
*Stack: 100% Crypto/Open Source*
*Blockchain: Ethereum*
