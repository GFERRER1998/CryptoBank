# CryptoBank Frontend - Estado Actual y Guía de Desarrollo

## 📋 Resumen Ejecutivo

| Aspecto | Estado |
|---------|--------|
| **Framework** | Next.js 14 + TypeScript |
| **Web3 Stack** | RainbowKit 2 + Wagmi 2 + Viem 2 + TanStack Query 5 |
| **Styling** | Tailwind CSS |
| **Estado Actual** | **MOCK UI** - Puramente visual, sin conexión a contratos reales |
| **Contratos Conectados** | ❌ No conectados (direcciones y ABIs listos en `lib/contracts.ts`) |

---

## 🗂️ Estructura del Frontend

```
frontend/
├── app/
│   ├── page.tsx                 # Landing page (Hero + Stats mock + RecentActivity mock)
│   ├── layout.tsx               # Layout con Providers (RainbowKit + Wagmi)
│   ├── dashboard/page.tsx       # Dashboard usuario (mock data)
│   ├── lending/page.tsx         # Supply/Borrow interface (MOCK - botones no funcionan)
│   ├── swap/page.tsx            # Token Swap interface (MOCK)
│   └── governance/page.tsx      # DAO Voting interface (MOCK)
│
├── components/
│   ├── Providers.tsx            # RainbowKit + Wagmi + React Query setup
│   ├── Navbar.tsx               # Navegación con ConnectButton
│   ├── StatsCard.tsx            # Tarjetas de estadísticas
│   └── RecentActivity.tsx       # Actividad reciente (mock data)
│
├── lib/
│   ├── config.ts                # Configuración de chains (Sepolia, Mainnet)
│   └── contracts.ts             # ✅ Direcciones reales Sepolia + ABIs completos
│
├── hooks/                       # 🔴 VACÍO - Pendiente implementar
│   ├── useLendingPool.ts        # Por crear
│   ├── useTokenBalance.ts       # Por crear
│   ├── useGovernance.ts         # Por crear
│   └── usePriceFeed.ts          # Por crear
│
├── package.json
├── tsconfig.json
├── tailwind.config.js
├── next.config.js
└── postcss.config.js
```

---

## ✅ Lo Que Ya Existe (Completado)

### 1. Configuración Web3 (`lib/contracts.ts`)

**Direcciones Sepolia Deployadas (2026-08-28):**
```typescript
export const CB_TOKEN_ADDRESS = "0xdAdf416Bf5972477390f493e19b818Ad1aB716e9"
export const LENDING_POOL_ADDRESS = "0x2C1BAe355B41926a310B649B962faE85Fb8E57D1"
export const GOVERNOR_ADDRESS = "0x60292093044b8884829455aF06Aca8E6912e3BC9"
export const TIMELOCK_ADDRESS = "0x1217f72DFBE3499F9ccF047F3C07cABb978F49A8"
export const PRICE_FEED_ADDRESS = "0xDf612D3422a748f00Fee370f60Cd3C54A161AA63"
export const INTEREST_RATE_STRATEGY_ADDRESS = "0x7A0Af01164c6e06c74a9CeD88A378814Ec9B2144"
```

**Tokens Sepolia:**
```typescript
export const SEPOLIA_TOKENS = {
  WETH: "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9",
  USDC: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
  WBTC: "0x29f2D40B0605204364af54EC677bD022dA425d03",
  LINK: "0x779877A7B0D9E8603169DdbD7836e478b4624789",
}
```

**AToken Addresses (creados al inicializar reservas):**
```typescript
export const ATOKEN_ADDRESSES = {
  WETH: "0x5aE60199a9b65CD7E76CFb2EF2F1e5FD3A144B63",
  USDC: "0x5D15249052dd3807E67cE09fe09898c49161eBEF",
  WBTC: "0xd471dBF2aFA70A23174546c90329570E8513d6E0",
  LINK: "0xE916B749cb9e07eB2542bC148fa08519011C0fD6",
}
```

**ABIs Disponibles:**
- `CB_TOKEN_ABI` - balanceOf, totalSupply, delegate
- `LENDING_POOL_ABI` - supply, withdraw, borrow, repay, getReserveData, getUserReserveData, getReserves
- `ATOKEN_ABI` - balanceOf, totalSupply, scaledBalanceOf, scaledTotalSupply, getUnderlyingBalance, UNDERLYING_ASSET_ADDRESS
- `INTEREST_RATE_STRATEGY_ABI` - calculateInterestRates, optimalUtilization, baseVariableBorrowRate, variableRateSlope1, variableRateSlope2
- `PRICE_FEED_ABI` - getAssetPrice, getAssetsPrices, getFeedData, getFeedAssets

### 2. Páginas UI Completas (Visual Only)

| Página | Componentes | Estado |
|--------|-------------|--------|
| **Home** (`/`) | Hero, Stats Grid (4 cards hardcoded), Features Grid (3 links), RecentActivity | ✅ Visual |
| **Dashboard** (`/dashboard`) | Portfolio overview, asset allocation, PnL mock | ✅ Visual |
| **Lending** (`/lending`) | Supply/Borrow tabs, Asset selector (ETH/USDC/CB), Amount input, MAX button, APY display, Market table | ✅ Visual |
| **Swap** (`/swap`) | Token selector, amount inputs, price impact, swap button | ✅ Visual |
| **Governance** (`/governance`) | Proposals list, vote buttons, create proposal form | ✅ Visual |

### 3. Componentes Reutilizables

- **Providers.tsx** - WagmiConfig, RainbowKitProvider, QueryClientProvider configurados para Sepolia
- **Navbar.tsx** - Navigation links + RainbowKit ConnectButton
- **StatsCard.tsx** - Card con título, valor, cambio %, icono
- **RecentActivity.tsx** - Lista de actividad mock (tx hash, tipo, amount, timestamp)

---

## 🔴 Lo Que FALTA para Frontend Real (Fase 4)

### Nuevos Hooks Requeridos en `frontend/hooks/`

#### `useLendingPool.ts` - Conexión a LendingPool Real
```typescript
// Funciones a implementar:
supply(asset: Address, amount: bigint, onBehalfOf: Address): Promise<Hash>
withdraw(asset: Address, amount: bigint, to: Address): Promise<Hash>
borrow(asset: Address, amount: bigint, onBehalfOf: Address): Promise<Hash>
repay(asset: Address, amount: bigint, onBehalfOf: Address): Promise<Hash>
getReserveData(asset: Address): Promise<ReserveData>
getUserReserveData(asset: Address, user: Address): Promise<UserReserveData>
getHealthFactor(user: Address): Promise<bigint>           // NUEVO - Health Factor real
getReserves(): Promise<Address[]>
```

#### `useTokenBalance.ts` - ERC20 Interactions
```typescript
balanceOf(token: Address, account: Address): Promise<bigint>
allowance(token: Address, owner: Address, spender: Address): Promise<bigint>
approve(token: Address, spender: Address, amount: bigint): Promise<Hash>
getTokenInfo(token: Address): Promise<{name, symbol, decimals}>
```

#### `useGovernance.ts` - DAO Operations
```typescript
propose(targets: Address[], values: bigint[], calldatas: Bytes[], description: string): Promise<Hash>
vote(proposalId: bigint, support: 0|1|2): Promise<Hash>
delegate(delegatee: Address): Promise<Hash>
getProposals(): Promise<Proposal[]>
getProposalState(proposalId: bigint): Promise<ProposalState>
getVotes(account: Address): Promise<bigint>
```

#### `usePriceFeed.ts` - Oracle Queries
```typescript
getAssetPrice(asset: Address): Promise<bigint>
getAssetsPrices(assets: Address[]): Promise<bigint[]>
getFeedData(asset: Address): Promise<FeedData>
```

### Integración en Páginas Existentes

| Página | Hooks a Conectar | Cambios Requeridos |
|--------|------------------|-------------------|
| `/lending` | `useLendingPool`, `useTokenBalance`, `usePriceFeed` | Reemplazar mock handlers con llamadas reales, mostrar health factor, loading states, error handling |
| `/dashboard` | `useTokenBalance`, `useLendingPool` | Mostrar balances reales, positions activas, health factor por asset |
| `/swap` | `useTokenBalance`, (futuro `useSwapRouter`) | Conectar a Uniswap V3 cuando exista |
| `/governance` | `useGovernance`, `useTokenBalance` | Propuestas reales, voting power, delegation UI |

---

## 🚀 Cómo Ver el Frontend Actual (MOCK)

### Opción A: pnpm (Recomendado para Windows)
```bash
cd frontend
pnpm install
pnpm dev
```

### Opción B: yarn
```bash
cd frontend
yarn install
yarn dev
```

### Opción C: npm con flags
```bash
cd frontend
npm install --legacy-peer-deps --ignore-scripts
npm run dev
```

**Luego abre:** http://localhost:3000

### Páginas Disponibles
| URL | Descripción |
|-----|-------------|
| `http://localhost:3000/` | Home - Landing page |
| `http://localhost:3000/dashboard` | Dashboard usuario |
| `http://localhost:3000/lending` | Lending UI (MOCK) |
| `http://localhost:3000/swap` | Swap UI (MOCK) |
| `http://localhost:3000/governance` | Governance UI (MOCK) |

---

## ⚙️ Configuración de Entorno

### Variables de Entorno Necesarias (`.env.local`)
```env
# WalletConnect Project ID (obtener en https://cloud.walletconnect.com)
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here

# RPC URLs (opcional - usa defaults de Wagmi)
NEXT_PUBLIC_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_key
NEXT_PUBLIC_MAINNET_RPC_URL=https://mainnet.infura.io/v3/your_key
```

### Chain Configuration (`lib/config.ts`)
```typescript
// Ya configurado para:
- Sepolia (Chain ID: 11155111) - Testnet actual
- Ethereum Mainnet (Chain ID: 1) - Para futuro
```

---

## 📦 Dependencias Principales (`package.json`)

```json
{
  "dependencies": {
    "next": "^14.2.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@rainbow-me/rainbowkit": "^2.1.0",
    "wagmi": "^2.9.0",
    "viem": "^2.9.0",
    "@tanstack/react-query": "^5.28.0"
  },
  "devDependencies": {
    "typescript": "^5.3.3",
    "@types/node": "^20.11.10",
    "@types/react": "^18.2.47",
    "@types/react-dom": "^18.2.18",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.33",
    "tailwindcss": "^3.4.1",
    "eslint": "^8.56.0",
    "eslint-config-next": "^14.2.0"
  }
}
```

---

## 🔗 Contratos Inteligentes - Estado Actual (Fase 3 ✅)

### Contratos Deployados en Sepolia

| Contrato | Dirección | Funcionalidad Clave |
|----------|-----------|---------------------|
| **CBToken** | `0xdAdf416Bf5972477390f493e19b818Ad1aB716e9` | ERC20 + ERC20Votes + ERC20Permit (100M supply) |
| **LendingPool** | `0x2C1BAe355B41926a310B649B962faE85Fb8E57D1` | Supply, Borrow, Withdraw, Repay, Liquidate, **Health Factor**, **Borrow Tracking**, **Caps** |
| **InterestRateStrategy** | `0x7A0Af01164c6e06c74a9CeD88A378814Ec9B2144` | Two-slope model (kink) |
| **CryptoBankGovernor** | `0x60292093044b8884829455aF06Aca8E6912e3BC9` | DAO voting, timelock 48h |
| **TimelockController** | `0x1217f72DFBE3499F9ccF047F3C07cABb978F49A8` | Execution delay |
| **PriceFeed** | `0xDf612D3422a748f00Fee370f60Cd3C54A161AA63` | Chainlink ETH/BTC/LINK + **Mock USDC $1.00** |

### Nuevas Capacidades Fase 3
- ✅ **Health Factor Real**: `(Σ collateral * price * threshold) / (Σ debt * price)`
- ✅ **Borrow Tracking**: `totalScaledVariableDebt` en ReserveData
- ✅ **Supply/Borrow Caps**: `setLiquidityCap`, `setBorrowCap` (solo POOL_ADMIN_ROLE)
- ✅ **USDC Mock Feed**: PriceFeed soporta `mockPrice` para stablecoins sin Chainlink
- ✅ **Multisig 2/3**: `SimpleMultisig` con PAUSER_ROLE para emergency pause
- ✅ **Roles Transferidos**: PAUSER→Multisig, ADMIN→Timelock, PriceFeed→Governor

---

## 📝 Scripts de Deploy (Foundry)

```bash
# Compilar
forge build

# Tests (34/34 passing)
forge test

# Deploy principal (CBToken, Timelock, Governor, LendingPool)
forge script script/Deploy.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

# Inicializar reservas (WETH, USDC, WBTC, LINK)
forge script script/InitReserves.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

# Configurar PriceFeed (Chainlink + Mock USDC)
forge script script/ConfigurePriceFeed.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

# Setup Multisig + transferir roles
forge script script/SetupMultisig.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
```

**Variables `.env` requeridas:**
```env
PRIVATE_KEY=0x...
IR_STRATEGY_ADDRESS=0x...  # Deployed InterestRateStrategy
PRICE_FEED_ADDRESS=0x...   # Deployed PriceFeed
```

---

## 🎯 Próximos Pasos - Fase 4 (Frontend Real + DEX)

### Sprint 1: Frontend Real Integration (2-3 semanas)
- [ ] Crear `frontend/hooks/useLendingPool.ts`
- [ ] Crear `frontend/hooks/useTokenBalance.ts`
- [ ] Crear `frontend/hooks/usePriceFeed.ts`
- [ ] Conectar `/lending` - supply, borrow, withdraw, repay reales
- [ ] Conectar `/dashboard` - balances reales, positions, health factor
- [ ] Agregar loading states, error handling, toast notifications
- [ ] Implementar approve flow automático

### Sprint 2: Governance Integration (1-2 semanas)
- [ ] Crear `frontend/hooks/useGovernance.ts`
- [ ] Conectar `/governance` - proposiciones reales, voting, delegation
- [ ] Proposal creation wizard UI

### Sprint 3: DEX/Trading (4-6 semanas)
- [ ] Uniswap V3 fork (Factory, Pool, Router, NFT Position Manager)
- [ ] Concentrated liquidity
- [ ] TWAP Oracle
- [ ] Conectar `/swap` - swaps reales, LP positions

---

## 📚 Referencias

- [ESTADO_ACTUAL.md](./ESTADO_ACTUAL.md) - Estado completo del proyecto
- [ROADMAP.md](./ROADMAP.md) - Roadmap detallado fases 3-6
- [plan.md](./plan.md) - Plan original completo
- [Foundry Book](https://book.getfoundry.sh/) - Documentación Foundry
- [Wagmi Docs](https://wagmi.sh/) - Hooks React para Ethereum
- [RainbowKit Docs](https://www.rainbowkit.com/) - Wallet connection
- [Viem Docs](https://viem.sh/) - TypeScript Ethereum library

---

*Última actualización: 2026-08-28 - Fase 3 Completada, Frontend en Mock UI*