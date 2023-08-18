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
    }

    mapping(uint256 => TokenInfo) private _tokenInfo;
    uint256 public tokenPrice;

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
        address vocalist,
        address originalArtist,
        address recordLabel,
        address remixArtist
    ) external onlyOwner {
        require(tokenId > 0, "Invalid tokenId");
        require(amount > 0, "Invalid amount");
        
        _mint(address(this), amount); // Mint the specified amount of tokens to the contract

        // Store token information in the ledger
        _tokenInfo[tokenId] = TokenInfo({
            owner: to,
            songLink: songLink,
            vocalist: vocalist,
            originalArtist: originalArtist,
            recordLabel: recordLabel,
            remixArtist: remixArtist,
            paymentAmplifyFee: 0,
            paymentVocalist: 0,
            paymentOriginalArtist: 0,
            paymentRecordLabel: 0,
            paymentRemixArtist: 0
        });

        // Transfer the minted tokens to the provided address
        _transfer(address(this), to, amount);
    }

    // Function to get the song info attached to a token
    // function getTokenSongInfo(uint256 tokenId)
    //     external
    //     view
    //     returns (
    //         string memory songLink,
    //         address vocalist,
    //         address originalArtist,
    //         address recordLabel,
    //         address remixArtist
    //     )
    // {
    //     SongInfo memory song = _songInfo[tokenId];
    //     return (song.songLink, song.vocalist, song.originalArtist, song.recordLabel, song.remixArtist);
    // }

    function buySongLink(uint256 tokenId) external payable {
        require(msg.value >= tokenPrice, "Insufficient payment");
        require(_tokenInfo[tokenId].vocalist != address(0), "Invalid tokenId");


        // Transfer the ownership of the token to the buyer
        _transfer(owner(), msg.sender, 1);

        // Execute the distribution logic
        _executeDistribution(tokenId);
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

         // Calculate individual payments based on roles and distribute
        uint256 amplifyFee = totalPayment * 5 / 100;
        uint256 recordLabelPayment = totalPayment * 25 / 100;
        uint256 splitPayment = totalPayment - recordLabelPayment - amplifyFee;
        uint256 vocalistPayment = splitPayment * 4 / 10;
        uint256 originalArtistPayment = splitPayment * 5/10;

        // uint256 vocalistRemixPayment = splitPayment * 3 / 10;
        // uint256 originalArtistRemixPayment = splitPayment * 5 / 10;
        uint256 remixArtistPayment = splitPayment* 1/10;

        // Update payment information in the ledger
        tokenData.paymentAmplifyFee = amplifyFee;
        tokenData.paymentVocalist = vocalistPayment;
        tokenData.paymentOriginalArtist = originalArtistPayment;
        tokenData.paymentRecordLabel = recordLabelPayment;
        tokenData.paymentRemixArtist = remixArtistPayment;

        // Transfer the amplify fee to the contract owner
        payable(owner()).transfer(amplifyFee);

        if (tokenData.vocalist != address(0)) {
            payable(tokenData.vocalist).transfer(vocalistPayment);
        }

        if (tokenData.originalArtist != address(0)) {
            payable(tokenData.originalArtist).transfer(originalArtistPayment);
        }

        if (tokenData.recordLabel != address(0)) {
            payable(tokenData.recordLabel).transfer(recordLabelPayment);
        }

        if (tokenData.remixArtist != address(0)) {
            payable(tokenData.remixArtist).transfer(remixArtistPayment);
        }

    
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
            address remixArtist,
            uint256 paymentAmplifyFee,
            uint256 paymentVocalist,
            uint256 paymentOriginalArtist,
            uint256 paymentRecordLabel,
            uint256 paymentRemixArtist
        )
    {
        TokenInfo memory tokenData = _tokenInfo[tokenId];
        return (
            tokenData.owner,
            tokenData.songLink,
            tokenData.vocalist,
            tokenData.originalArtist,
            tokenData.recordLabel,
            tokenData.remixArtist,
            tokenData.paymentAmplifyFee,
            tokenData.paymentVocalist,
            tokenData.paymentOriginalArtist,
            tokenData.paymentRecordLabel,
            tokenData.paymentRemixArtist
        );
    }
}