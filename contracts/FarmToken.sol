//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FarmToken is Ownable{
    //this contract can do the following :
    //stake tokens
    //unstake tokens
    //issue tokens
    //addAllowedtokens
    //getETHvalue

    //lets make the main mapping,,,
    //token address -> staker`s address -> amount
    mapping (address => mapping(address => uint256)) public stakingBalance;
    mapping (address => uint256) public uniqueTokensStaked;
    address []public AllowedTokens;
    address []public stakers;
    mapping (address => address) public tokenPriceFeedMapping;
    IERC20 public dapptoken;

    constructor(address _dapptoken) public {
        dapptoken = IERC20(_dapptoken);
    }

    function issuetokens() public onlyOwner {
        for(uint256 idx = 0; idx < stakers.length; idx++){
            address recipient = stakers[idx];
            uint256 usertotalvalue = getUserTotalValue(recipient);
            dapptoken.transfer(recipient, usertotalvalue);
        }
    }
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner 
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }
    function getUserTotalValue(address _user) public view returns (uint256){
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] >0,"No tokens staked");
        for (uint256 idxtoken = 0; idxtoken < AllowedTokens.length; idxtoken++){
            totalValue = totalValue + getUsersingleValue(_user, AllowedTokens[idxtoken]);
        }
        return totalValue;
    }
    function getUsersingleValue(address _user, address _token) public view returns (uint256){
        if (uniqueTokensStaked[_user] <=0){
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // is price in the 10**18 format ??
        return (stakingBalance[_token][_user]*price/(10**decimals));
    }
    function stakeTokens(uint256 _amount, address _tokenaddress) public {
        //will also tell what and how many tokens can u stake
        require(_amount>0,"put in Positive amount for the amount of tokens to be staked");
        //now to see which ones can actually be staked
        require(canstake(_tokenaddress), "the token you are trying to stake can not be staked in this protocol");
        //now to actually stake , first know difference between transfer and transferfrom
        IERC20(_tokenaddress).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender,_tokenaddress);
        stakingBalance[_tokenaddress][msg.sender] += _amount;
        if (uniqueTokensStaked[msg.sender] ==1){
            stakers.push(msg.sender);
        }

        //to see if the above line is valid
    }

    function unstakeTokens(address _token)public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance>0,"amount staked of specified token is 0");
        IERC20(_token).transfer(msg.sender,balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        //reentrancy attacks...
    }

    function updateUniqueTokensStaked(address _user, address _tokenaddress) internal {
        if (stakingBalance[_user][_tokenaddress] <=0){
            uniqueTokensStaked[_user] += 1;
        }
    }
    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int256 price,,,)= priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }
    function addAllowedTokens(address _tokenaddress) public onlyOwner(){
        AllowedTokens.push(_tokenaddress);
    }
    function canstake(address _tokenaddress) public returns (bool){
        //returns true if token can be staked, false elsewise
        if (_tokenaddress == address(dapptoken)){
            return true;
        }
        for (uint256 j = 0; j < AllowedTokens.length; j++){
            if (AllowedTokens[j]==_tokenaddress){
                return true;
            }
        }
        return false;

    }
}