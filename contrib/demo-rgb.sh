#!/usr/bin/env bash

# There might be a need to download build-essentials, cmake, python3 and python3-dev
sudo apt install -y build-essentials cmake python3 python3-dev

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
# Find your wallet's testnet xprv (it's in black text for dark theme terminal users)
btc-hot -P info ${DIR}/testnet.seed
# Initialize lnpd with your hot wallet xprv
lnpd -vvv --network testnet init

tmux new-session -d -s store stored -vvv
tmux new-session -d -s lnp lnpd -vvv --network testnet
tmux new-session -d -s rgb rgbd -vvv --network testnet --electrum-server electrum.blockstream.info --electrum-port 60001
tmux new-session -d -s storm stormd -vvv --chat --downpour --msg ~/.lnp_node/testnet/msg
# -OR- run all the daemons within the same terminal (processes must be exited using process manager)
# Note: Try all these commands separately first to ensure they can run
stored -vvv & lnpd -vvv --network testnet & rgbd -vvv --network testnet & stormd -vvv --chat --downpour --msg ~/.lnp_node/testnet/msg &

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

# There might be a need to download build-essentials, cmake, python3 and python3-dev
sudo apt install -y build-essentials cmake python3 python3-dev

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
# Find your wallet's testnet xprv (it's in black text for dark theme terminal users)
btc-hot -P info ${DIR}/testnet.seed
# Initialize lnpd with your hot wallet xprv
lnpd -vvv --network testnet init

tmux new-session -d -s store stored -vvv
tmux new-session -d -s lnp lnpd -vvv --network testnet --listen-all --bifrost
tmux new-session -d -s rgb rgbd -vvv --network testnet --electrum-server electrum.blockstream.info --electrum-port 60001
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
rgb consignment validate ${CONSIGNMENT} electrum.blockstream.info:60001

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
# We also instruct the daemon to send the consignment to the beneficiary LN node.
# If done on the same system (a self-payment), the --send argument can be omitted.
# If done on the remote peer, the --send argument is reqquired.
#   For sending to the remote peer, we need to check if both peers (self and remote) 
#   have connected by Bifrost protocol (check this using `lnp-cli peers` method).
NODE_ID="..." #The node_id of the beneficiary LN node
STORM_ADDR="..." #The stormd IP connected in your RGB node
STORM_PORT="..." #The stormd RPC port
BENEFICIARY="$NODE_ID@$STORM_ADDR:$STORM_PORT"
rgb-cli -n testnet transfer finalize --endseal ${TXOB} ${PSBT} ${CONSIGNMENT} --send $BENEFICIARY

# Those who interested can look into the transfer consignment
rgb consignment inspect ${CONSIGNMENT}

# If we validate the consignment now, we will see that it will report absence
# of the mined endpoint transaction, which is correct - we have not yet published
# witness transaction from the PSBT file
rgb consignment validate ${CONSIGNMENT} electrum.blockstream.info:60001

# Lets finalize, sign & publish the witness transaction
btc-hot sign ${PSBT} ${DIR}/testnet
btc-cold finalize --publish testnet ${PSBT}

# Now, once the transaction will be mined, the verification should pass
rgb consignment validate ${CONSIGNMENT} electrum.blockstream.info:60001

# -- CONSUME AND UNLOCK ASSET ------------------------------------------------
# Go to a remote server / other machine and do the following

# First, we must get all the information required to consume the consignment file.
# The consignment file
CONSIGNMENT=${DIR}/demo.rgbc
# The UXTO used in blinded utxo operation.
RECEIVE_UXTO=$UTXO
# The blinding factor generated in blinded utxo operation.
BLINDING_FACTOR=$INVOICE_BLINDING
# The close method used in PAYMENT operation.
CLOSE_METHOD="tapret1st"

# Next, we need to compose the reveal information to unlock the uxto.
REVEAL="$CLOSE_METHOD@$RECEIVE_UXTO#$BLINDING_FACTOR"

# Let's consume and reveal the concealed seal inside the consignment file.
rgb-cli -n testnet transfer consume ${CONSIGNMENT} --reveal ${REVEAL}

# Now, we need to check if contract state has changed.
# First, get the contract ID
rgb-cli -n testnet contract list
CONTRACT_ID="rgb1...."

# Next, check the new contract state
rgb-cli -n testnet contract state ${CONTRACT_ID}

# Finally, if all works correctly, we can spend the received asset.
# This process equals the PAYMENT operation above, except that this time
# we will use the $RECEIVE_UXTO as $UTXO_SRC and generate another blind utxo.
