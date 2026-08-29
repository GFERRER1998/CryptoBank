# CryptoBank - Roadmap Completo: Testnet a Mainnet

## 📊 Estado Actual (Resumen)

| Componente | Estado | Detalles |
|------------|--------|----------|
| **Smart Contracts Core** | ✅ 6/6 | CBToken, AToken, LendingPool, InterestRateStrategy, PriceFeed, Governor |
| **Tests** | ✅ 34/34 | Unit, Integration, Invariant, E2E - 100% passing |
| **Frontend** | ✅ 5 páginas | Home, Dashboard, Lending, Swap, Governance (UI mockups) |
| **Deploy Testnet** | ✅ Sepolia | 6 contratos + 4 reservas (WETH, USDC, WBTC, LINK) |
| **Documentación** | ✅ Completa | README, plan.md, ESTADO_ACTUAL, audit docs |

---

## 🎯 FASE 3: COMPLETAR TESTNET (Inmediato - 1-2 semanas)

### 3.1 Fixes Críticos de LendingPool

| Tarea | Archivo | Esfuerzo | Prioridad |
|-------|---------|----------|-----------|
| **Health Factor real** | `LendingPool.sol:696` | 2h | 🔴 Crítico |
| **Borrow tracking real** | `LendingPool.sol:684` | 3h | 🔴 Crítico |
| **Supply/Borrow caps** | `ReserveData` + init | 2h | 🟡 Alto |
| **User collateral tracking** | `UserReserveData` | 2h | 🟡 Alto |

### 3.2 PriceFeed - USDC Feed

| Tarea | Archivo | Esfuerzo | Prioridad |
|-------|---------|----------|-----------|
| Mock USDC/USD feed o feed alternativo | `PriceFeed.sol` + script | 1h | 🔴 Crítico |
| Rate limiting por feed | `PriceFeed.sol` | 2h | 🟡 Alto |

### 3.3 Access Control & Multisig

| Tarea | Archivo | Esfuerzo | Prioridad |
|-------|---------|----------|-----------|
| Deploy Gnosis Safe Multisig (2/3) | Script nuevo | 1h | 🔴 Crítico |
| Transferir PAUSER_ROLE → Multisig | Script | 30m | 🔴 Crítico |
| Transferir POOL_ADMIN_ROLE → Timelock | Script | 30m | 🔴 Crítico |
| Transferir FEED_ADMIN_ROLE → Governor | Script | 30m | 🟡 Alto |

### 3.4 Testing Extensivo Testnet

| Tarea | Esfuerzo | Prioridad |
|-------|----------|-----------|
| Fork tests contra mainnet (Aave, Chainlink) | 4h | 🟡 Alto |
| Stress testing con múltiples usuarios | 2h | 🟡 Alto |
| Gas optimization review | 3h | 🟢 Medio |

---

## 🎯 FASE 4: DEX / TRADING (4-6 semanas)

### 4.1 Uniswap V3 Core (Basado en plan.md)

```
contracts/dex/
├── UniswapV3Factory.sol        # Factory de pools
├── UniswapV3Pool.sol           # Pool con concentrated liquidity
├── SwapRouter.sol              # Router multi-hop
├── NonfungiblePositionManager.sol  # NFTs de posición
├── Oracle.sol                  # TWAP Oracle
├── libraries/
│   ├── TickMath.sol
│   ├── SqrtPriceMath.sol
│   ├── SwapMath.sol
│   ├── TickBitmap.sol
│   └── Position.sol
```

### 4.2 Integración con LendingPool

- OracleHub que combine Chainlink + TWAP
- Collateral factors basados en TWAP
- Liquidaciones usando Uniswap V3

### 4.3 Frontend Trading

- Swap interface funcional (no mock)
- Pool creation UI
- LP position management (NFTs)

---

## 🎯 FASE 5: GOVERNANCE HARDENING (1-2 semanas)

### 5.1 Completar Governor Flow

- Proposal creation wizard en frontend
- Delegation UI
- Vote delegation tracking
- Emergency proposals (short timelock)

### 5.2 Timelock Controller

- Verificar 48h delay en testnet
- Multi-sig executors
- Admin delay para parámetros críticos

---

## 🎯 FASE 6: AUDITORÍA Y PRODUCCIÓN (4-8 semanas)

### 6.1 Auditoría Interna

- [ ] Slither analysis completo
- [ ] Mythril / Echidna fuzzing
- [ ] Formal verification (health factor, liquidation)

### 6.2 Auditoría Externa

- Selección de auditor (Trail of Bits, OpenZeppelin, Consensys)
- Scope: 6 contratos core + DEX (si listo)
- Timeline: 2-4 semanas
- Budget: $50K-150K

### 6.3 Bug Bounty

- Immunefi program ($100K+ pool)
- Triage process definido

### 6.3 Mainnet Deploy

| Paso | Comando/Script |
|------|----------------|
| CREATE2 deterministic deploy | `forge script script/DeployMainnet.s.sol --broadcast --verify` |
| Verificar Etherscan | `forge verify-contract` |
| Inicializar reservas con caps | `ConfigureMarkets.s.sol` |
| Transfer ownership → DAO | Timelock queue + execute |
| Monitoring setup | Tenderly + Forta |

---

## 📋 Checklist de Seguridad (del SECURITY_CHECKLIST.md)

### Pre-Deploy Mainnet - Bloqueadores

- [ ] External audit completed, 0 critical/high
- [ ] Multisig deployed (2/3 o 3/5)
- [ ] PAUSER_ROLE → Multisig
- [ ] POOL_ADMIN_ROLE → Timelock (48h)
- [ ] FEED_ADMIN_ROLE → Governor
- [ ] Supply/Borrow caps en todas las reservas
- [ ] Health factor calculation correcto
- [ ] Borrow tracking implementado
- [ ] Rate limiting en PriceFeed
- [ ] Multiple oracle support (fallback)

### Post-Deploy Monitoring

- [ ] Alertas: large withdrawals, utilization spikes
- [ ] TVL tracking dashboard
- [ ] Governance proposal monitor
- [ ] Emergency pause bot (auto-pause en anomalías)

---

## 📦 Archivos a Crear/Modificar

### Smart Contracts (nuevos)

```
script/
├── DeployMainnet.s.sol          # Deploy con CREATE2
├── ConfigureMarkets.s.sol       # Init reserves con caps
├── SetupMultisig.s.sol          # Deploy Gnosis + transfer roles
├── SetupGovernance.s.sol        # Transfer admin roles
└── VerifyAll.s.sol              # Verificación Etherscan

contracts/dex/                    # Fase 4 - Uniswap V3 fork
contracts/lending/LendingPoolConfigurator.sol  # Admin de mercados
```

### Smart Contracts (modificaciones)

```
src/lending/LendingPool.sol
  - _calculateHealthFactor() real implementation
  - _getTotalBorrows() real implementation
  - supply/borrow caps enforcement
  - User collateral enabled/disabled

src/infrastructure/PriceFeed.sol
  - Rate limiting por asset
  - Multiple oracle support
  - Mock USDC feed para testnet
```

### Frontend (funcionalidad real)

```
frontend/hooks/
├── useLendingPool.ts      # Supply, borrow, withdraw, repay
├── useSwapRouter.ts       # Swap, add/remove liquidity
├── useGovernance.ts       # Propose, vote, delegate
└── useTokenBalance.ts     # Real-time balances

frontend/app/lending/page.tsx  # Conectar a contratos reales
frontend/app/swap/page.tsx     # Conectar a Uniswap V3
frontend/app/governance/page.tsx  # Proposal creation + voting
```

### Testing

```
test/fork/                      # Fork tests contra mainnet
test/integration/FullFlow.t.sol # E2E completo
```

---

## ⏱️ Timeline Estimado

| Fase | Duración | Entregable |
|------|----------|------------|
| **3. Testnet Completion** | 1-2 sem | Testnet production-ready |
| **4. DEX/Trading** | 4-6 sem | Uniswap V3 funcional |
| **5. Governance Hardening** | 1-2 sem | DAO completamente operativo |
| **6. Audit + Mainnet** | 4-8 sem | Mainnet launch |

**Total: 10-18 semanas** (dependiendo de auditoría externa)

---

## 💰 Costos Estimados

| Item | Costo |
|------|-------|
| Auditoría externa | $50K-150K |
| Bug bounty (Immunefi) | $100K+ pool |
| Mainnet deploy gas | ~$5-10K |
| Monitoring (Tenderly/Forta) | $500-2000/mes |
| Multisig setup | ~$500 gas |

---

## 🚀 Próximo Paso Inmediato

Empezar por **Fase 3.1** (health factor + borrow tracking en LendingPool). Es lo más crítico y desbloquea testnet real.

```bash
# Para empezar, regenerar dependencias:
forge install
cd frontend && npm install
```

---

## Referencias

- [ESTADO_ACTUAL.md](ESTADO_ACTUAL.md) - Estado detallado actual
- [plan.md](plan.md) - Plan original completo
- [audit/SECURITY_CHECKLIST.md](audit/SECURITY_CHECKLIST.md) - Checklist de seguridad
- [README.md](README.md) - Documentación del proyecto