"use client";

import { useAccount, useChainId, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { LENDING_POOL_ADDRESS, ATOKEN_ADDRESSES, SEPOLIA_TOKENS } from "@/lib/contracts";
import { LENDING_POOL_ABI, ATOKEN_ABI } from "@/lib/abis";

export interface ReserveData {
  isActive: boolean;
  isFrozen: boolean;
  isPaused: boolean;
  liquidityIndex: bigint;
  currentLiquidityRate: bigint;
  variableBorrowIndex: bigint;
  currentVariableBorrowRate: bigint;
  lastUpdateTimestamp: bigint;
  liquidityCap: bigint;
  borrowCap: bigint;
  aTokenAddress: `0x${string}`;
  interestRateStrategyAddress: `0x${string}`;
  reserveFactor: bigint;
}

export interface UserReserveData {
  currentATokenBalance: bigint;
  currentStableDebt: bigint;
  currentVariableDebt: bigint;
  principalStableDebt: bigint;
  stableBorrowRate: bigint;
  stableRateLastUpdated: bigint;
  usageAsCollateralEnabled: boolean;
}

export interface UserAccountData {
  totalCollateralBase: bigint;
  totalDebtBase: bigint;
  availableBorrowsBase: bigint;
  currentLiquidationThreshold: bigint;
  ltv: bigint;
  healthFactor: bigint;
}

export interface MarketData {
  symbol: string;
  assetAddress: `0x${string}`;
  aTokenAddress: `0x${string}`;
  supplyAPY: number;
  variableBorrowAPY: number;
  totalLiquidity: bigint;
  totalBorrows: bigint;
  liquidityCap: bigint;
  borrowCap: bigint;
  utilizationRate: number;
  reserveFactor: number;
  isActive: boolean;
  isFrozen: boolean;
}

export function useReserveData(assetAddress: `0x${string}` | undefined) {
  const { data, refetch, isLoading, error } = useReadContract({
    address: LENDING_POOL_ADDRESS,
    abi: LENDING_POOL_ABI,
    functionName: "getReserveData",
    args: assetAddress ? [assetAddress] : undefined,
    query: { enabled: !!assetAddress, refetchInterval: 10000 },
  });

  return {
    data: data as ReserveData | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useUserReserveData(assetAddress: `0x${string}` | undefined, userAddress?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetUser = userAddress || connectedAccount;

  const { data, refetch, isLoading, error } = useReadContract({
    address: LENDING_POOL_ADDRESS,
    abi: LENDING_POOL_ABI,
    functionName: "getUserReserveData",
    args: assetAddress && targetUser ? [assetAddress, targetUser] : undefined,
    query: { enabled: !!assetAddress && !!targetUser, refetchInterval: 10000 },
  });

  return {
    data: data as UserReserveData | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useUserAccountData(userAddress?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetUser = userAddress || connectedAccount;

  const { data, refetch, isLoading, error } = useReadContract({
    address: LENDING_POOL_ADDRESS,
    abi: LENDING_POOL_ABI,
    functionName: "getUserAccountData",
    args: targetUser ? [targetUser] : undefined,
    query: { enabled: !!targetUser, refetchInterval: 10000 },
  });

  return {
    data: data as UserAccountData | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useHealthFactor(userAddress?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetUser = userAddress || connectedAccount;

  const { data, refetch, isLoading, error } = useReadContract({
    address: LENDING_POOL_ADDRESS,
    abi: LENDING_POOL_ABI,
    functionName: "getHealthFactor",
    args: targetUser ? [targetUser] : undefined,
    query: { enabled: !!targetUser, refetchInterval: 10000 },
  });

  return {
    healthFactor: data as bigint | undefined,
    formattedHealthFactor: data ? Number(formatUnits(data, 18)).toFixed(2) : "N/A",
    refetch,
    isLoading,
    error,
  };
}

export function useReservesList() {
  const { data, refetch, isLoading, error } = useReadContract({
    address: LENDING_POOL_ADDRESS,
    abi: LENDING_POOL_ABI,
    functionName: "getReserves",
    query: { refetchInterval: 30000 },
  });

  return {
    reserves: (data as `0x${string}`[] | undefined) || [],
    refetch,
    isLoading,
    error,
  };
}

export function useSupply(assetAddress: `0x${string}` | undefined, amount: bigint, onBehalfOf?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetOnBehalfOf = onBehalfOf || connectedAccount;

  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const supply = async () => {
    if (!assetAddress || !targetOnBehalfOf) throw new Error("Missing parameters");
    return await writeContractAsync({
      address: LENDING_POOL_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: "supply",
      args: [assetAddress, amount, targetOnBehalfOf],
    });
  };

  return {
    supply,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useWithdraw(assetAddress: `0x${string}` | undefined, amount: bigint, to?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetTo = to || connectedAccount;

  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const withdraw = async () => {
    if (!assetAddress || !targetTo) throw new Error("Missing parameters");
    return await writeContractAsync({
      address: LENDING_POOL_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: "withdraw",
      args: [assetAddress, amount, targetTo],
    });
  };

  return {
    withdraw,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useBorrow(assetAddress: `0x${string}` | undefined, amount: bigint, onBehalfOf?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetOnBehalfOf = onBehalfOf || connectedAccount;

  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const borrow = async () => {
    if (!assetAddress || !targetOnBehalfOf) throw new Error("Missing parameters");
    return await writeContractAsync({
      address: LENDING_POOL_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: "borrow",
      args: [assetAddress, amount, targetOnBehalfOf],
    });
  };

  return {
    borrow,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useRepay(assetAddress: `0x${string}` | undefined, amount: bigint, onBehalfOf?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetOnBehalfOf = onBehalfOf || connectedAccount;

  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const repay = async () => {
    if (!assetAddress || !targetOnBehalfOf) throw new Error("Missing parameters");
    return await writeContractAsync({
      address: LENDING_POOL_ADDRESS,
      abi: LENDING_POOL_ABI,
      functionName: "repay",
      args: [assetAddress, amount, targetOnBehalfOf],
    });
  };

  return {
    repay,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useATokenBalance(aTokenAddress: `0x${string}` | undefined, userAddress?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetUser = userAddress || connectedAccount;

  const { data: balance, refetch, isLoading } = useReadContract({
    address: aTokenAddress,
    abi: ATOKEN_ABI,
    functionName: "balanceOf",
    args: targetUser ? [targetUser] : undefined,
    query: { enabled: !!aTokenAddress && !!targetUser, refetchInterval: 10000 },
  });

  const { data: scaledBalance } = useReadContract({
    address: aTokenAddress,
    abi: ATOKEN_ABI,
    functionName: "scaledBalanceOf",
    args: targetUser ? [targetUser] : undefined,
    query: { enabled: !!aTokenAddress && !!targetUser, refetchInterval: 10000 },
  });

  const { data: underlyingBalance } = useReadContract({
    address: aTokenAddress,
    abi: ATOKEN_ABI,
    functionName: "getUnderlyingBalance",
    args: targetUser ? [targetUser] : undefined,
    query: { enabled: !!aTokenAddress && !!targetUser, refetchInterval: 10000 },
  });

  return {
    balance: balance as bigint | undefined,
    scaledBalance: scaledBalance as bigint | undefined,
    underlyingBalance: underlyingBalance as bigint | undefined,
    refetch,
    isLoading,
  };
}

export function useAllMarketsData() {
  const { reserves, isLoading: isReservesLoading, refetch: refetchReserves } = useReservesList();
  
  const tokenSymbols: Record<string, string> = {
    [SEPOLIA_TOKENS.WETH.toLowerCase()]: "WETH",
    [SEPOLIA_TOKENS.USDC.toLowerCase()]: "USDC",
    [SEPOLIA_TOKENS.WBTC.toLowerCase()]: "WBTC",
    [SEPOLIA_TOKENS.LINK.toLowerCase()]: "LINK",
  };

  const decimalsMap: Record<string, number> = {
    [SEPOLIA_TOKENS.WETH.toLowerCase()]: 18,
    [SEPOLIA_TOKENS.USDC.toLowerCase()]: 6,
    [SEPOLIA_TOKENS.WBTC.toLowerCase()]: 8,
    [SEPOLIA_TOKENS.LINK.toLowerCase()]: 18,
  };

  return {
    reserves,
    isLoading: isReservesLoading,
    refetch: refetchReserves,
    tokenSymbols,
    decimalsMap,
  };
}