"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function Swap() {
  const { isConnected } = useAccount();

  if (!isConnected) {
    return (
      <div className="pt-24 flex flex-col items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white mb-4">Connect Your Wallet</h1>
          <p className="text-gray-400 mb-8">Swap tokens</p>
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
          <p className="text-gray-400">Trade tokens</p>
        </div>
        <div className="bg-gray-800/50 rounded-2xl p-6 border border-gray-700">
          <p className="text-white">Swap page - minimal version</p>
        </div>
      </div>
    </div>
  );
}