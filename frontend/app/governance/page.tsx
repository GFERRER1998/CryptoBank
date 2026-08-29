"use client";

import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { formatUnits } from "viem";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAllProposals, useProposalState, useVotes, useQuorum, useVotingDelay, useVotingPeriod, useVote, useDelegate, PROPOSAL_STATES } from "@/hooks/useGovernance";
import { useTokenBalance, CB_TOKEN_ADDRESS, formatTokenAmount } from "@/hooks/useTokenBalance";
import { ToastProvider, useToast } from "@/components/Toast";

function GovernanceContent() {
  const { address, isConnected } = useAccount();
  const { addToast } = useToast();
  const [activeTab, setActiveTab] = useState<"proposals" | "create">("proposals");
  const [selectedProposalId, setSelectedProposalId] = useState<bigint | null>(null);
  const [voteSupport, setVoteSupport] = useState<0 | 1 | 2>(1);
  const [createTitle, setCreateTitle] = useState("");
  const [createDescription, setCreateDescription] = useState("");

  const { proposals, isLoading: proposalsLoading, refetch: refetchProposals } = useAllProposals();
  const { votes: votingPower, formattedVotes, isLoading: votesLoading } = useVotes(address);
  const { quorum, formattedQuorum } = useQuorum();
  const { votingDelay } = useVotingDelay();
  const { votingPeriod } = useVotingPeriod();
  const { balance: cbBalance } = useTokenBalance(CB_TOKEN_ADDRESS, address);

  const { vote, isPending: isVoting, isSuccess: voteSuccess, error: voteError } = useVote(selectedProposalId!, voteSupport);
  const { delegate, isPending: isDelegating, isSuccess: delegateSuccess } = useDelegate(address!);

  const canCreateProposal = cbBalance && cbBalance >= 10000n * 10n ** 18n;

  const activeProposals = proposals.filter(p => p.state === "Active" || p.state === "Pending").length;

  const getStateColor = (state: string | undefined) => {
    switch (state) {
      case "Active": return "bg-green-500/20 text-green-400";
      case "Succeeded": return "bg-blue-500/20 text-blue-400";
      case "Defeated": return "bg-red-500/20 text-red-400";
      case "Executed": return "bg-purple-500/20 text-purple-400";
      case "Queued": return "bg-yellow-500/20 text-yellow-400";
      case "Canceled": return "bg-gray-500/20 text-gray-400";
      default: return "bg-gray-500/20 text-gray-400";
    }
  };

  const formatProposalId = (id: bigint) => `#${id.toString().slice(0, 8)}...`;

  const calculateProgress = (forVotes: bigint, againstVotes: bigint, abstainVotes: bigint) => {
    const total = forVotes + againstVotes + abstainVotes;
    if (total === 0n) return 0;
    return Number((forVotes * 100n) / total);
  };

  if (!isConnected) {
    return (
      <div className="pt-24 flex flex-col items-center justify-center min-h-screen">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-white mb-4">Connect Your Wallet</h1>
          <p className="text-gray-400 mb-8">Participate in DAO governance</p>
          <ConnectButton />
        </div>
      </div>
    );
  }

  return (
    <div className="pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">DAO Governance</h1>
          <p className="text-gray-400">Participate in protocol decisions with your CB tokens</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Your CB Balance</p>
            <p className="text-xl font-bold text-white">
              {cbBalance ? parseFloat(formatTokenAmount(cbBalance, 18)).toLocaleString(undefined, { maximumFractionDigits: 0 }) : "..."} CB
            </p>
          </div>
          <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Voting Power</p>
            <p className="text-xl font-bold text-white">{votesLoading ? "..." : formattedVotes} CB</p>
          </div>
          <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Active Proposals</p>
            <p className="text-xl font-bold text-white">{proposalsLoading ? "..." : activeProposals}</p>
          </div>
          <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
            <p className="text-gray-400 text-sm">Quorum Required</p>
            <p className="text-xl font-bold text-white">{formattedQuorum}%</p>
          </div>
        </div>

        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setActiveTab("proposals")}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              activeTab === "proposals"
                ? "bg-purple-600 text-white"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
          >
            Proposals
          </button>
          <button
            onClick={() => setActiveTab("create")}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              activeTab === "create"
                ? "bg-purple-600 text-white"
                : "bg-gray-700 text-gray-300 hover:bg-gray-600"
            }`}
          >
            Create Proposal
          </button>
        </div>

        {activeTab === "proposals" ? (
          <div className="space-y-4">
            {proposalsLoading ? (
              <div className="text-center py-8">
                <p className="text-gray-400">Loading proposals...</p>
              </div>
            ) : proposals.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-gray-400 mb-4">No proposals found</p>
                <button onClick={() => setActiveTab("create")} className="px-6 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors">
                  Create First Proposal
                </button>
              </div>
            ) : (
              proposals.map((proposal) => (
                <div
                  key={proposal.id?.toString()}
                  className="bg-gray-800/50 rounded-xl p-6 border border-gray-700"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-lg font-semibold text-white">
                          {proposal.description || "Untitled Proposal"}
                        </h3>
                        <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStateColor(proposal.state)}`}>
                          {proposal.state}
                        </span>
                      </div>
                      <p className="text-gray-400 text-sm">
                        Proposed by {proposal.proposer?.slice(0, 6)}...{proposal.proposer?.slice(-4)} • ID: {formatProposalId(proposal.id!)}
                      </p>
                    </div>
                  </div>

                  <div className="mb-4">
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-green-400">For: {proposal.forVotes ? formatUnits(proposal.forVotes, 18) : "0"}</span>
                      <span className="text-red-400">Against: {proposal.againstVotes ? formatUnits(proposal.againstVotes, 18) : "0"}</span>
                      <span className="text-yellow-400">Abstain: {proposal.abstainVotes ? formatUnits(proposal.abstainVotes, 18) : "0"}</span>
                    </div>
                    <div className="h-2 bg-gray-700 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-green-500 to-green-400 transition-all duration-500"
                        style={{ width: `${calculateProgress(proposal.forVotes || 0n, proposal.againstVotes || 0n, proposal.abstainVotes || 0n)}%` }}
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-gray-400 text-sm">
                      {proposal.startBlock && proposal.endBlock 
                        ? `Blocks ${proposal.startBlock} - ${proposal.endBlock}` 
                        : "Not started"}
                    </span>
                    {(proposal.state === "Active" || proposal.state === "Pending") && (
                      <div className="flex gap-2">
                        <button
                          onClick={() => { setSelectedProposalId(proposal.id!); setVoteSupport(1); }}
                          disabled={isVoting}
                          className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
                        >
                          {isVoting ? "Voting..." : "Vote For"}
                        </button>
                        <button
                          onClick={() => { setSelectedProposalId(proposal.id!); setVoteSupport(0); }}
                          disabled={isVoting}
                          className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
                        >
                          {isVoting ? "Voting..." : "Vote Against"}
                        </button>
                        <button
                          onClick={() => { setSelectedProposalId(proposal.id!); setVoteSupport(2); }}
                          disabled={isVoting}
                          className="px-4 py-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50"
                        >
                          Abstain
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        ) : (
          <div className="bg-gray-800/50 rounded-xl p-6 border border-gray-700 max-w-2xl">
            <h3 className="text-lg font-semibold text-white mb-4">Create New Proposal</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-gray-400 text-sm mb-2">Title</label>
                <input
                  type="text"
                  value={createTitle}
                  onChange={(e) => setCreateTitle(e.target.value)}
                  placeholder="Proposal title"
                  className="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-purple-500"
                />
              </div>
              <div>
                <label className="block text-gray-400 text-sm mb-2">Description</label>
                <textarea
                  rows={4}
                  value={createDescription}
                  onChange={(e) => setCreateDescription(e.target.value)}
                  placeholder="Describe your proposal in detail..."
                  className="w-full bg-gray-700 border border-gray-600 rounded-lg px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-purple-500"
                />
              </div>
              <div className="p-4 bg-gray-700/50 rounded-lg">
                <p className="text-gray-400 text-sm">
                  Creating a proposal requires <span className="text-yellow-400 font-bold">10,000 CB tokens</span>.
                  {canCreateProposal ? "You have enough tokens." : "You need more CB tokens."}
                  Your voting power will be used to create the proposal.
                </p>
              </div>
              <button
                onClick={async () => {
                  if (!createTitle || !createDescription) {
                    addToast("Please fill in title and description", "error");
                    return;
                  }
                  if (!canCreateProposal) {
                    addToast("Insufficient CB tokens (need 10,000 CB)", "error");
                    return;
                  }
                  // In a real implementation, you'd call the propose function
                  // This is a placeholder for the actual proposal creation
                  addToast("Proposal creation not yet implemented - requires target contract calls", "info");
                }}
                disabled={!canCreateProposal || !createTitle || !createDescription}
                className="w-full py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-lg font-medium hover:from-purple-700 hover:to-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Create Proposal
              </button>
            </div>
          </div>
        )}

        <div className="mt-12">
          <h3 className="text-lg font-semibold text-white mb-4">Governance Parameters</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
              <p className="text-gray-400 text-sm">Voting Delay</p>
              <p className="text-xl font-bold text-white">{votingDelay?.toString() || "..."} blocks</p>
            </div>
            <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
              <p className="text-gray-400 text-sm">Voting Period</p>
              <p className="text-xl font-bold text-white">{votingPeriod?.toString() || "..."} blocks</p>
            </div>
            <div className="bg-gray-800/50 rounded-xl p-4 border border-gray-700">
              <p className="text-gray-400 text-sm">Proposal Threshold</p>
              <p className="text-xl font-bold text-white">10,000 CB</p>
            </div>
          </div>
        </div>

        {(voteSuccess || delegateSuccess) && (
          <div className="fixed bottom-4 right-4 z-50 bg-green-900/90 border border-green-500 px-4 py-3 rounded-lg shadow-lg text-white">
            Transaction confirmed!
          </div>
        )}
        {voteError && (
          <div className="fixed bottom-4 right-4 z-50 bg-red-900/90 border border-red-500 px-4 py-3 rounded-lg shadow-lg text-white">
            Vote failed: {voteError.message}
          </div>
        )}
      </div>
    </div>
  );
}

export default function Governance() {
  return (
    <ToastProvider>
      <GovernanceContent />
    </ToastProvider>
  );
}