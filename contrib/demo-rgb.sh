#!/usr/bin/env bash

# --- INITIAL SETUP

# Run separate install script
./install.sh

DIR=~/.demo # Replace with the desired location

btc-hot seed ${DIR}/testnet.seed
btc-hot derive --testnet ${DIR}/testnet.seed ${DIR}/testnet
# Copy printed out descriptor and paste it into the next command
DESCRIPTOR="<descriptor>"
echo -n ${DESCRIPTOR} > ${DIR}/testnet.descr
WALLET="${DIR}/testnet.wallet"
btc-cold create ${DIR}/testnet.descr ${WALLET}
btc-cold address ${WALLET}
# Take two addresses and transfer some testnet bitcoins to them
# We use the first address to allocate the issued assets and
# the second one as a change
btc-cold check ${WALLET}
# Note the transaction outputs and save them to these variables
UTXO_ISSUE="<txid>:<vout>"
UTXO_CHANGE="<txid>:<vout>"

tmux new-session -d -s store stored -vvv
tmux new-session -d -s lnp lnpd -vvv --network testnet
tmux new-session -d -s rgb rgbd -vvv --network testnet
tmux new-session -d -s storm storm -vvv --chat --downpour

# --- CONTRACT ISSUANCE

rgb20 -n testnet issue DEMO "RGB demo asset" 10000@${UTXO_ISSUE}
# Copy the contract text to the variable
CONTRACT="rgbc1...."
rgb-cli -n testnet contract register ${CONTRACT}
# Take the contract id and save it
CONTRACT_ID="rgb1...."
# Ensure that the contract got registered
rgb-cli -n testnet contract list
# Check that we have assets on our UTXO:
rgb-cli -n testnet contract state ${CONTRACT_ID}

# ----------------------------------------------------------
# Go to a remote server / other machine and do the following

# Run separate install script
./install.sh

DIR=~/.demo # Replace with the desired location

btc-hot seed ${DIR}/testnet.seed
btc-hot derive --testnet ${DIR}/testnet2.seed ${DIR}/testnet2
# Copy printed out descriptor and paste it into the next command
DESCRIPTOR="<descriptor>"
echo -n ${DESCRIPTOR} > ${DIR}/testnet2.descr
btc-cold create ${DIR}/testnet2.descr ${DIR}/testnet2.wallet
btc-cold address ${DIR}/testnet2.wallet
# Copy first address from the above and send it some testnet bitcoins
btc-cold check ${DIR}/testnet2.wallet
# Note the first transaction output and save it to variable
UTXO="<txid>:<vout>"

tmux new-session -d -s store stored -vvv
tmux new-session -d -s lnp lnpd -vvv --network testnet --listen-all --bifrost
tmux new-session -d -s rgb rgbd -vvv --network testnet
tmux new-session -d -s storm storm -vvv --chat --downpour

# Copy the contract we issued on the other machine
CONTRACT="rgbc1...."
rgb-cli -n testnet contract register ${CONTRACT}

# Lets create a blinded utxo now
rgb blind ${UTXO}
# Save blinding integer factor and the blind UTXO string
INVOICE_BLINDING=#Integer
TXOB="txob1....."

# -- PAYMENT ------------------------------------------------
# Go back to the original machine

# Also save the beneficiary txo string
TXOB="txob1....."
UTXO_SRC=$UTXO_ISSUE # We will transfer issued funds, but in fact it can be any UTXO with the asset

# First, we compose consignment describing the asset we have on _our existing UTXO_
# (this is the UTXO we issued asset to, but it can be any mined UTXO having asset).
# This is not the final consignment; it is a base for constructing the consignment.
CONSIGNMENT=${DIR}/demo.rgbc
rgb-cli -n testnet transfer compose ${CONTRACT_ID} ${UTXO_SRC} ${CONSIGNMENT}
# We can verify that the consignment is correct
rgb consignment validate ${CONSIGNMENT}

# Next, we need to compose state transition performing the transfer for our contract.
# We do not need stash for that, since the base consignment we just created contains
# all required state information. We use RGB20 utility which understands concept of
# the fungible asset and can prepare state transition according to RGB20 schema rules.
TRANSITION=${DIR}/demo.rgbt
rgb20 transfer --utxo ${UTXO_SRC} --change 9900@tapret1st:${UTXO_CHANGE} \
      ${CONSIGNMENT} 100@${TXOB} ${TRANSITION}

# Now we need to prepare PSBT file containing the witness transaction, which will
# commit to the transfer we are doing. We also need to allow Tapret commitments in
# the first output (which is the change output created automatically).
FEE=500
PSBT="${DIR}/demo.psbt"
btc-cold construct --input "${UTXO_SRC} /0/0" --allow-tapret-path 1 ${WALLET} ${PSBT} ${FEE}

# Now we need to embed information about the contract into PSBT
rgb-cli -n testnet contract embed ${CONTRACT_ID} ${PSBT}

# We need to add to the PSBT information about the state transition.
# The daemon will also analyze are there any other assets (under different contracts)
# on the UTXOs we spend in PSBT, and if any, it will generate "blank" state transitions,
# which will be also added to the PSBT file together with contracts for each of those
# assets. Finally, the node will generate disclosure with all those other assets moved
# and store it internally to update its stash once the transaction from PSBT gets
# finalized and mined.
rgb-cli -n testnet transfer combine ${CONTRACT_ID} ${TRANSITION} ${PSBT} ${UTXO_SRC}

# This processes all state transitions under all contracts which are present in PSBT
# and prepares information about them which will be used in LNPBP4 commitments.
rgb psbt bundle ${PSBT}

# We can analyze PSBT and see all the details we added to it
rgb psbt analyze ${PSBT}

# Since the PSBT file now contains ALL required commitments and final Tapret LNPBP4
# data, the txid of the witness transaction is final.
# Now we can finalize the consignment by adding the anchor information to it
# referencing this txid.
# We also instruct the daemon to send the consignment to the beneficiaty LN node.
rgb-cli -n testnet transfer finalize --endseal ${TXOB} ${PSBT} ${CONSIGNMENT} --send

# Those who interested can look into the transfer consignment
rgb consignment inspect ${CONSIGNMENT}

# If we validate the consignment now, we will see that it will report absence
# of the mined endpoint transaction, which is correct - we have not yet published
# witness transaction from the PSBT file
rgb consignment validate ${CONSIGNMENT}

# Lets finalize, sign & publish the witness transaction
dbc commit ${PSBT}
btc-hot sign ${PSBT} ${DIR}/testnet
btc-cold finalize --publish testnet ${PSBT}

# Now, once the transaction will be mined, the verification should pass
rgb consignment validate ${CONSIGNMENT}
