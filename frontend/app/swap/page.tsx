"use client";

import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useTokenBalance, TOKEN_LIST, formatTokenAmount } from "@/hooks/useTokenBalance";
import { useAllTokenPrices } from "@/hooks/usePriceFeed";
import { ToastProvider } from "@/components/Toast";

const tokens = [
  { symbol: "WETH", name: "Wrapped Ether", icon: "🔷" },
  { symbol: "USDC", name: "USD Coin", icon: "💵" },
  { symbol: "CB", name: "CryptoBank Token", icon: "💜" },
  { symbol: "LINK", name: "Chainlink", icon: "🔗" },
  { symbol: "WBTC", name: "Wrapped Bitcoin", icon: "₿" },
];

function SwapContent() {
  const { address, isConnected } = useAccount();
  const [fromTokenSymbol, setFromTokenSymbol] = useState<"WETH" | "USDC" | "CB" | "LINK" | "WBTC">("WETH");
  const [toTokenSymbol, setToTokenSymbol] = useState<"WETH" | "USDC" | "CB" | "LINK" | "WBTC">("USDC");
  const [fromAmount, setFromAmount] = useState("");
  const [toAmount, setToAmount] = useState("");

  const { prices, isLoading: pricesLoading } = useAllTokenPrices();
  
  const fromTokenInfo = TOKEN_LIST.find(t => t.symbol === fromTokenSymbol);
  const toTokenInfo = TOKEN_LIST.find(t => t.symbol === toTokenSymbol);
  
  const fromDecimals = fromTokenInfo?.decimals || 18;
  const toDecimals = toTokenInfo?.decimals || 18;
  
  const fromTokenAddress = fromTokenInfo?.address;
  const toTokenAddress = toTokenInfo?.address;

  const { balance: fromBalance, isLoading: fromLoading } = useTokenBalance(fromTokenAddress as `0x${string}`, address);
  const { balance: toBalance, isLoading: toLoading } = useTokenBalance(toTokenAddress as `0x${string}`, address);

  const fromPrice = prices[fromTokenSymbol]?.priceFormatted || "0";
  const toPrice = prices[toTokenSymbol]?.priceFormatted || "0";
  const fromPriceUsd = parseFloat(fromPrice);
  const toPriceUsd = parseFloat(toPrice);

  const exchangeRate = fromPriceUsd > 0 && toPriceUsd > 0 ? fromPriceUsd / toPriceUsd : 0;

  const handleFromAmountChange = (value: string) => {
    setFromAmount(value);
    if (value && parseFloat(value) > 0 && exchangeRate > 0) {
      setToAmount((parseFloat(value) * exchangeRate).toFixed(4));
    } else {
      setToAmount("");
    }
  };

  const handleSwapTokens = () => {
    const tempFrom = fromTokenSymbol;
    const tempTo = toTokenSymbol;
    setFromTokenSymbol(tempTo);
    setToTokenSymbol(tempFrom);
    setFromAmount(toAmount);
    setToAmount(fromAmount);
  };

  const maxFromAmount = fromBalance ? formatTokenAmount(fromBalance, fromDecimals) : "0";

  if (!isConnected) {
    return (
      <div className="pt-24 flex flex-col items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white mb-4">Connect Your Wallet</h1>
          <p className="text-gray-400 mb-8">Swap tokens with real-time prices</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  return (
    <div className="pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Token Swap</h1>
          <p className="text-gray-400">Trade tokens with real-time prices from Chainlink</p>
        </div>

        <div className="max-w-lg mx-auto">
          <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
            <div className="mb-2">
              <div className="flex justify-between text-sm mb-2">
                <span className="text-gray-400">From</span>
                <span className="text-gray-400">
                  Balance: {fromBalance ? parseFloat(maxFromAmount).toFixed(4) : "..."} {fromTokenSymbol}
                </span>
              </div>
              <div className="bg-gray-700 rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      const idx = tokens.findIndex(t => t.symbol === fromTokenSymbol);
                      setFromTokenSymbol(tokens[(idx + 1) % tokens.length].symbol as any);
                    }}
                    className="flex items-center gap-2 px-3 py-2 bg-gray-600 hover:bg-gray-500 rounded-lg"
                  >
                    <span className="text-xl">{tokens.find(t => t.symbol === fromTokenSymbol)?.icon}</span>
                    <span className="text-white">{fromTokenSymbol}</span>
                    <span className="text-gray-400">▼</span>
                  </button>
                  <input
                    type="number"
                    step={fromDecimals <= 6 ? "0.000001" : "0.000000000000000001"}
                    min="0"
                    max={maxFromAmount}
                    value={fromAmount}
                    onChange={(e) => handleFromAmountChange(e.target.value)}
                    placeholder="0.00"
                    className="flex-1 bg-transparent text-right text-2xl text-white placeholder-gray-400 focus:outline-none"
                  />
                </div>
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>≈ ${fromAmount && exchangeRate > 0 ? (parseFloat(fromAmount) * fromPriceUsd).toFixed(2) : "0.00"}</span>
                  <span>Price: ${fromPriceUsd.toLocaleString()}</span>
                </div>
              </div>
            </div>

            <div className="flex justify-center -my-2 relative z-10">
              <button
                onClick={handleSwapTokens}
                className="p-2 bg-gray-700 hover:bg-gray-600 rounded-xl border-4 border-gray-800 transition-colors"
              >
                <span className="text-white text-xl">↕</span>
              </button>
            </div>

            <div className="mt-2">
              <div className="flex justify-between text-sm mb-2">
                <span className="text-gray-400">To</span>
                <span className="text-gray-400">
                  Balance: {toBalance ? parseFloat(formatTokenAmount(toBalance, toDecimals)).toFixed(4) : "..."} {toTokenSymbol}
                </span>
              </div>
              <div className="bg-gray-700 rounded-xl p-4">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => {
                      const idx = tokens.findIndex(t => t.symbol === toTokenSymbol);
                      setToTokenSymbol(tokens[(idx + 1) % tokens.length].symbol as any);
                    }}
                    className="flex items-center gap-2 px-3 py-2 bg-gray-600 hover:bg-gray-500 rounded-lg"
                  >
                    <span className="text-xl">{tokens.find(t => t.symbol === toTokenSymbol)?.icon}</span>
                    <span className="text-white">{toTokenSymbol}</span>
                    <span className="text-gray-400">▼</span>
                  </button>
                  <input
                    type="number"
                    value={toAmount}
                    readOnly
                    placeholder="0.00"
                    className="flex-1 bg-transparent text-right text-2xl text-white placeholder-gray-400 focus:outline-none"
                  />
                </div>
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>≈ ${toAmount && toPriceUsd > 0 ? (parseFloat(toAmount) * toPriceUsd).toFixed(2) : "0.00"}</span>
                  <span>Price: ${toPriceUsd.toLocaleString()}</span>
                </div>
              </div>
            </div>

            {fromAmount && parseFloat(fromAmount) > 0 && exchangeRate > 0 && (
              <div className="mt-4 p-4 bg-gray-700/50 rounded-lg space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Exchange Rate</span>
                  <span className="text-white">
                    1 {fromTokenSymbol} = {exchangeRate.toFixed(4)} {toTokenSymbol}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Price Impact</span>
                  <span className="text-green-400"><0.1%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Minimum Received (0.5% slippage)</span>
                  <span className="text-white">
                    {(parseFloat(toAmount) * 0.995).toFixed(4)} {toTokenSymbol}
                  </span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Route</span>
                  <span className="text-white">
                    {fromTokenSymbol} → {toTokenSymbol} (via Uniswap V3 - coming soon)
                  </span>
                </div>
              </div>
            )}

            <button
              className="w-full mt-4 py-4 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-xl font-medium hover:from-purple-700 hover:to-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={!fromAmount || parseFloat(fromAmount) <= 0 || fromLoading || toLoading || pricesLoading}
            >
              {fromLoading || toLoading || pricesLoading ? "Loading..." : "Swap (DEX integration pending)"}
            </button>

            <p className="text-center text-sm text-gray-500 mt-3">
              Swap functionality will use Uniswap V3 when deployed. 
              <br />Currently showing real-time prices from Chainlink oracles.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Swap() {
  return (
    <ToastProvider>
      <SwapContent />
    </ToastProvider>
  );
}