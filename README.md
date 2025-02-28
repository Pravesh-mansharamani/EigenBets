# PredictionMarketHook

This project implements a decentralized prediction market on Uniswap v4 hooks, enabling users to bet on binary outcomes (YES/NO) for events using USDC as the base currency. The market leverages an Automated Market Maker (AMM) with custom logic for swaps, liquidity management, and outcome resolution, and integrates two AI agents for outcome prediction.

- **Deployed Hook Address**: [0xd35eef48a8b2efe557390845ce0d94d91a378ac0](https://sepolia.basescan.org/address/0xd35eef48a8b2efe557390845ce0d94d91a378ac0)

---

## Overview

The `PredictionMarketHook` contract allows users to:
- Bet on YES or NO outcomes by swapping USDC for custom YES/NO tokens.
- Add or remove liquidity to YES-USDC and NO-USDC pools.
- Claim winnings in USDC after the market resolves.

Two AI agents—one built using **Gaia** and the other using **Hyperbolic**—scrape Twitter data and perform sentiment analysis on tweets to predict a deterministic outcome (YES or NO). These predictions are verified through an **Automated Verification System (AVS)**, ensuring the outcome is accurate and presented in a verifiable form.

---

## Key Functions

- **`openMarket()`**: Opens the market for betting, callable only by the owner.
- **`closeMarket()`**: Closes the market, stopping further bets, callable only by the owner.
- **`resolveOutcome(bool _outcomeIsYes)`**: Resolves the market with the final outcome (YES/NO), callable only by the owner.
- **`swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOutMinimum)`**: Swaps tokens (e.g., USDC to YES/NO or YES to NO) with slippage protection.
- **`initializePools()`**: Sets up YES-USDC and NO-USDC pools with initial liquidity, callable only by the owner.
- **`addLiquidity(PoolKey memory key, uint256 usdcAmount, uint256 tokenAmount)`**: Internal function to add liquidity to a specified pool during initialization or swaps.
- **`claim()`**: Allows users to claim USDC winnings based on their winning token holdings after resolution.
- **`getOdds()`**: Returns the current odds (as percentages) for YES and NO outcomes based on pool balances.
- **`getTokenPrices()`**: Returns the current prices of YES and NO tokens derived from pool ratios.
- **`resetMarket()`**: Resets the market for a new prediction round after resolution, callable only by the owner.

---

## AI Agents and Verification

The prediction market integrates two AI agents to determine outcomes:
- **Gaia Agent**: Scrapes Twitter data and runs sentiment analysis on tweets to predict the event outcome (YES/NO).
- **Hyperbolic Agent**: Independently scrapes Twitter data and performs sentiment analysis for outcome prediction.

Both agents analyze the sentiment of tweets related to the event (positive/negative) to reach a deterministic outcome. Their predictions are then verified by an **AVS (Automated Verification System)**, which cross-checks the results for consistency and accuracy. The verified outcome is presented in a transparent, verifiable format for market resolution.

---

## Application Flow

The lifecycle of the prediction market follows these steps:

1. **Market Setup**:
   - The owner deploys the hook and calls `initializePools()` to create YES-USDC and NO-USDC pools with initial liquidity (50,000 USDC and 50,000 YES/NO tokens each).

2. **Betting Phase**:
   - The owner calls `openMarket()` to allow betting.
   - Users swap USDC for YES or NO tokens via `swap()` to place bets or trade between tokens.
   - Liquidity providers can indirectly add liquidity through swaps, tracked by the hook.

3. **Market Closure**:
   - The owner calls `closeMarket()` to stop betting and prepare for resolution.

4. **Outcome Resolution**:
   - The Gaia and Hyperbolic AI agents scrape Twitter and analyze sentiment to predict the outcome.
   - The AVS verifies the predictions, ensuring consensus.
   - The owner calls `resolveOutcome()` with the verified outcome, withdrawing liquidity and collecting USDC for distribution.

5. **Claiming Winnings**:
   - Users holding the winning token (YES or NO) call `claim()` to receive their proportional share of the USDC pool.
   - The market can be reset with `resetMarket()` for a new round.

---

## Automated Market Maker (AMM)

The AMM is built using Uniswap v4 hooks, providing custom logic for the prediction market:

- **Pool Structure**: Two pools (YES-USDC and NO-USDC) manage liquidity and swaps, initialized with a fee of 3000 and tick spacing of 60.
- **Price Discovery**: Token prices are derived from the ratio of USDC to YES/NO tokens in each pool, updated via `_afterSwap()` tracking.
- **Swap Logic**: The `swap()` function handles direct swaps (USDC ↔ YES/NO) or two-step swaps (YES ↔ NO via USDC), enforcing market state checks.
- **Liquidity Management**: The hook tracks pool balances (`usdcInYesPool`, `yesTokensInPool`, etc.) and adjusts them during swaps or liquidity operations.
- **Outcome Settlement**: Upon resolution, liquidity is removed, and the total USDC collected is distributed to winning token holders proportionally.

The AMM ensures continuous trading and odds reflection based on betting activity, with hooks enforcing rules like market state restrictions.

---

## How to Use

1. **Deploy the Hook**: Already deployed at [0xd35eef48a8b2efe557390845ce0d94d91a378ac0](https://sepolia.basescan.org/address/0xd35eef48a8b2efe557390845ce0d94d91a378ac0) on Base Sepolia.
2. **Initialize Pools**: Owner calls `initializePools()` to set up the market.
3. **Open Market**: Owner calls `openMarket()` to start betting.
4. **Place Bets**: Users call `swap()` to trade USDC for YES/NO tokens.
5. **Close Market**: Owner calls `closeMarket()` to end betting.
6. **Resolve Outcome**: Owner calls `resolveOutcome()` with AI-verified outcome.
7. **Claim Winnings**: Users call `claim()` to redeem winnings.

---