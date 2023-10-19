// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//constant, imutable

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;


    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;
   
    // 21,508 gas - imutable
    // 23,644 gas - non-imutable

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enought ETH"
        );
       
        s_addressToAmountFunded[msg.sender] += msg.value;
         s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function withdrawCheaper() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength;funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(
            ""
            ""
        );
        require(callSuccess, "Call filed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the array
        s_funders = new address[](0);
        //actually withdraw the funds

        //transfer (need to be cast to payable)
        // payable(msg.sender).transfer(address(this).balance);

        //send (.send return boolean and need require field after it)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess ,"Send failed");

        //call (.call return 2 parameters but we need only first)
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(
            ""
            ""
        );
        require(callSuccess, "Call filed");
    }

    

    // What happens if someone sends this contract ETH without calling the fund function ?

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * View / Pure functions (Getters)
     */

    function getAddressToAmoundFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address){
        return s_funders[index];
    }

    function getOwner() external view returns (address){
        return i_owner;
    }
}
