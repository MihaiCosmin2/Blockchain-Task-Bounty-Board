// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract UserReputation {
    mapping(address => uint) public reputation;

    address public bountyBoardAddress; // adresa contractului bountyboard doar el poate modifica scorul
    address public owner;

    event ReputationIncreased(address user, uint amount, uint newScore);

    constructor() {
        owner = msg.sender;
    }

    function setBountyBoard(address _bountyBoardAddress) external {
        require(msg.sender == owner, "doar ownerul poate seta adresa");
        bountyBoardAddress = _bountyBoardAddress;
    }

    function increaseReputation(address _user, uint _amount) external {
        require(msg.sender == bountyBoardAddress, "...");
        reputation[_user] += _amount;

        emit ReputationIncreased(_user, _amount, reputation[_user]);
    }

    function getReputation(address _user) external view returns (uint) {
        return reputation[_user];
    }

}
