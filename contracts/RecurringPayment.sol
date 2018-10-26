pragma solidity ^0.4.24;

import "@ethereum-alarm-clock/contracts/contracts/Interface/SchedulerInterface.sol";

contract RecurringPayment {
    address public scheduler;

    address public recipient;

    uint256 public interval;
    uint256 public value;

    address public currentScheduledTx;

    uint256 public constant gwei = 10**10;

    event PaymentScheduled(address indexed scheduledTransaction, address recipient, uint value);
    event PaymentExecuted(address indexed scheduledTransaction, address recipient, uint value);

    constructor(
        address _scheduler,
        address _recipient,
        uint256 _interval,
        uint256 _value
    )   public
        payable
    {
        scheduler = _scheduler;
        recipient = _recipient;
        interval = _interval;
        value = _value;
    }

    function () public payable {
        if (msg.value > 0) {
            return; // accepts funds if the contract is running low.
        }

        process();
    }

    function doSchedule() public returns (address scheduledTransaction) {
        if (currentScheduledTx != address(0)) {
            require(msg.sender == currentScheduledTx);
        }

        currentScheduledTx = SchedulerInterface(scheduler).schedule(
            address(this),                  // Send to this contract.
            "",                             // No bytecode (trigger fallback).
            [
                2000000,                    // Gas
                0,                          // Amount of wei to send.
                255,                        // Size of execution window.
                block.timestamp + interval, // Start of execution window.
                2 * gwei,                   // GasPrice.
                0,                          // Fee.
                2 * gwei,                   // Bounty.
                gwei / 2                    // Required Deposit.
            ]
        );

        emit PaymentScheduled(currentScheduledTx, recipient, value);

        return currentScheduledTx;
    }

    function process() public returns (bool) {
        require(msg.sender == currentScheduledTx);

        recipient.transfer(value);

        if (address(this).balance >= value) {
            doSchedule();
        }
    }
}