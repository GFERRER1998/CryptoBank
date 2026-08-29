"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { mainnet, sepolia } from "wagmi/chains";
import { http } from "wagmi";

const ALCHEMY_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY;
const WALLET_CONNECT_ID = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "demo";

const SEPOLIA_RPC = ALCHEMY_KEY
  ? `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_KEY}`
  : "https://rpc.sepolia.org";

const MAINNET_RPC = ALCHEMY_KEY
  ? `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`
  : "https://eth.llamarpc.com";

export const config = getDefaultConfig({
  appName: "CryptoBank",
  projectId: WALLET_CONNECT_ID,
  chains: [mainnet, sepolia],
  transports: {
    [mainnet.id]: http(MAINNET_RPC),
    [sepolia.id]: http(SEPOLIA_RPC),
  },
});
