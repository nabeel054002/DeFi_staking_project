pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DappToken is ERC20{
    constructor() public ERC20("DappToken","DAPP"){
        //minted a million tokens
        _mint(msg.sender, 1000000000000000000000000);
    }
    
}