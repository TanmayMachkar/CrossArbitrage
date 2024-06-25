# FlashLoan Arbitrage Contract

## Overview

This Solidity contract facilitates flash loan-based cross arbitrage on the Ethereum blockchain. It's designed to leverage price differences between assets on Uniswap, aiming to generate profits through successive trades within a single transaction block.

## Contract Functionality

### `initateArbitrage`

- **Description:** Initiates the arbitrage by swapping borrowed USDC for LINK in the liquidity pool.
- **Parameters:**
  - `_tokenBorrow`: Address of the borrowed token.
  - `_amount`: Amount of token to borrow for the arbitrage.
- **Actions:**
  - Approves WETH, USDC, and LINK token spending on the Uniswap Router.
  - Identifies the liquidity pool between USDC and LINK.
  - Swaps USDC for LINK in the liquidity pool, initiating the arbitrage process.

### `uniswapV2Call`

- **Description:** Executes the arbitrage steps and handles repayment to the flash loan pool.
- **Parameters:**
  - `_sender`: Address initiating the call.
  - `_amount0`: Amount of the first token in the pair.
  - `_amount1`: Amount of the second token in the pair.
  - `_data`: Encoded data containing details for the arbitrage.
- **Actions:**
  - Checks and validates the sender and contract alignment.
  - Decodes the data to retrieve loan details (borrowed token, amount, borrower's address).
  - Executes the series of trades for cross arbitrage (USDC → LINK → USDC).
  - Verifies the profitability of the arbitrage.
  - Transfers profits to the initiator and repays the flash loan.

### Other Functions

- `getBalanceOfToken`: Retrieves the contract's balance of a specific token.
- `placeTrade`: Executes token swaps through Uniswap based on specified tokens and amounts.
- `checkResult`: Helper function to check if the arbitrage yields profits.

### Prerequisites

- Ensure you have a development environment set up with Node.js and npm installed.

### Installation

1. Clone the repository:
   ```
   https://github.com/TanmayMachkar/CrossArbitrage.git
   ```

2. Navigate to the project directory:
   ```
   cd CrossArbitrage
   ```

3. Install dependencies:
   ```
   npm install
   ```

### Testing
1. Test the FlashLoan smart contract:
   ```
   npx hardhat test
   ```

## Usage

1. Deploy the contract on the Ethereum blockchain.
2. Call `initateArbitrage` with the desired parameters to start the arbitrage process.
3. The contract will autonomously execute trades and handle repayments.
4. Ensure sufficient liquidity and price differences to yield profitable arbitrage.
5. If you get an error "Not profitable Arbitrage" then find crypto pairs and replace them in the contract which can provide you with profitable arbitrage.

## Disclaimer

⚠️ Cross arbitrage involves financial risks. Understanding the contract functionalities, market dynamics, and implications is crucial before using this software.
