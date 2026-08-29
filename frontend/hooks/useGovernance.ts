"use client";

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { formatUnits } from "viem";
import { GOVERNOR_ADDRESS, CB_TOKEN_ADDRESS, TIMELOCK_ADDRESS } from "@/lib/contracts";
import { GOVERNOR_ABI, CB_TOKEN_ABI } from "@/lib/abis";

export type ProposalState = 
  | "Pending" 
  | "Active" 
  | "Canceled" 
  | "Defeated" 
  | "Succeeded" 
  | "Queued" 
  | "Expired" 
  | "Executed";

export const PROPOSAL_STATES: ProposalState[] = [
  "Pending", "Active", "Canceled", "Defeated", "Succeeded", "Queued", "Expired", "Executed"
];

export interface Proposal {
  id: bigint;
  proposer: `0x${string}`;
  targets: `0x${string}`[];
  values: bigint[];
  signatures: string[];
  calldatas: `0x${string}`[];
  startBlock: bigint;
  endBlock: bigint;
  description: string;
  executed: boolean;
  state: ProposalState;
  forVotes: bigint;
  againstVotes: bigint;
  abstainVotes: bigint;
}

export function usePropose(
  targets: `0x${string}`[],
  values: bigint[],
  calldatas: `0x${string}`[],
  description: string
) {
  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const propose = async () => {
    return await writeContractAsync({
      address: GOVERNOR_ADDRESS,
      abi: GOVERNOR_ABI,
      functionName: "propose",
      args: [targets, values, calldatas, description],
    });
  };

  return {
    propose,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useVote(proposalId: bigint, support: 0 | 1 | 2) {
  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const vote = async () => {
    return await writeContractAsync({
      address: GOVERNOR_ADDRESS,
      abi: GOVERNOR_ABI,
      functionName: "vote",
      args: [proposalId, support],
    });
  };

  return {
    vote,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useDelegate(delegatee: `0x${string}`) {
  const { writeContractAsync, data: hash, isPending, error, reset } = useWriteContract();
  const { isLoading: isWaiting, isSuccess } = useWaitForTransactionReceipt({ hash });

  const delegate = async () => {
    return await writeContractAsync({
      address: CB_TOKEN_ADDRESS,
      abi: CB_TOKEN_ABI,
      functionName: "delegate",
      args: [delegatee],
    });
  };

  return {
    delegate,
    hash,
    isPending: isPending || isWaiting,
    isSuccess,
    error,
    reset,
  };
}

export function useProposals() {
  const { data: proposalIds, refetch: refetchIds, isLoading: isIdsLoading } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "getProposals",
    query: { refetchInterval: 30000 },
  });

  return {
    proposalIds: (proposalIds as bigint[] | undefined) || [],
    refetch: refetchIds,
    isLoading: isIdsLoading,
  };
}

export function useProposal(proposalId: bigint | undefined) {
  const { data, refetch, isLoading, error } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "proposals",
    args: proposalId ? [proposalId] : undefined,
    query: { enabled: !!proposalId, refetchInterval: 15000 },
  });

  const { data: state } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "state",
    args: proposalId ? [proposalId] : undefined,
    query: { enabled: !!proposalId, refetchInterval: 15000 },
  });

  return {
    proposal: data as Proposal | undefined,
    state: state ? PROPOSAL_STATES[Number(state)] : undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useProposalState(proposalId: bigint | undefined) {
  const { data, refetch, isLoading, error } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "state",
    args: proposalId ? [proposalId] : undefined,
    query: { enabled: !!proposalId, refetchInterval: 15000 },
  });

  return {
    state: data ? PROPOSAL_STATES[Number(data)] : undefined,
    stateRaw: data as number | undefined,
    refetch,
    isLoading,
    error,
  };
}

export function useVotes(account?: `0x${string}`) {
  const { address: connectedAccount } = useAccount();
  const targetAccount = account || connectedAccount;

  const { data, refetch, isLoading, error } = useReadContract({
    address: CB_TOKEN_ADDRESS,
    abi: CB_TOKEN_ABI,
    functionName: "getVotes",
    args: targetAccount ? [targetAccount] : undefined,
    query: { enabled: !!targetAccount, refetchInterval: 30000 },
  });

  return {
    votes: data as bigint | undefined,
    formattedVotes: data ? formatUnits(data, 18) : "0",
    refetch,
    isLoading,
    error,
  };
}

export function useQuorum() {
  const { data, refetch, isLoading } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "quorum",
    query: { refetchInterval: 3600000 },
  });

  return {
    quorum: data as bigint | undefined,
    formattedQuorum: data ? formatUnits(data, 18) : "0",
    refetch,
    isLoading,
  };
}

export function useVotingDelay() {
  const { data, refetch, isLoading } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "votingDelay",
    query: { refetchInterval: 3600000 },
  });

  return {
    votingDelay: data as bigint | undefined,
    refetch,
    isLoading,
  };
}

export function useVotingPeriod() {
  const { data, refetch, isLoading } = useReadContract({
    address: GOVERNOR_ADDRESS,
    abi: GOVERNOR_ABI,
    functionName: "votingPeriod",
    query: { refetchInterval: 3600000 },
  });

  return {
    votingPeriod: data as bigint | undefined,
    refetch,
    isLoading,
  };
}

export function useAllProposals() {
  const { proposalIds, isLoading: isIdsLoading, refetch: refetchIds } = useProposals();
  
  const proposalHooks = proposalIds.map(id => useProposal(id));
  
  const proposals = proposalHooks.map((hook, index) => ({
    id: proposalIds[index],
    ...hook.proposal,
    state: hook.state,
    isLoading: hook.isLoading,
  }));

  return {
    proposals,
    isLoading: isIdsLoading || proposalHooks.some(h => h.isLoading),
    refetch: refetchIds,
  };
}