"use client";

import { useReadContract } from "wagmi";
import { formatUnits } from "viem";
import { PRICE_FEED_ADDRESS, SEPOLIA_TOKENS, SEPOLIA_FEEDS } from "@/lib/contracts";
import { PRICE_FEED_ABI } from "@/lib/abis";

export interface FeedData {
  feedAddress: `0x${string}`;
  priceDecimals: bigint;
  isPaused: boolean;
  minPrice: bigint;
  maxPrice: bigint;
  maxStalePeriod: bigint;
}

export interface AssetPrice {
  asset: `0x${string}`;
  symbol: string;
  price: bigint;
  priceFormatted: string;
  priceDecimals: number;
  isPaused: boolean;
  lastUpdate: number | null;
}

const TOKEN_FEED_MAP: Record<string, `0x${string}`> = {
  [SEPOLIA_TOKENS.WETH.toLowerCase()]: SEPOLIA_FEEDS.ETH_USD,
  [SEPOLIA_TOKENS.WBTC.toLowerCase()]: SEPOLIA_FEEDS.BTC_USD,
  [SEPOLIA_TOKENS.LINK.toLowerCase()]: SEPOLIA_FEEDS.LINK_USD,
};

const TOKEN_DECIMALS: Record<string, number> = {
  [SEPOLIA_TOKENS.WETH.toLowerCase()]: 18,
  [SEPOLIA_TOKENS.USDC.toLowerCase()]: 6,
  [SEPOLIA_TOKENS.WBTC.toLowerCase()]: 8,
  [SEPOLIA_TOKENS.LINK.toLowerCase()]: 18,
};

export function useAssetPrice(assetAddress: `0x${string}` | undefined) {
  const { data: price, refetch, isLoading, error } = useReadContract({
    address: PRICE_FEED_ADDRESS,
    abi: PRICE_FEED_ABI,
    functionName: "getAssetPrice",
    args: assetAddress ? [assetAddress] : undefined,
    query: { enabled: !!assetAddress, refetchInterval: 30000 },
  });

  const feedAddress = assetAddress ? TOKEN_FEED_MAP[assetAddress.toLowerCase()] : undefined;
  
  const { data: feedData } = useReadContract({
    address: PRICE_FEED_ADDRESS,
    abi: PRICE_FEED_ABI,
    functionName: "getFeedData",
    args: feedAddress ? [feedAddress] : undefined,
    query: { enabled: !!feedAddress, refetchInterval: 60000 },
  });

  const decimals = assetAddress ? TOKEN_DECIMALS[assetAddress.toLowerCase()] || 8 : 8;
  const priceDecimals = feedData ? Number((feedData as any).priceDecimals) : 8;

  return {
    price: price as bigint | undefined,
    formattedPrice: price ? formatUnits(price, priceDecimals) : "0",
    priceDecimals,
    isPaused: (feedData as any)?.isPaused || false,
    feedData: feedData as FeedData | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useAssetsPrices(assetAddresses: `0x${string}`[]) {
  const { data: prices, refetch, isLoading, error } = useReadContract({
    address: PRICE_FEED_ADDRESS,
    abi: PRICE_FEED_ABI,
    functionName: "getAssetsPrices",
    args: assetAddresses.length > 0 ? [assetAddresses] : undefined,
    query: { enabled: assetAddresses.length > 0, refetchInterval: 30000 },
  });

  return {
    prices: (prices as bigint[] | undefined) || [],
    refetch,
    isLoading,
    error,
  };
}

export function useFeedData(assetAddress: `0x${string}` | undefined) {
  const feedAddress = assetAddress ? TOKEN_FEED_MAP[assetAddress.toLowerCase()] : undefined;
  
  const { data, refetch, isLoading, error } = useReadContract({
    address: PRICE_FEED_ADDRESS,
    abi: PRICE_FEED_ABI,
    functionName: "getFeedData",
    args: feedAddress ? [feedAddress] : undefined,
    query: { enabled: !!feedAddress, refetchInterval: 60000 },
  });

  return {
    feedData: data as FeedData | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useFeedAssets() {
  const { data, refetch, isLoading, error } = useReadContract({
    address: PRICE_FEED_ADDRESS,
    abi: PRICE_FEED_ABI,
    functionName: "getFeedAssets",
    query: { refetchInterval: 60000 },
  });

  return {
    assets: (data as `0x${string}`[] | undefined) || [],
    refetch,
    isLoading,
    error,
  };
}

export function useAllTokenPrices() {
  const tokenAddresses = Object.values(SEPOLIA_TOKENS) as `0x${string}`[];
  const { prices, isLoading, refetch, error } = useAssetsPrices(tokenAddresses);

  const formattedPrices: Record<string, AssetPrice> = {};
  
  tokenAddresses.forEach((asset, index) => {
    const symbol = Object.entries(SEPOLIA_TOKENS).find(([_, addr]) => addr.toLowerCase() === asset.toLowerCase())?.[0] || "Unknown";
    const price = prices[index];
    const decimals = TOKEN_DECIMALS[asset.toLowerCase()] || 8;
    
    formattedPrices[symbol] = {
      asset,
      symbol,
      price: price || 0n,
      priceFormatted: price ? formatUnits(price, decimals) : "0",
      priceDecimals: decimals,
      isPaused: false,
      lastUpdate: Date.now(),
    };
  });

  return {
    prices: formattedPrices,
    isLoading,
    refetch,
    error,
  };
}

export function calculateUsdValue(tokenAmount: bigint, tokenDecimals: number, priceUsd: bigint, priceDecimals: number): string {
  if (tokenAmount === 0n || priceUsd === 0n) return "0";
  try {
    const tokenAmountFormatted = Number(formatUnits(tokenAmount, tokenDecimals));
    const priceFormatted = Number(formatUnits(priceUsd, priceDecimals));
    const usdValue = tokenAmountFormatted * priceFormatted;
    return usdValue.toFixed(2);
  } catch {
    return "0";
  }
}

export function formatPrice(price: bigint, decimals: number): string {
  try {
    const formatted = Number(formatUnits(price, decimals));
    if (formatted >= 1) return formatted.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    if (formatted >= 0.01) return formatted.toFixed(4);
    return formatted.toFixed(8);
  } catch {
    return "0";
  }
}