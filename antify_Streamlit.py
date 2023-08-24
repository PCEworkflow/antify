import json
from web3 import Web3
from pathlib import Path
from dotenv import load_dotenv
import streamlit as st

# Define and connect a new Web3 provider
import os


load_dotenv("web3_Ganache.env")
infra_url= 'http://127.0.0.1:7545'
w3 = Web3(Web3.HTTPProvider(infra_url))
################################################################################
# Contract Helper function:
# 1. Loads the contract once using cache
# 2. Connects to the contract using the contract address and ABI
################################################################################


@st.cache(allow_output_mutation=True)
def load_contract():

    # Load Art Gallery ABI
    with open(Path("abi_Antify.json")) as f:
        certificate_abi = json.load(f)

    # Set the contract address (this is the address of the deployed contract)
    load_dotenv("contract_Antify.env")
    contract_address = os.getenv("contract_Address")
    # Get the contract using web3
    contract = w3.eth.contract(address='0x894F8c2C4d915B1AC2fB2bfd712a9ACEb67cd582', abi=certificate_abi)

    return contract
#load the contract
contract = load_contract()

#create streamlit title 
st.title("Antify")

# Create a list of options for the user to select from to buy a token from the minted tokens

st.sidebar.header("Buy a token")
st.sidebar.write("Select a token ID from the dropdown menu below to buy a token from the minted tokens")

# Get total number of songs available to buy
total_NumberOfSongs = contract.functions.countValuesInArray().call()

# Create a enter text string to buy a token with a song name
song_Name = st.text_input("Enter a song name to buy a token")

def buy_token(token_id):
    try:
        # Call the buySongLink function in the smart contract
        tx_hash = contract.functions.buySongLink(token_id).transact({'from': w3.eth.accounts[0], 'value': contract.functions.tokenPrice().call()})
        st.success(f"Transaction successful! Transaction Hash: {tx_hash.hex()}")
    except Exception as e:
        st.error(f"Transaction failed: {str(e)}")

# Display dropdown menu to select a token
selected_token_id = st.sidebar.selectbox("Select a token ID to buy", list(range(1, total_NumberOfSongs + 1)))

# Display button to buy the selected token
if st.sidebar.button("Buy"):
    buy_token(selected_token_id)

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
st.write(f"Amplify Fee: {payment_info[4]}")
st.write(f"Vocalist Payment: {payment_info[5]}")
st.write(f"Original Artist Payment: {payment_info[6]}")
st.write(f"Record Label Payment: {payment_info[7]}")
st.write(f"Remix Artist Payment: {payment_info[8]}")
st.write(f"Total Payment: {payment_info[3]}")


