// Contract addresses - Deployed on Sepolia (2026-08-28)
export const CB_TOKEN_ADDRESS = "0xdAdf416Bf5972477390f493e19b818Ad1aB716e9" as const;
export const LENDING_POOL_ADDRESS = "0x2C1BAe355B41926a310B649B962faE85Fb8E57D1" as const;
export const GOVERNOR_ADDRESS = "0x60292093044b8884829455aF06Aca8E6912e3BC9" as const;
export const TIMELOCK_ADDRESS = "0x1217f72DFBE3499F9ccF047F3C07cABb978F49A8" as const;
export const PRICE_FEED_ADDRESS = "0xDf612D3422a748f00Fee370f60Cd3C54A161AA63" as const;
export const INTEREST_RATE_STRATEGY_ADDRESS = "0x7A0Af01164c6e06c74a9CeD88A378814Ec9B2144" as const;

// Sepolia token addresses
export const SEPOLIA_TOKENS = {
  WETH: "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9" as const,
  USDC: "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238" as const,
  WBTC: "0x29f2D40B0605204364af54EC677bD022dA425d03" as const,
  LINK: "0x779877A7B0D9E8603169DdbD7836e478b4624789" as const,
} as const;

// AToken addresses (created during reserve initialization)
export const ATOKEN_ADDRESSES = {
  WETH: "0x5aE60199a9b65CD7E76CFb2EF2F1e5FD3A144B63" as const,
  USDC: "0x5D15249052dd3807E67cE09fe09898c49161eBEF" as const,
  WBTC: "0xd471dBF2aFA70A23174546c90329570E8513d6E0" as const,
  LINK: "0xE916B749cb9e07eB2542bC148fa08519011C0fD6" as const,
} as const;

// Chainlink price feeds on Sepolia (8 decimals)
export const SEPOLIA_FEEDS = {
  ETH_USD: "0x694AA1769357215DE4FAC081bf1f309aDC325306" as const,
  BTC_USD: "0x1B44f3514812D8357c87870A117E0b0747BE81Fb" as const,
  LINK_USD: "0x425fEc615c2d0d5202e621CFfFE005a5b0B18e43" as const,
} as const;

// ABIs (simplified - full ABIs in artifacts/)
export const CB_TOKEN_ABI = [
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "totalSupply",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "delegate",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "delegatee", type: "address" }],
    outputs: [],
  },
] as const;

export const LENDING_POOL_ABI = [
  {
    name: "supply",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "asset", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "onBehalfOf", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "withdraw",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "asset", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "to", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "borrow",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "asset", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "onBehalfOf", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "repay",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "asset", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "onBehalfOf", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "getReserveData",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "asset", type: "address" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "isActive", type: "bool" },
          { name: "isFrozen", type: "bool" },
          { name: "isPaused", type: "bool" },
          { name: "liquidityIndex", type: "uint128" },
          { name: "currentLiquidityRate", type: "uint128" },
          { name: "variableBorrowIndex", type: "uint128" },
          { name: "currentVariableBorrowRate", type: "uint128" },
          { name: "lastUpdateTimestamp", type: "uint40" },
          { name: "liquidityCap", type: "uint256" },
          { name: "borrowCap", type: "uint256" },
          { name: "aTokenAddress", type: "address" },
          { name: "interestRateStrategyAddress", type: "address" },
          { name: "reserveFactor", type: "uint256" },
        ],
      },
    ],
  },
  {
    name: "getUserReserveData",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "asset", type: "address" },
      { name: "user", type: "address" },
    ],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "currentATokenBalance", type: "uint256" },
          { name: "currentStableDebt", type: "uint256" },
          { name: "currentVariableDebt", type: "uint256" },
          { name: "principalStableDebt", type: "uint256" },
          { name: "stableBorrowRate", type: "uint256" },
          { name: "stableRateLastUpdated", type: "uint40" },
          { name: "usageAsCollateralEnabled", type: "bool" },
        ],
      },
    ],
  },
  {
    name: "getReserves",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }],
  },
] as const;

export const ATOKEN_ABI = [
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "totalSupply",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "scaledBalanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "scaledTotalSupply",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "getUnderlyingBalance",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "user", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "UNDERLYING_ASSET_ADDRESS",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
  },
] as const;

export const INTEREST_RATE_STRATEGY_ABI = [
  {
    name: "calculateInterestRates",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "totalDeposits", type: "uint256" },
      { name: "totalBorrowed", type: "uint256" },
      { name: "reserveFactor", type: "uint256" },
      { name: "excessLiquidity", type: "uint256" },
    ],
    outputs: [
      { name: "liquidityRate", type: "uint256" },
      { name: "variableBorrowRate", type: "uint256" },
    ],
  },
  {
    name: "optimalUtilization",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "baseVariableBorrowRate",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "variableRateSlope1",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "variableRateSlope2",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
] as const;

export const PRICE_FEED_ABI = [
  {
    name: "getAssetPrice",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "asset", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    name: "getAssetsPrices",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "assets", type: "address[]" }],
    outputs: [{ name: "prices", type: "uint256[]" }],
  },
  {
    name: "getFeedData",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "asset", type: "address" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "feedAddress", type: "address" },
          { name: "priceDecimals", type: "uint256" },
          { name: "isPaused", type: "bool" },
          { name: "minPrice", type: "uint256" },
          { name: "maxPrice", type: "uint256" },
          { name: "maxStalePeriod", type: "uint256" },
        ],
      },
    ],
  },
  {
    name: "getFeedAssets",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }],
  },
] as const;