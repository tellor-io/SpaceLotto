//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "usingtellor/contracts/UsingTellor.sol";

contract SpaceLotto is UsingTellor {


    struct Position {
        uint64 lon;
        uint64 lat;
    }

    uint128 public constant TEN_MINUTES = 600; 

    uint256 public tellorId = 75; //The id on tellor system
    uint256 public ticket = 100000000; //100 Million wei
    uint128 public lastResult;
    mapping(address => mapping(uint256 => Position)) public bets; //better -> timestamp -> Position 
    mapping(bytes32 => bool) public uniqueBets;
    mapping(uint256 => bytes32) public results;

    constructor(address _tellorAddress) public UsingTellor(_tellorAddress) {
        lastResult = uint128(block.timestamp);
    }

    function spaceBet(uint128 _timestamp, uint64 _lon, uint64 _lat) external payable {
        require(msg.value == ticket, "must pay ticket to play");
        _isValidBet(_timestamp, _lon, _lat);

        bytes32 betHash = hash(_timestamp, _lon, _lat);
        require(!uniqueBets[betHash], "bet already taken");

        bets[msg.sender][_timestamp] = new Position(_lon, _lat);
        uniqueBets[betHash] = true;
    }
    function claimPrize(uint128 _timestamp, uint64 _lon, uint64 _lat) external {
        bytes32 betHash = hash(_timestamp, _lon, _lat);
        require(uniqueBets[betHash], "bet must have been taken");
        require(bets[msg.sender][_timestamp].lon == _lon, "wrong position");
        require(bets[msg.sender][_timestamp].lat == _lat, "wrong position");
        require(result[_timestamp] == betHash, "result was not drawn");
        
        //Naive Transfer funds for winner
        msg.sender.transfer(balance(address.this));
    }
    function drawResult() external {
        //must be at least 10 min after the last result
        require(uin128(block.timestamp) >= lastResult + TEN_MINUTES, "Too soon for a new draw")

        //getting the earliest tellor value 
        (_retrieved,  _value, _tellorTimestamp) = getDataBefore(tellorId, block.timestamp - 2 * TEN_MINUTES);
        require(_retrieved, "No value from tellor Oracle");
        require(_tellorTimestamp + TEN_MINUTES <= block.timestamp, "tellor value must be old enough");
        uint64 _lat = uint64(value);
        uint64 _lon  = uint64(value >> 64);
        uint128 _time = uint64(value >> 128);

        result = hash(_timestamp, _lon, _lat);
        results[uint256(_time)] = result;

    }
 
    function _isValidBet(uint128 _timestamp, uint64 _lon, uint64 _lat) internal{
        require( _timestamp > block.timestamp && _lon > 0 && _lat > 0, "invalid bet");
    }

    function _hash(uint128 _timestamp, uint64 _lon, uint64 _lat) returns (bytes32) {
        return keccack256(abi.encodePacked(_timestamp, _lon, _lat));
    }


}


