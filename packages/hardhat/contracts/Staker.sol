// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  uint256 public deadline = block.timestamp + 30 seconds;

  uint256 public threshold = 1 ether;

  mapping ( address => uint256 ) public balances;

  event Stake(address, uint256);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier isOverDeadline {
    require(block.timestamp >= deadline, "Deadline has not passed.");
    _;
  }
  
  modifier isUnderDeadline {
    require(block.timestamp < deadline, "Deadline has passed.");
    _;
  }

  modifier hasFailed {
    require(block.timestamp >= deadline, "Deadline has not passed");
    require(address(this).balance < threshold, "Balance not under the threshold");
    _;
  }
  
  modifier hasBalance {
    require(balances[msg.sender] > 0, "Account has no balance.");
    _;
  }
  
  modifier notCompleted {
    require(!exampleExternalContract.completed(), "Fundraising is complete.");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() isUnderDeadline payable public {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() isOverDeadline notCompleted public {
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{ value: address(this).balance }();
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() hasFailed hasBalance notCompleted public {
    payable(msg.sender).transfer(balances[msg.sender]);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256) {
    if (deadline < block.timestamp) {
      return 0;
    }

    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
