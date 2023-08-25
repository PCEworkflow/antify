# Antify Smart Contract

This is a smart contract implemented in Solidity that represents the SongLinkToken, an ERC-20 token with additional functionality for managing song-related information and payments to various stakeholders.

## Features

- **Minting Tokens with Song Information**: The contract allows the owner to mint tokens with associated song information, including song links, artist details, and payment distribution.
- **Token Buying and Distribution**: Users can purchase song tokens by paying the token price. Upon purchase, payments are distributed to various stakeholders involved in the song.
- **Payment Tracking**: The contract keeps track of payments made for each token and the distribution of payments to artists, labels, and other stakeholders.
- **Unique Token IDs**: The contract ensures that each token ID is unique and increments the tokens minted count accordingly.
- **Owner Management**: The contract owner has the ability to set the token price and withdraw the contract's balance.

## Getting Started

1. Clone this repository to your local machine.
2. Install the required dependencies using npm or yarn.

## Contract Deployment

1. Deploy the contract on the Ethereum blockchain using Remix, Truffle, or your preferred development environment.
2. Set the initial token price using the `_TOKENPRICE` on deployment of the contract.
3. Mint tokens using the `mintWithSongInfo` function by providing the required parameters.

## Usage

- **Minting Tokens**: Call the `mintWithSongInfo` function to mint tokens with associated song information.

- **Buying Tokens**: Users can buy tokens using Ether by calling the `buySongLink` function with the desired token ID.

- **Viewing Token Information**: Use various view functions to retrieve token information, payment details, and more.
