// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ExternalCalls {
    mapping(address => uint8) public score;

    struct IncreaseTwice {
        uint8 first;
        uint8 second;
    }

    function increaseScore(address nxid, uint8 scoreToAdd) external {
        score[nxid] += scoreToAdd;
    }

    function increaseScoreTwice(address nxid, uint8 firstScoreToAdd, uint8 secondScoreToAdd) external {
        score[nxid] += firstScoreToAdd;
        score[nxid] += secondScoreToAdd;
    }

    function increaseScoreWithReturn(address nxid, uint8 scoreToAdd) external returns (uint256) {
        score[nxid] += scoreToAdd;
        return score[nxid];
    }

    function increaseScoreWithStruct(address nxid, IncreaseTwice memory inputs) external {
        score[nxid] += inputs.first;
        score[nxid] += inputs.second;
    }
}
