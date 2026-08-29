"use client";

import { useAccount, useChainId, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseUnits, formatUnits } from "viem";
import { SEPOLIA_TOKENS, ATOKEN_ADDRESSES, CB_TOKEN_ADDRESS, LENDING_POOL_ADDRESS } from "@/lib/contracts";
import { ERC20_ABI } from "@/lib/abis";

export type TokenSymbol = keyof typeof SEPOLIA_TOKENS;

export interface TokenInfo {
  address: `0x${string}`;
  symbol: string;
  name: string;
  decimals: number;
  isAToken: boolean;
}

export const TOKEN_LIST: TokenInfo[] = [
  { address: SEPOLIA_TOKENS.WETH, symbol: "WETH", name: "Wrapped Ether", decimals: 18, isAToken: false },
  { address: SEPOLIA_TOKENS.USDC, symbol: "USDC", name: "USD Coin", decimals: 6, isAToken: false },
  { address: SEPOLIA_TOKENS.WBTC, symbol: "WBTC", name: "Wrapped Bitcoin", decimals: 8, isAToken: false },
  { address: SEPOLIA_TOKENS.LINK, symbol: "LINK", name: "Chainlink", decimals: 18, isAToken: false },
  { address: ATOKEN_ADDRESSES.WETH, symbol: "aWETH", name: "Aave Interest Bearing WETH", decimals: 18, isAToken: true },
  { address: ATOKEN_ADDRESSES.USDC, symbol: "aUSDC", name: "Aave Interest Bearing USDC", decimals: 6, isAToken: true },
  { address: ATOKEN_ADDRESSES.WBTC, symbol: "aWBTC", name: "Aave Interest Bearing WBTC", decimals: 8, isAToken: true },
  { address: ATOKEN_ADDRESSES.LINK, symbol: "aLINK", name: "Aave Interest Bearing LINK", decimals: 18, isAToken: true },
  { address: CB_TOKEN_ADDRESS, symbol: "CB", name: "CryptoBank Token", decimals: 18, isAToken: false },
];

const ERC20_ABI_FULL = [
  { name: "balanceOf", type: "function", stateMutability: "view", inputs: [{ name: "account", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "allowance", type: "function", stateMutability: "view", inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
  { name: "approve", type: "function", stateMutability: "nonpayable", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }] },
  { name: "name", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "symbol", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "string" }] },
  { name: "decimals", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint8" }] },
  { name: "totalSupply", type: "function", stateMutability: "view", inputs: [], outputs: [{ name: "", type: "uint256" }] },
] as const;

export function useTokenBalance(tokenAddress: `0x${string}` | undefined, account?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetAccount = account || connectedAccount;

  const { data: balance, refetch: refetchBalance, isLoading: isBalanceLoading } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI_FULL,
    functionName: "balanceOf",
    args: targetAccount ? [targetAccount] : undefined,
    query: { enabled: !!tokenAddress && !!targetAccount },
  });

  return {
    balance: balance as bigint | undefined,
    formattedBalance: balance ? formatUnits(balance, 18) : "0",
    refetchBalance,
    isLoading: isBalanceLoading,
  };
}

export function useTokenAllowance(tokenAddress: `0x${string}` | undefined, spender: `0x${string}`, account?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetAccount = account || connectedAccount;

  const { data: allowance, refetch: refetchAllowance, isLoading: isAllowanceLoading } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI_FULL,
    functionName: "allowance",
    args: targetAccount && spender ? [targetAccount, spender] : undefined,
    query: { enabled: !!tokenAddress && !!targetAccount && !!spender },
  });

  return {
    allowance: allowance as bigint | undefined,
    formattedAllowance: allowance ? formatUnits(allowance, 18) : "0",
    refetchAllowance,
    isLoading: isAllowanceLoading,
  };
}

export function useApprove(tokenAddress: `0x${string}` | undefined, spender: `0x${string}`, amount: bigint) {
  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const approve = async () => {
    if (!tokenAddress) throw new Error("Token address required");
    const txHash = await writeContractAsync({
      address: tokenAddress,
      abi: ERC20_ABI_FULL,
      functionName: "approve",
      args: [spender, amount],
    });
    return txHash;
  };

  return {
    approve,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useTokenInfo(tokenAddress: `0x${string}` | undefined) {
  const { data: name } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI_FULL,
    functionName: "name",
    query: { enabled: !!tokenAddress },
  });
  const { data: symbol } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI_FULL,
    functionName: "symbol",
    query: { enabled: !!tokenAddress },
  });
  const { data: decimals } = useReadContract({
    address: tokenAddress,
    abi: ERC20_ABI_FULL,
    functionName: "decimals",
    query: { enabled: !!tokenAddress },
  });

  return {
    name: name as string | undefined,
    symbol: symbol as string | undefined,
    decimals: decimals as number | undefined,
  };
}

export function useTokenBySymbol(symbol: TokenSymbol) {
  const tokenInfo = TOKEN_LIST.find(t => t.symbol === symbol);
  return tokenInfo;
}

export function parseTokenAmount(amount: string, decimals: number): bigint {
  if (!amount || amount === "") return 0n;
  try {
    return parseUnits(amount, decimals);
  } catch {
    return 0n;
  }
}

export function formatTokenAmount(amount: bigint, decimals: number): string {
  try {
    return formatUnits(amount, decimals);
  } catch {
    return "0";
  }
}

export function getTokenDecimals(symbol: TokenSymbol): number {
  const token = TOKEN_LIST.find(t => t.symbol === symbol);
  return token?.decimals || 18;
}

export { CB_TOKEN_ADDRESS, SEPOLIA_TOKENS, ATOKEN_ADDRESSES } from "@/lib/contracts";