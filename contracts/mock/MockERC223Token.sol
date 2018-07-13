pragma solidity ^0.4.23;

import "sc-library/contracts/ERC223/ERC223MintableToken.sol";
import "./MockERC20Token.sol";


contract MockERC223Token is MockERC20Token, ERC223MintableToken {

}
