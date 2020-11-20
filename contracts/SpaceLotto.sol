//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "usingtellor/contracts/UsingTellor.sol";

contract SpaceLotto is UsingTellor {

    struct Position {
        uint64 lon;
        uint64 lat;
    }

    uint128 public constant TEN_MINUTES = 600; 

    uint256 public tellorId = 75; //The id on tellor system
    uint256 public ticket = 100000000; //100 Million wei
    uint256 public lastDrawnSlot = 0;

    mapping(address => mapping(uint256 => Position)) public bets; //better -> timestamp -> Position 
    mapping(bytes32 => bool) public uniqueBets;
    mapping(uint256 => bytes32) public slotResults; //slot -> result
    mapping(uint256 => bytes32) public timeResults; //slot -> result

    constructor( address payable  _tellorAddress) UsingTellor(_tellorAddress) {
    }

    function spaceBet(uint128 _timestamp, uint64 _lon, uint64 _lat) external payable {
        require(msg.value == ticket, "must pay ticket to play");
        _isValidBet(_timestamp, _lon, _lat);

        bytes32 betHash = _hash(_timestamp, _lon, _lat);
        require(!uniqueBets[betHash], "bet already taken");

        bets[msg.sender][_timestamp] = Position(_lon, _lat);
        uniqueBets[betHash] = true;
    }
    function claimPrize(uint128 _timestamp, uint64 _lon, uint64 _lat) external {
        require(slotResults[getSlotFor(_timestamp)] != bytes32(0), "result must have been drawn for this slot");

        bytes32 betHash = _hash(_timestamp, _lon, _lat);
        require(uniqueBets[betHash], "bet must have been taken");
        require(bets[msg.sender][_timestamp].lon == _lon, "wrong position");
        require(bets[msg.sender][_timestamp].lat == _lat, "wrong position");
        require(timeResults[_timestamp] == betHash, "result was not drawn");
        
        //Naive Transfer funds for winner
        msg.sender.transfer(address(this).balance);
    }
    function drawResult() external {
        //must be at least 10 min after the last result
        require(getCurrentSlot() - 2 > lastDrawnSlot, "too soon for a new draw");

        //TODO wrong timestamp here 
        (bool _retrieved, uint256 _value, uint256 _tellorTimestamp) = getDataBefore(tellorId, block.timestamp - TEN_MINUTES);
        require(_retrieved, "No value from tellor Oracle");
        require(_tellorTimestamp + TEN_MINUTES <= block.timestamp, "tellor value must be old enough");
        uint64 _lat = uint64(_value);
        uint64 _lon  = uint64(_value >> 64);
        uint128 _time = uint64(_value >> 128);

        bytes32 result = _hash(_time, _lon, _lat);
        uint256 slot = getSlotFor(uint256(_time));

        require(slotResults[slot] == bytes32(0), "already have a result for this slot");

        slotResults[slot] = result;
        timeResults[uint256(_time)] = result;
        lastDrawnSlot  = slot;
    }

    function getCurrentSlot() public view returns(uint){
        return block.timestamp / 600;
    }

     function getSlotFor(uint256 _timestamp) public view returns(uint){
        return _timestamp / 600;
    }
 
    function _isValidBet(uint128 _timestamp, uint64 _lon, uint64 _lat) internal{
        // Can only bet on future slots
        require( getSlotFor(_timestamp) > getCurrentSlot() && _lon > 0 && _lat > 0, "invalid bet");
    }

    function _hash(uint128 _timestamp, uint64 _lon, uint64 _lat) internal returns (bytes32) {
        return keccak256(abi.encodePacked(_timestamp, _lon, _lat));
    }

    receive() external payable { }


}


