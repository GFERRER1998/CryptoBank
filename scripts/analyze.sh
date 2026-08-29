#!/bin/bash
# CryptoBank Slither Analysis Script
# Run this script to perform static analysis on the contracts

set -e

echo "=========================================="
echo "  CryptoBank Security Analysis"
echo "=========================================="
echo ""

# Check if slither is installed
if ! command -v slither &> /dev/null; then
    echo "Slither not found. Installing..."
    pip install slither-analyzer
fi

# Check if solc is installed
if ! command -v solc &> /dev/null; then
    echo "solc not found. Please install solc 0.8.24"
    echo "  npm install -g solc"
    exit 1
fi

echo "Running Slither analysis..."
echo ""

# Run Slither
slither . \
    --config-file slither.config.json \
    --solc-remaps "@openzeppelin/=lib/openzeppelin-contracts/" \
    2>&1 | tee audit/slither-output.txt

echo ""
echo "=========================================="
echo "  Analysis Complete"
echo "=========================================="
echo ""
echo "Results saved to:"
echo "  - audit/slither-results.json"
echo "  - audit/slither-output.txt"
echo ""
