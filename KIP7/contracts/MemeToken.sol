// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@klaytn/contracts/KIP/token/KIP7/KIP7.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/IKIP17Enumerable.sol";
import "./interfaces/IVoting.sol";

contract memeToken is KIP7 {

    constructor() KIP7("memeTokenTest", "MTT") {

    }

}