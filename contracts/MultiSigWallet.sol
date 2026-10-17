// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MultiSigWallet
/// @notice Educational N-of-M wallet. Not audited. Do not hold real funds.
contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "owners required");
        require(_required > 0 && _required <= _owners.length, "bad threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "zero owner");
            require(!isOwner[owner], "duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256 txId) {
        require(to != address(0), "zero to");
        transactions.push(Transaction({to: to, value: value, data: data, executed: false}));
        txId = transactions.length - 1;
        emit Submit(txId, to, value, data);
        _confirm(txId);
    }

    function confirm(uint256 txId) external onlyOwner {
        _confirm(txId);
    }

    function revoke(uint256 txId) external onlyOwner {
        require(txId < transactions.length, "missing tx");
        require(!transactions[txId].executed, "already executed");
        require(confirmed[txId][msg.sender], "not confirmed");
        confirmed[txId][msg.sender] = false;
        emit Revoke(msg.sender, txId);
    }

    function execute(uint256 txId) external onlyOwner {
        require(txId < transactions.length, "missing tx");
        Transaction storage transaction = transactions[txId];
        require(!transaction.executed, "already executed");
        require(approvalCount(txId) >= required, "need more confirmations");

        transaction.executed = true;
        (bool ok, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(ok, "call failed");
        emit Execute(txId);
    }

    function approvalCount(uint256 txId) public view returns (uint256 count) {
        require(txId < transactions.length, "missing tx");
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmed[txId][owners[i]]) {
                count++;
            }
        }
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function _confirm(uint256 txId) internal {
        require(txId < transactions.length, "missing tx");
        require(!transactions[txId].executed, "already executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        confirmed[txId][msg.sender] = true;
        emit Confirm(msg.sender, txId);
    }
}
