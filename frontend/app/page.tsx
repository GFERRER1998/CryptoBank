"use client";

import { useAccount, useBalance } from "wagmi";
import { formatEther, formatUnits } from "viem";
import Link from "next/link";
import { StatsCard } from "@/components/StatsCard";
import { RecentActivity } from "@/components/RecentActivity";
import { useTokenBalance, CB_TOKEN_ADDRESS, formatTokenAmount } from "@/hooks/useTokenBalance";
import { useUserAccountData } from "@/hooks/useLendingPool";
import { useAllTokenPrices } from "@/hooks/usePriceFeed";
import { SEPOLIA_TOKENS, ATOKEN_ADDRESSES } from "@/lib/contracts";

export default function Home() {
  const { address, isConnected } = useAccount();
  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });
  const { data: accountData } = useUserAccountData();
  const { prices } = useAllTokenPrices();

  const tokenAddresses = Object.values(SEPOLIA_TOKENS);
  const aTokenAddresses = Object.values(ATOKEN_ADDRESSES);

  const tokenBalances = tokenAddresses.map(addr => 
    useTokenBalance(addr as `0x${string}`, address)
  );

  const aTokenBalances = aTokenAddresses.map(addr => 
    useTokenBalance(addr as `0x${string}`, address)
  );

  const cbTokenBalance = useTokenBalance(CB_TOKEN_ADDRESS, address);

  let totalTvl = 0;
  let totalDeposits = 0;
  let totalBorrows = 0;

  if (accountData) {
    totalDeposits = parseFloat(formatUnits(accountData.totalCollateralBase, 18));
    totalBorrows = parseFloat(formatUnits(accountData.totalDebtBase, 18));
    totalTvl = totalDeposits;
  }

  return (
    <div className="pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-6xl font-bold text-white mb-6">
            The Future of{" "}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-blue-500">
              Decentralized Banking
            </span>
          </h1>
          <p className="text-xl text-gray-400 max-w-2xl mx-auto mb-8">
            Earn interest, borrow assets, trade tokens, and govern the protocol - 
            all on Ethereum with full decentralization.
          </p>
          
          {!isConnected ? (
            <div className="flex justify-center gap-4">
              <Link href="/lending" className="px-8 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg font-medium hover:from-purple-700 hover:to-blue-700 transition-all">
                Connect Wallet to Start
              </Link>
            </div>
          ) : (
            <div className="bg-gray-800/50 rounded-2xl p-6 max-w-md mx-auto border border-gray-700">
              <p className="text-gray-400 text-sm mb-2">Your Sepolia ETH Balance</p>
              <p className="text-3xl font-bold text-white">
                {ethBalance ? `${Number(formatEther(ethBalance.value)).toFixed(4)} ETH` : '...'}
              </p>
              <p className="text-gray-400 text-sm mt-2">
                CB Tokens: {cbTokenBalance.balance ? parseFloat(formatTokenAmount(cbTokenBalance.balance, 18)).toFixed(0) : "..."} CB
              </p>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          <StatsCard
            title="Total Value Locked"
            value={isConnected && accountData ? `$${totalTvl.toLocaleString(undefined, { minimumFractionDigits: 0 })}` : "$12.5M"}
            change="+5.2%"
            icon="🔒"
          />
          <StatsCard
            title="Your Deposits"
            value={isConnected && accountData ? `$${totalDeposits.toLocaleString(undefined, { minimumFractionDigits: 0 })}` : "$8.2M"}
            change="+3.1%"
            icon="💰"
          />
          <StatsCard
            title="Your Borrows"
            value={isConnected && accountData ? `$${totalBorrows.toLocaleString(undefined, { minimumFractionDigits: 0 })}` : "$4.3M"}
            change="+7.8%"
            icon="📊"
          />
          <StatsCard
            title="CB Balance"
            value={isConnected && cbTokenBalance.balance ? `${parseFloat(formatTokenAmount(cbTokenBalance.balance, 18)).toLocaleString()} CB` : "1,234 CB"}
            change="+12.5%"
            icon="👥"
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
          <Link href="/lending" className="group">
            <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700 hover:border-purple-500 transition-all group-hover:bg-gray-800">
              <div className="text-4xl mb-4">🏦</div>
              <h3 className="text-xl font-semibold text-white mb-2">Lending & Borrowing</h3>
              <p className="text-gray-400">
                Supply assets to earn interest or borrow against your collateral with competitive rates.
              </p>
            </div>
          </Link>

          <Link href="/swap" className="group">
            <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700 hover:border-purple-500 transition-all group-hover:bg-gray-800">
              <div className="text-4xl mb-4">🔄</div>
              <h3 className="text-xl font-semibold text-white mb-2">Token Swap</h3>
              <p className="text-gray-400">
                Trade tokens with real-time Chainlink prices. DEX integration coming soon.
              </p>
            </div>
          </Link>

          <Link href="/governance" className="group">
            <div className="bg-gray-800/50 rounded-2xl p-8 border border-gray-700 hover:border-purple-500 transition-all group-hover:bg-gray-800">
              <div className="text-4xl mb-4">🗳️</div>
              <h3 className="text-xl font-semibold text-white mb-2">DAO Governance</h3>
              <p className="text-gray-400">
                Participate in protocol decisions and shape the future of CryptoBank.
              </p>
            </div>
          </Link>
        </div>

        <RecentActivity />
      </div>
    </div>
  );
}