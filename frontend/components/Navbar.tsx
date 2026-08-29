"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import Link from "next/link";
import { useAccount } from "wagmi";

export function Navbar() {
  const { isConnected } = useAccount();

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-gray-900/80 backdrop-blur-md border-b border-gray-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-500 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">CB</span>
              </div>
              <span className="text-xl font-bold text-white">CryptoBank</span>
            </Link>
            
            <div className="hidden md:flex items-center gap-6">
              <Link href="/dashboard" className="text-gray-300 hover:text-white transition-colors">
                Dashboard
              </Link>
              <Link href="/lending" className="text-gray-300 hover:text-white transition-colors">
                Lending
              </Link>
              <Link href="/swap" className="text-gray-300 hover:text-white transition-colors">
                Swap
              </Link>
              <Link href="/governance" className="text-gray-300 hover:text-white transition-colors">
                Governance
              </Link>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {isConnected && (
              <Link
                href="/dashboard"
                className="hidden md:flex items-center gap-2 px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors"
              >
                My Portfolio
              </Link>
            )}
            <ConnectButton />
          </div>
        </div>
      </div>
    </nav>
  );
}
