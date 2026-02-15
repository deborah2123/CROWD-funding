# CROWD-funding Clarity Smart Contract

A simple crowdfunding smart contract written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language) for the Stacks blockchain. This contract enables a single campaign with contribution tracking, withdrawal, and refund logic.

## Features

- **Single Campaign:** One creator, one funding goal, one deadline.
- **Contribution Tracking:** Contributors can send STX and their contributions are tracked.
- **Withdrawal:** Creator can withdraw funds if the goal is met.
- **Refunds:** Contributors can refund their STX if the goal is not met after the deadline.
- **Error Handling:** Robust error codes for all major failure cases.

## Contract Overview

### Data Variables

- `creator`: The campaign creator (set at deploy).
- `funding-goal`: The minimum amount to raise (default: 1,000,000 microSTX).
- `deadline`: Campaign end (set by creator via `initialize`).
- `total-raised`: Total STX raised so far.
- `withdrawn`: Whether the creator has withdrawn funds.
- `initialized`: Whether the campaign has been initialized.
- `contributions`: Map of contributor principal to their contributed amount.

### Public Functions

- `initialize(duration)`: Creator sets the campaign deadline (in block height or time units).
- `contribute(amount)`: Contribute STX before the deadline.
- `withdraw()`: Creator withdraws funds if the goal is reached.
- `refund()`: Contributors can refund if the goal is not met after the deadline.

### Read-Only Functions

- `get-creator()`: Returns the creator principal.
- `get-goal()`: Returns the funding goal.
- `get-deadline()`: Returns the campaign deadline.
- `get-total-raised()`: Returns the total raised.
- `get-contribution(who)`: Returns the contribution amount for a given principal.
- `is-goal-reached()`: Returns true if the goal is reached.
- `is-campaign-active()`: Returns true if the campaign is active.

## Usage

1. **Deploy the contract**  
   The deployer becomes the campaign creator.

2. **Initialize the campaign**  
   The creator must call `initialize(duration)` to set the deadline.

3. **Contribute**  
   Anyone can call `contribute(amount)` to participate before the deadline.

4. **Withdraw or Refund**  
   - If the goal is met, the creator can call `withdraw()` to collect funds.
   - If the goal is not met after the deadline, contributors can call `refund()` to get their STX back.

## Error Codes

| Code         | Meaning                        |
|--------------|-------------------------------|
| `u100`       | Not creator                   |
| `u101`       | Campaign still active         |
| `u102`       | Campaign ended                |
| `u103`       | Goal not reached              |
| `u104`       | Goal already met              |
| `u105`       | No contribution found         |
| `u106`       | Already withdrawn             |
| `u107`       | STX transfer failed           |
| `u108`       | Not initialized               |
| `u109`       | Already initialized           |
