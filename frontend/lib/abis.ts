export const ERC20_ABI = [
  { name: "balanceOf", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "allowance", type: "function", stateMutability: "view", inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "approve", type: "function", stateMutability: "nonpayable", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }] },
  { name: "name", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "symbol", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "decimals", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint8" }] },
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
] as const;

export const LENDING_POOL_ABI = [
  { name: "supply", type: "function", stateMutability: "nonpayable", inputs: [{ name: "asset", type: "address" }, { name: "amount", type: "uint256" }, { name: "onBehalfOf", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "withdraw", type: "function", stateMutability: "nonpayable", inputs: [{ name: "asset", type: "address" }, { name: "amount", type: "uint256" }, { name: "to", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "borrow", type: "function", stateMutability: "nonpayable", inputs: [{ name: "asset", type: "address" }, { name: "amount", type: "uint256" }, { name: "onBehalfOf", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "repay", type: "function", stateMutability: "nonpayable", inputs: [{ name: "asset", type: "address" }, { name: "amount", type: "uint256" }, { name: "onBehalfOf", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "getReserveData", type: "function", stateMutability: "view", inputs: [{ name: "asset", type: "address" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "isActive", type: "bool" }, { name: "isFrozen", type: "bool" }, { name: "isPaused", type: "bool" },
    { name: "liquidityIndex", type: "uint128" }, { name: "currentLiquidityRate", type: "uint128" },
    { name: "variableBorrowIndex", type: "uint128" }, { name: "currentVariableBorrowRate", type: "uint128" },
    { name: "lastUpdateTimestamp", type: "uint40" }, { name: "liquidityCap", type: "uint256" },
    { name: "borrowCap", type: "uint256" }, { name: "aTokenAddress", type: "address" },
    { name: "interestRateStrategyAddress", type: "address" }, { name: "reserveFactor", type: "uint256" }
  ] }] },
  { name: "getUserReserveData", type: "function", stateMutability: "view", inputs: [{ name: "asset", type: "address" }, { name: "user", type: "address" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "currentATokenBalance", type: "uint256" }, { name: "currentStableDebt", type: "uint256" },
    { name: "currentVariableDebt", type: "uint256" }, { name: "principalStableDebt", type: "uint256" },
    { name: "stableBorrowRate", type: "uint256" }, { name: "stableRateLastUpdated", type: "uint40" },
    { name: "usageAsCollateralEnabled", type: "bool" }
  ] }] },
  { name: "getReserves", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "address[]" }] },
  { name: "getHealthFactor", type: "function", stateMutability: "view", inputs: [{ name: "user", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "getUserAccountData", type: "function", stateMutability: "view", inputs: [{ name: "user", type: "address" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "totalCollateralBase", type: "uint256" }, { name: "totalDebtBase", type: "uint256" },
    { name: "availableBorrowsBase", type: "uint256" }, { name: "currentLiquidationThreshold", type: "uint256" },
    { name: "ltv", type: "uint256" }, { name: "healthFactor", type: "uint256" }
  ] }] },
] as const;

export const ATOKEN_ABI = [
  { name: "balanceOf", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
  { name: "scaledBalanceOf", type: "function", stateMutability: "view", inputs: [{ name: "user", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "scaledTotalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
  { name: "getUnderlyingBalance", type: "function", stateMutability: "view", inputs: [{ name: "user", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "UNDERLYING_ASSET_ADDRESS", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "address" }] },
] as const;

export const PRICE_FEED_ABI = [
  { name: "getAssetPrice", type: "function", stateMutability: "view", inputs: [{ name: "asset", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "getAssetsPrices", type: "function", stateMutability: "view", inputs: [{ name: "assets", type: "address[]" }], outputs: [{ name: "prices", type: "uint256[]" }] },
  { name: "getFeedData", type: "function", stateMutability: "view", inputs: [{ name: "asset", type: "address" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "feedAddress", type: "address" }, { name: "priceDecimals", type: "uint256" },
    { name: "isPaused", type: "bool" }, { name: "minPrice", type: "uint256" },
    { name: "maxPrice", type: "uint256" }, { name: "maxStalePeriod", type: "uint256" }
  ] }] },
  { name: "getFeedAssets", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "address[]" }] },
] as const;

export const GOVERNOR_ABI = [
  { name: "propose", type: "function", stateMutability: "nonpayable", inputs: [
    { name: "targets", type: "address[]" }, { name: "values", type: "uint256[]" },
    { name: "calldatas", type: "bytes[]" }, { name: "description", type: "string" }
  ], outputs: [{ name: "", type: "uint256" }] },
  { name: "vote", type: "function", stateMutability: "nonpayable", inputs: [
    { name: "proposalId", type: "uint256" }, { name: "support", type: "uint8" }
  ], outputs: [{ name: "", type: "uint256" }] },
  { name: "delegate", type: "function", stateMutability: "nonpayable", inputs: [{ name: "delegatee", type: "address" }], outputs: [] },
  { name: "getProposals", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256[]" }] },
  { name: "state", type: "function", stateMutability: "view", inputs: [{ name: "proposalId", type: "uint256" }], outputs: [{ name: "", type: "uint8" }] },
  { name: "proposals", type: "function", stateMutability: "view", inputs: [{ name: "proposalId", type: "uint256" }], outputs: [{
    name: "", type: "tuple", components: [
      { name: "id", type: "uint256" }, { name: "proposer", type: "address" },
      { name: "targets", type: "address[]" }, { name: "values", type: "uint256[]" },
      { name: "signatures", type: "bytes[]" }, { name: "calldatas", type: "bytes[]" },
      { name: "startBlock", type: "uint256" }, { name: "endBlock", type: "uint256" },
      { name: "description", type: "string" }, { name: "executed", type: "bool" }
    ]
  }] },
  { name: "getVotes", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "quorum", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
  { name: "votingDelay", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
  { name: "votingPeriod", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
] as const;

export const CB_TOKEN_ABI = [
  { name: "balanceOf", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
  { name: "delegate", type: "function", stateMutability: "nonpayable", inputs: [{ name: "delegatee", type: "address" }], outputs: [] },
  { name: "getVotes", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "name", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "symbol", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "decimals", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint8" }] },
] as const;