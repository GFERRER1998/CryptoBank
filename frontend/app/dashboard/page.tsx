"use client";

import { useAccount, useBalance, useChainId } from "wagmi";
import { formatEther, formatUnits } from "viem";
import { StatsCard } from "@/components/StatsCard";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useUserAccountData, useHealthFactor } from "@/hooks/useLendingPool";
import { useTokenBalance, TOKEN_LIST, formatTokenAmount } from "@/hooks/useTokenBalance";
import { useAllTokenPrices } from "@/hooks/usePriceFeed";
import { CB_TOKEN_ADDRESS } from "@/lib/contracts";
import Link from "next/link";

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const currentChainId = useChainId();
  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });
  const { data: accountData, isLoading: accountLoading, refetch: refetchAccount } = useUserAccountData();
  const { healthFactor, formattedHealthFactor, isLoading: hfLoading } = useHealthFactor();

  const { prices, isLoading: pricesLoading } = useAllTokenPrices();

  const tokenAddresses = TOKEN_LIST.filter(t => !t.isAToken).map(t => t.address);
  const aTokenAddresses = TOKEN_LIST.filter(t => t.isAToken).map(t => t.address);

  const tokenBalances = tokenAddresses.map(addr => 
    useTokenBalance(addr as `0x${string}`, address)
  );

  const aTokenBalances = aTokenAddresses.map(addr => 
    useTokenBalance(addr as `0x${string}`, address)
  );

  const cbTokenBalance = useTokenBalance(CB_TOKEN_ADDRESS, address);

  const isLoading = accountLoading || hfLoading || tokenBalances.some(b => b.isLoading) || aTokenBalances.some(b => b.isLoading);

  let totalSuppliedUsd = 0;
  let totalBorrowedUsd = 0;
  let totalCollateralUsd = 0;

  if (!isLoading && accountData) {
    tokenBalances.forEach((balance, index) => {
      const token = TOKEN_LIST.find(t => t.address === tokenAddresses[index]);
      const price = token ? prices[token.symbol]?.priceFormatted : "0";
      if (token && balance.balance) {
        const amount = parseFloat(formatTokenAmount(balance.balance, token.decimals));
        const priceUsd = parseFloat(price);
        if (token.isAToken) {
          totalSuppliedUsd += amount * priceUsd;
        } else {
          totalCollateralUsd += amount * priceUsd;
        }
      }
    });

    if (accountData.totalDebtBase > 0) {
      totalBorrowedUsd = parseFloat(formatUnits(accountData.totalDebtBase, 18));
    }
  }

  const netWorth = totalSuppliedUsd + totalCollateralUsd - totalBorrowedUsd;

  if (!isConnected) {
    return (
      <div className="pt-24 flex flex-col items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white mb-4">Connect Your Wallet</h1>
          <p className="text-gray-400 mb-8">View your portfolio and manage your assets</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  const supplies = TOKEN_LIST
    .filter(t => t.isAToken)
    .map((token, index) => {
      const balance = aTokenBalances[index];
      const underlyingToken = TOKEN_LIST.find(t => t.symbol === token.symbol.replace('a', ''));
      const price = underlyingToken ? prices[underlyingToken.symbol]?.priceFormatted : "0";
      const amount = balance.balance ? parseFloat(formatTokenAmount(balance.balance, token.decimals)) : 0;
      const usdValue = amount * parseFloat(price);
      return {
        ...token,
        balance,
        amount,
        price: parseFloat(price),
        usdValue,
      };
    })
    .filter(s => s.amount > 0);

  return (
    <div className="pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">Dashboard</h1>
            <p className="text-gray-400">Overview of your portfolio on Sepolia</p>
          </div>
          <div className="flex items-center gap-4">
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${
              currentChainId === 11155111 ? "bg-green-600 text-white" : "bg-yellow-600 text-white"
            }`}>
              {currentChainId === 11155111 ? "Sepolia" : `Chain ${currentChainId}`}
            </span>
            <button
              onClick={() => { refetchAccount(); tokenBalances.forEach(b => b.refetchBalance()); aTokenBalances.forEach(b => b.refetchBalance()); }}
              disabled={isLoading}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors disabled:opacity-50"
            >
              {isLoading ? "Refreshing..." : "Refresh"}
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatsCard
            title="Net Worth"
            value={isLoading ? "..." : `$${netWorth.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
            change={netWorth >= 0 ? "+" : ""}
            icon="💎"
          />
          <StatsCard
            title="Total Supplied"
            value={isLoading ? "..." : `$${totalSuppliedUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
            change="+0%"
            icon="💰"
          />
          <StatsCard
            title="Total Borrowed"
            value={isLoading ? "..." : `$${totalBorrowedUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
            change={totalBorrowedUsd > 0 ? "-" : ""}
            icon="📊"
          />
          <StatsCard
            title="Health Factor"
            value={hfLoading ? "..." : formattedHealthFactor === "N/A" ? "∞" : formattedHealthFactor}
            change={parseFloat(formattedHealthFactor) > 1.5 ? "Safe" : "⚠️ Risk"}
            icon="🛡️"
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Supply Positions</h3>
                <Link href="/lending" className="text-sm text-purple-400 hover:text-purple-300">Manage →</Link>
              </div>
              {supplies.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-400 mb-4">No active supplies</p>
                  <Link href="/lending" className="px-6 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors inline-block">
                    Supply Assets
                  </Link>
                </div>
              ) : (
                <div className="space-y-4">
                  {supplies.map((supply) => (
                    <div key={supply.symbol} className="flex items-center justify-between p-4 bg-gray-700/50 rounded-lg">
                      <div className="flex items-center gap-4">
                        <span className="text-2xl">{supply.icon}</span>
                        <div>
                          <p className="text-white font-medium">{supply.symbol}</p>
                          <p className="text-gray-400 text-sm">{supply.name}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-white font-bold">{supply.amount.toFixed(4)} {supply.symbol}</p>
                        <p className="text-gray-400 text-sm">${supply.usdValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
                      </div>
                    </div>
                  ))}
                  <div className="pt-4 border-t border-gray-700 flex justify-between">
                    <span className="text-gray-400">Total Supplied</span>
                    <span className="text-white font-bold">${totalSuppliedUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                  </div>
                </div>
              )}
            </div>

            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-white">Borrow Positions</h3>
                <Link href="/lending" className="text-sm text-yellow-400 hover:text-yellow-300">Manage →</Link>
              </div>
              <div className="bg-gray-700/50 rounded-lg p-4">
                {accountData && accountData.totalDebtBase > 0n ? (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 bg-gray-800/50 rounded-lg">
                      <div>
                        <p className="text-white font-medium">Total Debt</p>
                        <p className="text-gray-400 text-sm">{formatUnits(accountData.totalDebtBase, 18)} (base)</p>
                      </div>
                      <div className="text-right">
                        <p className="text-white font-bold">${totalBorrowedUsd.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
                      </div>
                    </div>
                    <div className="grid grid-cols-3 gap-4 text-sm">
                      <div className="text-center p-3 bg-gray-800/50 rounded-lg">
                        <p className="text-gray-400">Available to Borrow</p>
                        <p className="text-white font-bold">
                          ${parseFloat(formatUnits(accountData.availableBorrowsBase, 18)).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                        </p>
                      </div>
                      <div className="text-center p-3 bg-gray-800/50 rounded-lg">
                        <p className="text-gray-400">LTV</p>
                        <p className="text-white font-bold">
                          {accountData.totalCollateralBase > 0n 
                            ? (Number(formatUnits(accountData.totalDebtBase, 18)) / Number(formatUnits(accountData.totalCollateralBase, 18)) * 100).toFixed(1) + "%"
                            : "0%"}
                        </p>
                      </div>
                      <div className="text-center p-3 bg-gray-800/50 rounded-lg">
                        <p className="text-gray-400">Liquidation Threshold</p>
                        <p className="text-white font-bold">
                          {Number(formatUnits(accountData.currentLiquidationThreshold, 18)).toFixed(1)}%
                        </p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-8">
                    <p className="text-gray-400 mb-4">No active borrows</p>
                    <Link href="/lending" className="px-6 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg transition-colors inline-block">
                      Borrow Assets
                    </Link>
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
              <h3 className="text-lg font-semibold text-white mb-4">Wallet Balances</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">🔷</span>
                    <div>
                      <p className="text-white font-medium">ETH</p>
                      <p className="text-gray-400 text-sm">Native Token</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-white font-bold">{ethBalance ? parseFloat(formatEther(ethBalance.value)).toFixed(4) : "0"} ETH</p>
                    <p className="text-gray-400 text-sm">${ethBalance ? (parseFloat(formatEther(ethBalance.value)) * (prices.WETH?.priceFormatted ? parseFloat(prices.WETH.priceFormatted) : 0)).toFixed(2) : "0"}</p>
                  </div>
                </div>

                <div className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">💜</span>
                    <div>
                      <p className="text-white font-medium">CB Token</p>
                      <p className="text-gray-400 text-sm">Governance Token</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-white font-bold">{cbTokenBalance.balance ? parseFloat(formatTokenAmount(cbTokenBalance.balance, 18)).toFixed(2) : "0"} CB</p>
                    <p className="text-gray-400 text-sm">${cbTokenBalance.balance ? (parseFloat(formatTokenAmount(cbTokenBalance.balance, 18)) * (prices.CB?.priceFormatted ? parseFloat(prices.CB.priceFormatted) : 0)).toFixed(2) : "0"}</p>
                  </div>
                </div>

                {TOKEN_LIST.filter(t => !t.isAToken && t.symbol !== "CB").map((token, index) => {
                  const balance = tokenBalances[TOKEN_LIST.findIndex(t => t.address === token.address)];
                  const price = prices[token.symbol]?.priceFormatted || "0";
                  const amount = balance.balance ? parseFloat(formatTokenAmount(balance.balance, token.decimals)) : 0;
                  return amount > 0 ? (
                    <div key={token.symbol} className="flex items-center justify-between p-3 bg-gray-700/50 rounded-lg">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">{token.icon}</span>
                        <div>
                          <p className="text-white font-medium">{token.symbol}</p>
                          <p className="text-gray-400 text-sm">{token.name}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-white font-bold">{amount.toFixed(4)} {token.symbol}</p>
                        <p className="text-gray-400 text-sm">${(amount * parseFloat(price)).toFixed(2)}</p>
                      </div>
                    </div>
                  ) : null;
                })}
              </div>
            </div>

            <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
              <h3 className="text-lg font-semibold text-white mb-4">Quick Actions</h3>
              <div className="space-y-3">
                <Link href="/lending" className="block w-full text-center py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors">
                  Supply / Borrow Assets
                </Link>
                <Link href="/swap" className="block w-full text-center py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors">
                  Swap Tokens
                </Link>
                <Link href="/governance" className="block w-full text-center py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors">
                  Vote on Proposals
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}