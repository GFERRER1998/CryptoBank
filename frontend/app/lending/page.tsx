"use client";

import { useState, useEffect, useCallback } from "react";
import { useAccount, useChainId, useBalance } from "wagmi";
import { parseUnits, formatUnits, formatEther } from "viem";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { ToastProvider } from "@/components/Toast";
import {
  useReserveData,
  useUserReserveData,
  useUserAccountData,
  useHealthFactor,
  useSupply,
  useWithdraw,
  useBorrow,
  useRepay,
  useAllMarketsData,
  MarketData,
} from "@/hooks/useLendingPool";
import {
  useTokenBalance,
  useTokenAllowance,
  useApprove,
  useTokenBySymbol,
  parseTokenAmount,
  formatTokenAmount,
  getTokenDecimals,
  TOKEN_LIST,
  TokenSymbol,
} from "@/hooks/useTokenBalance";
import { useAllTokenPrices } from "@/hooks/usePriceFeed";
import { SEPOLIA_TOKENS, ATOKEN_ADDRESSES } from "@/lib/contracts";

const SUPPORTED_TOKENS: { symbol: TokenSymbol; name: string; icon: string }[] = [
  { symbol: "WETH", name: "Wrapped Ether", icon: "🔷" },
  { symbol: "USDC", name: "USD Coin", icon: "💵" },
  { symbol: "WBTC", name: "Wrapped Bitcoin", icon: "₿" },
  { symbol: "LINK", name: "Chainlink", icon: "🔗" },
];

function LendingContent() {
  const { address, isConnected, chainId } = useAccount();
  const [activeTab, setActiveTab] = useState<"supply" | "borrow" | "withdraw" | "repay">("supply");
  const [selectedSymbol, setSelectedSymbol] = useState<TokenSymbol>("WETH");
  const [amount, setAmount] = useState("");
  const [showMaxModal, setShowMaxModal] = useState(false);

  const selectedToken = SUPPORTED_TOKENS.find(t => t.symbol === selectedSymbol);
  const tokenInfo = useTokenBySymbol(selectedSymbol);
  const decimals = tokenInfo?.decimals || 18;
  const assetAddress = tokenInfo?.address as `0x${string}`;
  const aTokenAddress = tokenInfo?.isAToken ? assetAddress : ATOKEN_ADDRESSES[selectedSymbol as keyof typeof ATOKEN_ADDRESSES];
  const lendingPoolAddress = "0x2C1BAe355B41926a310B649B962faE85Fb8E57D1" as const;

  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });

  const { data: reserveData, isLoading: reserveLoading, refetch: refetchReserve } = useReserveData(assetAddress);
  const { data: userReserveData, isLoading: userReserveLoading, refetch: refetchUserReserve } = useUserReserveData(assetAddress);
  const { data: accountData, isLoading: accountLoading, refetch: refetchAccount } = useUserAccountData();
  const { healthFactor, formattedHealthFactor, isLoading: hfLoading } = useHealthFactor();
  const { prices, isLoading: pricesLoading } = useAllTokenPrices();

  const { balance: userTokenBalance, refetch: refetchTokenBalance } = useTokenBalance(assetAddress, address);
  const { balance: userATokenBalance, refetch: refetchATokenBalance } = useTokenBalance(aTokenAddress, address);
  const { allowance, refetch: refetchAllowance } = useTokenAllowance(assetAddress, lendingPoolAddress, address);

  const { supply, isPending: isSupplying, isSuccess: supplySuccess, error: supplyError, hash: supplyHash } = useSupply(assetAddress, parseTokenAmount(amount, decimals));
  const { withdraw, isPending: isWithdrawing, isSuccess: withdrawSuccess, error: withdrawError } = useWithdraw(assetAddress, parseTokenAmount(amount, decimals));
  const { borrow, isPending: isBorrowing, isSuccess: borrowSuccess, error: borrowError } = useBorrow(assetAddress, parseTokenAmount(amount, decimals));
  const { repay, isPending: isRepaying, isSuccess: repaySuccess, error: repayError } = useRepay(assetAddress, parseTokenAmount(amount, decimals));

  const { approve, isPending: isApproving, isSuccess: approveSuccess, error: approveError, hash: approveHash } = useApprove(
    assetAddress,
    lendingPoolAddress,
    parseTokenAmount(amount, decimals)
  );

  const isAnyPending = isSupplying || isWithdrawing || isBorrowing || isRepaying || isApproving;

  const supplyAPY = reserveData ? Number(formatUnits(reserveData.currentLiquidityRate, 27)) * 100 : 0;
  const borrowAPY = reserveData ? Number(formatUnits(reserveData.currentVariableBorrowRate, 27)) * 100 : 0;

  const totalLiquidity = reserveData ? formatTokenAmount(reserveData.liquidityCap, decimals) : "0";
  const totalBorrows = userReserveData ? formatTokenAmount(userReserveData.currentVariableDebt, decimals) : "0";

  const userSupplyBalance = userATokenBalance ? formatTokenAmount(userATokenBalance, decimals) : "0";
  const userBorrowBalance = userReserveData ? formatTokenAmount(userReserveData.currentVariableDebt, decimals) : "0";

  const tokenPrice = prices[selectedSymbol]?.priceFormatted || "0";
  const tokenPriceUsd = parseFloat(tokenPrice);

  const canSupply = parseFloat(amount) > 0 && userTokenBalance && parseFloat(userTokenBalance) >= parseFloat(amount);
  const canWithdraw = parseFloat(amount) > 0 && userATokenBalance && parseFloat(userATokenBalance) >= parseFloat(amount);
  const canBorrow = parseFloat(amount) > 0 && accountData && parseFloat(formatUnits(accountData.availableBorrowsBase, 18)) >= parseFloat(amount) * tokenPriceUsd;
  const canRepay = parseFloat(amount) > 0 && userTokenBalance && parseFloat(userTokenBalance) >= parseFloat(amount);

  const needsApprove = allowance && parseUnits(amount, decimals) > allowance;

  const handleAction = async () => {
    if (!address) return;

    try {
      if (needsApprove && !approveSuccess) {
        await approve();
        return;
      }

      switch (activeTab) {
        case "supply":
          if (canSupply) await supply();
          break;
        case "withdraw":
          if (canWithdraw) await withdraw();
          break;
        case "borrow":
          if (canBorrow) await borrow();
          break;
        case "repay":
          if (canRepay) await repay();
          break;
      }

      setAmount("");
      setTimeout(() => {
        refetchReserve();
        refetchUserReserve();
        refetchAccount();
        refetchTokenBalance();
        refetchATokenBalance();
        refetchAllowance();
      }, 2000);
    } catch (err) {
      console.error("Transaction failed:", err);
    }
  };

  const handleMaxClick = () => {
    let maxAmount = "0";
    switch (activeTab) {
      case "supply":
        maxAmount = userTokenBalance || "0";
        break;
      case "withdraw":
        maxAmount = userATokenBalance || "0";
        break;
      case "borrow":
        if (accountData) {
          const available = parseFloat(formatUnits(accountData.availableBorrowsBase, 18));
          maxAmount = (available / tokenPriceUsd).toFixed(4);
        }
        break;
      case "repay":
        maxAmount = userTokenBalance || userBorrowBalance || "0";
        break;
    }
    setAmount(maxAmount);
  };

  const actionLabel = {
    supply: "Supply",
    withdraw: "Withdraw",
    borrow: "Borrow",
    repay: "Repay",
  }[activeTab];

  const apyLabel = activeTab === "supply" || activeTab === "withdraw" ? "Supply APY" : "Borrow APY";
  const currentAPY = activeTab === "supply" || activeTab === "withdraw" ? supplyAPY : borrowAPY;

  if (!isConnected) {
    return (
      <div className="pt-24 flex flex-col items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white mb-4">Connect Your Wallet</h1>
          <p className="text-gray-400 mb-8">Supply or borrow assets on Sepolia</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  return (
    <div className="pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-3xl font-bold text-white mb-2">Lending & Borrowing</h1>
              <p className="text-gray-400">Earn interest or borrow against your collateral</p>
            </div>
            <div className="flex items-center gap-6 text-sm">
              <div className="text-right">
                <p className="text-gray-400">Health Factor</p>
                <p className="text-white font-bold text-lg">
                  {hfLoading ? "..." : formattedHealthFactor === "N/A" ? "∞" : formattedHealthFactor}
                </p>
              </div>
              <div className="text-right">
                <p className="text-gray-400">Sepolia ETH</p>
                <p className="text-white font-bold">{ethBalance ? formatEther(ethBalance.value).slice(0, 6) : "0"} ETH</p>
              </div>
            </div>
          </div>

          {supplyError && <div className="mb-4 p-3 bg-red-900/30 border border-red-500 rounded-lg text-red-300">Supply Error: {supplyError.message}</div>}
          {borrowError && <div className="mb-4 p-3 bg-red-900/30 border border-red-500 rounded-lg text-red-300">Borrow Error: {borrowError.message}</div>}
          {withdrawError && <div className="mb-4 p-3 bg-red-900/30 border border-red-500 rounded-lg text-red-300">Withdraw Error: {withdrawError.message}</div>}
          {repayError && <div className="mb-4 p-3 bg-red-900/30 border border-red-500 rounded-lg text-red-300">Repay Error: {repayError.message}</div>}
          {approveError && <div className="mb-4 p-3 bg-yellow-900/30 border border-yellow-500 rounded-lg text-yellow-300">Approval needed: {approveError.message}</div>}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1">
            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700 space-y-6">
              <div>
                <label className="block text-gray-400 text-sm mb-2">Action</label>
                <div className="grid grid-cols-4 gap-2">
                  {(["supply", "withdraw", "borrow", "repay"] as const).map((tab) => (
                    <button
                      key={tab}
                      onClick={() => { setActiveTab(tab); setAmount(""); }}
                      className={`py-2 rounded-lg font-medium text-sm transition-colors ${
                        activeTab === tab
                          ? (tab === "supply" ? "bg-green-600" : tab === "withdraw" ? "bg-blue-600" : tab === "borrow" ? "bg-yellow-600" : "bg-red-600") + " text-white"
                          : "bg-gray-700 text-gray-300 hover:bg-gray-600"
                      }`}
                    >
                      {tab.charAt(0).toUpperCase() + tab.slice(1)}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-gray-400 text-sm mb-2">Asset</label>
                <div className="grid grid-cols-4 gap-2">
                  {SUPPORTED_TOKENS.map((asset) => (
                    <button
                      key={asset.symbol}
                      onClick={() => { setSelectedSymbol(asset.symbol); setAmount(""); }}
                      className={`p-3 rounded-lg border transition-colors ${
                        selectedSymbol === asset.symbol
                          ? "border-purple-500 bg-purple-500/20"
                          : "border-gray-700 bg-gray-700/50 hover:border-gray-600"
                      }`}
                    >
                      <span className="text-xl">{asset.icon}</span>
                      <p className="text-white text-sm mt-1">{asset.symbol}</p>
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-gray-400 text-sm mb-2">
                  Amount {selectedToken && `(${selectedToken.symbol})`}
                </label>
                <div className="relative">
                  <input
                    type="number"
                    step="0.000001"
                    min="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    disabled={isAnyPending}
                    className="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-purple-500 disabled:opacity-50"
                  />
                  <button
                    onClick={handleMaxClick}
                    disabled={isAnyPending}
                    className="absolute right-3 top-1/2 -translate-y-1/2 px-3 py-1 bg-gray-600 hover:bg-gray-500 rounded-md text-white text-sm disabled:opacity-50"
                  >
                    MAX
                  </button>
                </div>
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>Balance: {userTokenBalance ? parseFloat(userTokenBalance).toFixed(4) : "0"} {selectedToken?.symbol}</span>
                  <span>aToken: {userSupplyBalance ? parseFloat(userSupplyBalance).toFixed(4) : "0"} a{selectedToken?.symbol}</span>
                </div>
              </div>

              <div className="p-4 bg-gray-700/50 rounded-lg space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">{apyLabel}</span>
                  <span className="text-white font-medium">{currentAPY.toFixed(2)}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Price</span>
                  <span className="text-white font-medium">${tokenPriceUsd.toLocaleString()}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Your Supply</span>
                  <span className="text-white font-medium">{userSupplyBalance ? parseFloat(userSupplyBalance).toFixed(4) : "0"} a{selectedToken?.symbol}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">Your Borrow</span>
                  <span className="text-white font-medium">{userBorrowBalance ? parseFloat(userBorrowBalance).toFixed(4) : "0"} {selectedToken?.symbol}</span>
                </div>
                {activeTab === "borrow" && accountData && (
                  <div className="flex justify-between text-sm border-t border-gray-600 pt-2">
                    <span className="text-gray-400">Available to Borrow</span>
                    <span className="text-white font-medium">
                      ${parseFloat(formatUnits(accountData.availableBorrowsBase, 18)).toFixed(2)}
                    </span>
                  </div>
                )}
              </div>

              {needsApprove && !approveSuccess && (
                <button
                  onClick={handleAction}
                  disabled={isAnyPending}
                  className="w-full py-3 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                >
                  {isApproving ? "Approving..." : "Approve Token"}
                </button>
              )}

              {!needsApprove && (
                <button
                  onClick={handleAction}
                  disabled={isAnyPending || !amount || parseFloat(amount) <= 0 || 
                    (activeTab === "supply" && !canSupply) ||
                    (activeTab === "withdraw" && !canWithdraw) ||
                    (activeTab === "borrow" && !canBorrow) ||
                    (activeTab === "repay" && !canRepay)
                  }
                  className="w-full py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg font-medium hover:from-purple-700 hover:to-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isAnyPending ? `${actionLabel}ing...` : `${actionLabel} ${selectedToken?.symbol}`}
                </button>
              )}

              {(isSupplying || isWithdrawing || isBorrowing || isRepaying) && (
                <div className="text-center text-sm text-gray-400">
                  Transaction submitted... waiting for confirmation
                </div>
              )}

              {(supplySuccess || withdrawSuccess || borrowSuccess || repaySuccess) && (
                <div className="text-center text-sm text-green-400">
                  Transaction confirmed! Refreshing data...
                </div>
              )}
            </div>
          </div>

          <div className="lg:col-span-2">
            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
              <h3 className="text-lg font-semibold text-white mb-4">Market Overview</h3>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="text-gray-400 text-sm border-b border-gray-700">
                      <th className="text-left py-3">Asset</th>
                      <th className="text-right py-3">Supply APY</th>
                      <th className="text-right py-3">Borrow APY</th>
                      <th className="text-right py-3">Your Supply</th>
                      <th className="text-right py-3">Your Borrow</th>
                      <th className="text-right py-3">Liquidity</th>
                      <th className="text-right py-3">Utilization</th>
                      <th className="text-right py-3">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {SUPPORTED_TOKENS.map((asset) => {
                      const token = useTokenBySymbol(asset.symbol);
                      const tokenAddr = token?.address;
                      const aTokenAddr = token?.isAToken ? tokenAddr : ATOKEN_ADDRESSES[asset.symbol as keyof typeof ATOKEN_ADDRESSES];
                      const { data: rd } = useReserveData(tokenAddr as `0x${string}`);
                      const { data: urd } = useUserReserveData(tokenAddr as `0x${string}`);
                      const { balance: ub } = useTokenBalance(tokenAddr as `0x${string}`, address);
                      const { balance: uab } = useTokenBalance(aTokenAddr as `0x${string}`, address);
                      const price = prices[asset.symbol]?.priceFormatted || "0";

                      const sAPY = rd ? Number(formatUnits(rd.currentLiquidityRate, 27)) * 100 : 0;
                      const bAPY = rd ? Number(formatUnits(rd.currentVariableBorrowRate, 27)) * 100 : 0;
                      const utilization = rd && rd.liquidityCap > 0n
                        ? (Number(formatUnits(rd.liquidityCap - (rd.liquidityCap - rd.currentLiquidityRate), 18)) / Number(formatUnits(rd.liquidityCap, 18))) * 100
                        : 0;

                      return (
                        <tr key={asset.symbol} className="border-b border-gray-700 last:border-0 hover:bg-gray-700/50 transition-colors">
                          <td className="py-4">
                            <div className="flex items-center gap-3">
                              <span className="text-2xl">{asset.icon}</span>
                              <div>
                                <p className="text-white font-medium">{asset.symbol}</p>
                                <p className="text-gray-400 text-sm">{asset.name}</p>
                              </div>
                            </div>
                          </td>
                          <td className="text-right py-4 text-green-400">{sAPY.toFixed(2)}%</td>
                          <td className="text-right py-4 text-yellow-400">{bAPY.toFixed(2)}%</td>
                          <td className="text-right py-4 text-white">
                            {uab ? parseFloat(uab).toFixed(4) : "0"} a{asset.symbol}
                          </td>
                          <td className="text-right py-4 text-white">
                            {urd ? parseFloat(formatTokenAmount(urd.currentVariableDebt, decimals)).toFixed(4) : "0"} {asset.symbol}
                          </td>
                          <td className="text-right py-4 text-white">
                            ${price !== "0" && rd
                              ? (Number(formatUnits(rd.liquidityCap, decimals)) * parseFloat(price)).toLocaleString(undefined, { maximumFractionDigits: 0 })
                              : "—"}
                          </td>
                          <td className="text-right py-4 text-white">{utilization.toFixed(1)}%</td>
                          <td className="text-right py-4">
                            <button
                              onClick={() => { setSelectedSymbol(asset.symbol); setActiveTab("supply"); }}
                              className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm transition-colors"
                            >
                              Select
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Lending() {
  return (
    <ToastProvider>
      <LendingContent />
    </ToastProvider>
  );
}