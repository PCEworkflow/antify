import json
from web3 import Web3
from pathlib import Path
from dotenv import load_dotenv
import streamlit as st

# Define and connect a new Web3 provider
import os
load_dotenv("web3_Ganache.env")
w3 = Web3(Web3.HTTPProvider(os.getenv("http")))

# Function to load the contract
@st.cache_resource
def load_contract():

    # Load Antify ABI
    with open(Path("abi_Antify.json")) as f:
        certificate_abi = json.load(f)

    # Set the contract address (this is the address of the deployed contract)
    load_dotenv("contract_Antify.env")
    contract_address = os.getenv("contract_Address")
    # Get the contract using web3
    contract = w3.eth.contract(address=contract_address, abi=certificate_abi)

    return contract
#load the contract
contract = load_contract()

# Create a function to link the song name to the token ID
def get_token_id(song_Name):
    try:
        # Call the getTokenIdBySongName function in the smart contract
        token_id = contract.functions.getTokenIdBySongName(song_Name).call()
        return token_id[0]
    except Exception as e:
        st.error(f"Token ID not found: {str(e)}")

def buy_token(token_id):
    try:
        # Call the buySongLink function in the smart contract
        tx_hash = contract.functions.buySongLink(token_id).transact({'from': w3.eth.accounts[0], 'value': contract.functions.tokenPrice().call()})
        st.success(f"Transaction successful! Transaction Hash: {tx_hash.hex()}")
    except Exception as e:
        st.error(f"Transaction failed: {str(e)}")



#create streamlit title 
st.title("Antify")

# Create a list of options for the user to select from to buy a token from the minted tokens

st.sidebar.header("Buy a token")
st.sidebar.write("Select a token ID from the dropdown menu below to buy a token from the minted tokens")

# Get total number of songs available to buy
total_NumberOfSongs = contract.functions.countValuesInArray().call()

# Create a enter text string to buy a token with a song name
song_Name = st.text_input("Enter a song name to buy a token")

#Show the token ID for the song name entered
if song_Name:
    token_id = get_token_id(song_Name)
    st.write(f"Token ID: {token_id}")
        
# Create a button to buy the song 
if st.button("Buy Song"):
    token_id = get_token_id(song_Name)
    buy_token(token_id)
    st.balloons()


# Display dropdown menu to select a token
selected_token_id = st.sidebar.selectbox("Select a token ID to buy", list(range(1, total_NumberOfSongs + 1)))

# Display button to buy the selected token
if st.sidebar.button("Buy"):
    buy_token(selected_token_id)
    st.sidebar.balloons()

# Display information about the selected token
st.write("Selected Token Information:")
token_info = contract.functions.getTokenInfo(selected_token_id).call()
st.write(f"Owner: {token_info[0]}")
st.write(f"Song Link: {token_info[1]}")
st.write(f"Vocalist: {token_info[2]}")
st.write(f"Original Artist: {token_info[3]}")
st.write(f"Record Label: {token_info[4]}")
st.write(f"Remix Artist: {token_info[5]}")

# Display payment information about the selected token
payment_info = contract.functions.getTotalPaymentInfo(selected_token_id).call()
st.write(f"Tokens Minted: {payment_info[0]}")
st.write(f"Tokens Sold: {payment_info[1]}")
st.write(f"Mint Timestamp: {payment_info[2]}")
st.write(f"Amplify Fee: {Web3.from_wei(payment_info[4], 'ether')}")
st.write(f"Vocalist Payment: {Web3.from_wei(payment_info[5], 'ether')}")
st.write(f"Original Artist Payment: {Web3.from_wei(payment_info[6], 'ether')}")
st.write(f"Record Label Payment: {Web3.from_wei(payment_info[7], 'ether')}")
st.write(f"Remix Artist Payment: {Web3.from_wei(payment_info[8], 'ether')}")
st.write(f"Total Payment: {Web3.from_wei(payment_info[3], 'ether')}")


# Display button to show Buyer information
if st.button("Show All Buyers Information"):
    buyer_info = contract.functions.getAllBuyers(selected_token_id).call()
    st.write(f"Buyer: {buyer_info[0]}")
    st.write(f"Buyer Timestamp: {buyer_info[1]}")

