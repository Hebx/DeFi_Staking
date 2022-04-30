// stake: Lock tokens into our smart contract
// Withdraw or unstake: Unlock tokens and pull out of the contract
// ClaimReward: users get reward tokens
// Good reward mechanism or Maths

// SPDX-License_Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedMoreThanZero();
contract Staking {

	IERC20 public s_stakingToken;
	IERC20 public s_rewardToken;

	// someones address => how much they stake
	mapping(address => uint256) public s_balances;

	// Mapping of how much each address have been paid
	mapping(address => uint256) public s_userRewardPerTokenPaid;

// a mapping of how much reward each address has to claim
	mapping(address => uint256) public s_rewards;

	uint256 public s_totalSupply;
	uint256 public s_rewardPerTokenStored;
	uint256 public s_lastUpdateTime;
	uint256 public constant REWARD_RATE = 100;

	modifier updateReward(address account) {
		// how much is reward per token?
		// last timestamp
		// between x time, user earned X tokens
		s_rewardPerTokenStored = rewardPerToken();
		s_lastUpdateTime = block.timestamp;
		s_rewards[account] = earned(account);
		s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
		_;
	}

	modifier moreThanZero(uint256 amount) {
		if (amount == 0) {
			revert Staking__NeedMoreThanZero();
		}
		_;
	}

	constructor(address stakingToken, address rewardToken ) {
		s_stakingToken = IERC20(stakingToken);
		s_rewardToken = IERC20(rewardToken);
	}

	function earned(address account)  public view returns(uint256) {
		uint256 currentBalance = s_balances[account];
		// how much they have been paid already
		uint256 amountPaid = s_userRewardPerTokenPaid[account];
		uint256 currentRewardPerToken = rewardPerToken();
		uint256 pastRewards = s_rewards[account];
		uint256 _earned = (currentBalance * (currentRewardPerToken - amountPaid) / 1e18) + pastRewards;
		return _earned;
	}

// Based on how long it's been dring this most recent snapshot
	function rewardPerToken() public view returns(uint256) {
		if (s_totalSupply == 0) {
			return s_rewardPerTokenStored;
		}
		return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
	}

	// WHich Tokens? ERC20 ?
	// If Any Token Must use chainlink data feeds to convert prices between tokens
	function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount)  {
		// keep track of how much this user has staked
		// keep track of how much token we have total
		// transfer the tokens to this contract
		s_balances[msg.sender] = s_balances[msg.sender] + amount;
		s_totalSupply += amount;
		// emit event
		bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
		// require(success, "Failed");
		if (!success) {
			revert Staking__TransferFailed();
		}
	}

	function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
		s_balances[msg.sender] -= amount;
		s_totalSupply -= amount;
		// bool success = s_stakingToken.transferFrom(address(this), msg.sender, amount);
		bool success = s_stakingToken.transfer(msg.sender, amount);
		if (!success) {
			revert Staking__TransferFailed();
		}
	}

	function claimReward() external updateReward(msg.sender) {
		// How much reward they get?

		// contratc emits X tokens per sec
		// disperse them to all token stakers

		// 100 reward tokens / second
		// staked : 50 staked tokens, 20 staked tokens , 30 staked tokens
		// reward : 50 reward tokens, 20 reward tokens , 30 reward tokens

		// stsked: 100, 50, 20 ,30 (total = 200)
		// rewards: 50, 25, 10, 15 (total = 100)

		uint256 reward = s_rewards[msg.sender];
		bool success = s_rewardToken.transfer(msg.sender, reward);
		if (!success) {
			revert Staking__TransferFailed();
		}

	}
}
