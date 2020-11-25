//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "usingtellor/contracts/UsingTellor.sol";
import "usingtellor/contracts/TellorPlayground.sol";

contract SpaceLotto is UsingTellor {

    struct Position {
        uint64 lon;
        uint64 lat;
    }

    uint128 public constant SLOT_DURATION = 600; 

    uint256 public tellorId = 75; //The id on tellor system
    uint256 public ticket = 100000000; //100 Million wei

    mapping(address => mapping(uint256 => Position)) public bets; //better -> timestamp -> Position 
    mapping(bytes32 => bool) public uniqueBets;
    mapping(uint256 => bytes32) public slotResults; //slot -> result
    mapping(uint256 => bytes32) public timeResults; //slot -> result
    mapping(uint256 => Position) public readableResults; //slot -> result

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

    function drawResult(uint256 _slotNumber) external {
        uint _currentSlot =  getCurrentSlot();
        require(_slotNumber + 2 <= _currentSlot, "too soon to be drawn");
        require(slotResults[_slotNumber] == bytes32(0), "already have a result for this slot");

        uint256 timeBefore = (_slotNumber + 1) * SLOT_DURATION;
        (bool _retrieved, uint256 _value, uint256 _tellorTimestamp) = getDataBefore(tellorId,timeBefore);
        require(_retrieved, "No value from tellor Oracle");
        
        uint64 _lat = uint64(_value);
        uint64 _lon  = uint64(_value >> 64);
        uint128 _time = uint128(_value >> 128);

        bytes32 result = _hash(_time, _lon, _lat);
        uint256 slot = getSlotFor(uint256(_time));

        require(slot == _slotNumber, "Does not belong to slot");
        slotResults[slot] = result;
        timeResults[uint256(_time)] = result;
        readableResults[slot] = Position(_lon, _lat);
    }

    function getCurrentSlot() public view returns(uint){
        return block.timestamp / SLOT_DURATION;
    }

     function getSlotFor(uint256 _timestamp) public view returns(uint){
        return _timestamp / SLOT_DURATION;
    }

    function getResult(uint256 slot) public view returns(uint64 longitude, uint64 latitude) {
        longitude = readableResults[slot].lon;
        latitude = readableResults[slot].lat;
    }

    function _isValidBet(uint128 _timestamp, uint64 _lon, uint64 _lat) internal view {
        // Can only bet on future slots
        require( getSlotFor(_timestamp) > getCurrentSlot() && _lon > 0 && _lat > 0, "invalid bet");
    }

    function _hash(uint128 _timestamp, uint64 _lon, uint64 _lat) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_timestamp, _lon, _lat));
    }

    receive() external payable { }
}


