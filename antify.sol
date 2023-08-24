// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SongLinkToken is ERC20, Ownable {
    struct TokenInfo {
        address owner;
        string songLink;
        address vocalist;
        address originalArtist;
        address recordLabel;
        address remixArtist;
        uint256 paymentAmplifyFee;
        uint256 paymentVocalist;
        uint256 paymentOriginalArtist;
        uint256 paymentRecordLabel;
        uint256 paymentRemixArtist;
        uint256 ethValue;
        uint256 tokensMinted;
        uint256 tokensSold;
        uint256 mintTimestamp;

        uint256 totalPayment;
        uint256 totalAmplifyFee;
        uint256 totalVocalistPayment;
        uint256 totalOriginalArtistPayment;
        uint256 totalRecordLabelPayment;
        uint256 totalRemixArtistPayment;
    }

    mapping(uint256 => TokenInfo) private _tokenInfo;
    mapping(uint256 => address[]) private _tokenBuyers; // Stores buyer addresses for each tokenId
    mapping(uint256 => uint256[]) private _tokenBuyerTimestamps; // Stores buyer timestamps for each tokenId
    mapping(string => uint256[]) private _songToTokenId; // Maps song names to token IDs
    uint256 public tokenPrice;
    uint256[] tokensUnique;  //keep track of legnth of unique tokenIds

    constructor(string memory name, string memory symbol, uint256 _tokenPrice) ERC20(name, symbol) {
        tokenPrice = _tokenPrice;
    }

    function setTokenPrice(uint256 _newTokenPrice) external onlyOwner {
        tokenPrice = _newTokenPrice;
    }

    function mintWithSongInfo(
        uint256 tokenId,
        uint256 amount,
        address to,
        string memory songLink,
        string memory songName, // Add song name parameter
        address vocalist,
        address originalArtist,
        address recordLabel,
        address remixArtist
    ) external onlyOwner {
        require(tokenId > 0, "Invalid tokenId");
        require(amount > 0, "Invalid amount");

        _mint(address(this), amount); // Mint the specified amount of tokens to the contract

        uint256 mintTimestamp = block.timestamp; // Get the current timestamp

        // Store token information in the ledger
        TokenInfo storage tokenInfo = _tokenInfo[tokenId]; // Get storage reference
        tokenInfo.owner = to;
        tokenInfo.songLink = songLink;
        tokenInfo.vocalist = vocalist;
        tokenInfo.originalArtist = originalArtist;
        tokenInfo.recordLabel = recordLabel;
        tokenInfo.remixArtist = remixArtist;
        tokenInfo.ethValue = 0;
        tokenInfo.tokensMinted = amount;
        tokenInfo.tokensSold = 0;
        tokenInfo.mintTimestamp = mintTimestamp;

        // Update the song name to token ID mapping
        _songToTokenId[songName].push(tokenId);

        //Update the tokensUnique array
        tokensUnique.push(tokenId);

        // Transfer the minted tokens to the provided address
        _transfer(address(this), to, amount);
    }


    function buySongLink(uint256 tokenId) external payable {
        require(msg.value >= tokenPrice, "Insufficient payment");
        require(_tokenInfo[tokenId].vocalist != address(0), "Invalid tokenId");

        TokenInfo storage tokenInfo = _tokenInfo[tokenId];

        // Update token information with ETH value, buyer, and timestamp
        tokenInfo.ethValue += msg.value;

        tokenInfo.totalPayment += tokenPrice; // Accumulate total payment

        _tokenBuyers[tokenId].push(msg.sender);
        _tokenBuyerTimestamps[tokenId].push(block.timestamp);
        tokenInfo.tokensSold++;

        // Transfer the ownership of the token to the buyer
        _transfer(owner(), msg.sender, 1);

        // Execute the distribution logic
        _executeDistribution(tokenId);
    }

    // function getBuyerInfo(uint256 tokenId, uint256 buyerIndex) external view returns (address, uint256) {
    //     require(buyerIndex < _tokenBuyerInfo[tokenId].length, "Invalid buyer index");
    //     uint256 buyerData = _tokenBuyerInfo[tokenId][buyerIndex];
    //     return (address(buyerData >> 128), uint256(uint128(buyerData)));
    // }

    function getBuyerTimestamp(uint256 tokenId, uint256 buyerIndex) external view returns (uint256) {
        require(buyerIndex < _tokenBuyerTimestamps[tokenId].length, "Invalid buyer index");
        return _tokenBuyerTimestamps[tokenId][buyerIndex];
    }

    // funciton to get buyer address and timestamp with only tokenId as the input parameter
    function getBuyerInfo(uint256 tokenId, uint256 buyerIndex) external view returns (address, uint256) {
        require(buyerIndex < _tokenBuyers[tokenId].length, "Invalid buyer index");
        return (_tokenBuyers[tokenId][buyerIndex], _tokenBuyerTimestamps[tokenId][buyerIndex]);
    }


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount == 1, "You can only transfer 1 token");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function withdrawBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Internal function to execute the distribution
    function _executeDistribution(uint256 tokenId) internal {
        TokenInfo storage tokenData = _tokenInfo[tokenId];
        uint256 totalPayment = tokenPrice; // Fixed token price for song link
        
        uint256[] memory payments = calculatePayments(totalPayment);

        // Update accumulated payment values
        tokenData.totalAmplifyFee += payments[0];
        tokenData.totalVocalistPayment += payments[1];
        tokenData.totalOriginalArtistPayment += payments[2];
        tokenData.totalRecordLabelPayment += payments[3];
        tokenData.totalRemixArtistPayment += payments[4];

        updatePaymentInfo(tokenData, payments);

        performTransfers(tokenData, payments);
    }

    function calculatePayments(uint256 totalPayment) internal pure returns (uint256[] memory) {
        uint256 amplifyFee = totalPayment * 5 / 100;
        uint256 recordLabelPayment = totalPayment * 25 / 100;
        uint256 splitPayment = totalPayment - recordLabelPayment - amplifyFee;
        uint256 vocalistPayment = splitPayment * 4 / 10;
        uint256 originalArtistPayment = splitPayment * 5 / 10;
        uint256 remixArtistPayment = splitPayment * 1 / 10;

        uint256[] memory payments = new uint256[](5);
        payments[0] = amplifyFee;
        payments[1] = vocalistPayment;
        payments[2] = originalArtistPayment;
        payments[3] = recordLabelPayment;
        payments[4] = remixArtistPayment;

        return payments;
    }

    function updatePaymentInfo(TokenInfo storage tokenData, uint256[] memory payments) internal {
        tokenData.paymentAmplifyFee = payments[0];
        tokenData.paymentVocalist = payments[1];
        tokenData.paymentOriginalArtist = payments[2];
        tokenData.paymentRecordLabel = payments[3];
        tokenData.paymentRemixArtist = payments[4];
    }

    function performTransfers(TokenInfo storage tokenData, uint256[] memory payments) internal {
        payable(owner()).transfer(payments[0]);

        if (tokenData.vocalist != address(0)) {
            payable(tokenData.vocalist).transfer(payments[1]);
        }

        if (tokenData.originalArtist != address(0)) {
            payable(tokenData.originalArtist).transfer(payments[2]);
        }

        if (tokenData.recordLabel != address(0)) {
            payable(tokenData.recordLabel).transfer(payments[3]);
        }

        if (tokenData.remixArtist != address(0)) {
            payable(tokenData.remixArtist).transfer(payments[4]);
        }
    }

    // function to add all buyers and timestamps to a dataframe
    function getAllBuyers(uint256 tokenId) external view returns (address[] memory, uint256[] memory) {
        return (_tokenBuyers[tokenId], _tokenBuyerTimestamps[tokenId]);
    }

    // Function to get token ID by song name
    function getTokenIdBySongName(string memory songName) external view returns (uint256[] memory) {
        return _songToTokenId[songName];
    }

    //Function to count number of values in tokensUnique array
    function countValuesInArray() external view returns (uint256) {
        return tokensUnique.length;
    }

    // Function to get token information and payment details
    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (
            address owner,
            string memory songLink,
            address vocalist,
            address originalArtist,
            address recordLabel,
            address remixArtist
        )
    {
        TokenInfo memory tokenData = _tokenInfo[tokenId];
        return (
            tokenData.owner,
            tokenData.songLink,
            tokenData.vocalist,
            tokenData.originalArtist,
            tokenData.recordLabel,
            tokenData.remixArtist
        );
    }

    function getPaymentInfo(uint256 tokenId)
        external
        view
        returns (

            uint256 paymentAmplifyFee,
            uint256 paymentVocalist,
            uint256 paymentOriginalArtist,
            uint256 paymentRecordLabel,
            uint256 paymentRemixArtist,
            uint256 ethValue,

            uint256 tokensMinted,
            uint256 mintTimestamp
        )

    {
        TokenInfo memory tokenData = _tokenInfo[tokenId];
        return (

            tokenData.paymentAmplifyFee,
            tokenData.paymentVocalist,
            tokenData.paymentOriginalArtist,
            tokenData.paymentRecordLabel,
            tokenData.paymentRemixArtist,
            tokenData.ethValue,
            tokenData.tokensMinted,
            tokenData.mintTimestamp
        );
    }

    function getTotalPaymentInfo(uint256 tokenId)
        external
        view
        returns (

            uint256 tokensMinted,
            uint256 tokensSold,
            uint256 mintTimestamp,
            uint256 totalPayment,
            uint256 totalAmplifyFee,
            uint256 totalVocalistPayment,
            uint256 totalOriginalArtistPayment,
            uint256 totalRecordLabelPayment,
            uint256 totalRemixArtistPayment
        )

    {
        TokenInfo memory tokenData = _tokenInfo[tokenId];
        return (

            tokenData.tokensMinted,
            tokenData.tokensSold,
            tokenData.mintTimestamp,
            tokenData.totalPayment,
            tokenData.totalAmplifyFee,
            tokenData.totalVocalistPayment,
            tokenData.totalOriginalArtistPayment,
            tokenData.totalRecordLabelPayment,
            tokenData.totalRemixArtistPayment

        );

    }

}