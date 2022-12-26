Order of repo/crate compillation for a new LNP/BP release (as of v0.9):

## Prerequisites

- rust-amplify/rust-amplify
  - amplufy_syn
  - amplify_derive
  - amplify_num
  - amplify_apfloat
  - amplify
- LNP-BP/rust-secp256k1-zkp
  - lnpbp_secp256k1zkp

## Consensus layer

1. strict_encoding -- separated from client_side_validation in v0.10
    - strict_encoding
    - strict_encoding_test
    - encoding_derive_helpers - optional
    - strict_encoding_derive - optional
2. rust-stens
    - stens
3. rust-aluvm
    - aluvm
5. client_side_validation
    - confined_encoding -- optional, will be introduced in v0.10
    - confined_encoding_derive -- optional, will be introduced in v0.10
    - commit_verify
    - single_use_seals
    - client_side_validation
6. bp-foundation
    - bitcoin_blockchain
    - bitcoin_scripts
7. descriptor-wallet
    - slip132 - optional
    - bitcoin_hd
    - descriptors
    - bitcoin_online
    - psbt
    - descriptor-wallet
8. rust-lnpbp
    - lnpbp_bech32
    - lnpbp_elgamal - optional
    - lnpbp_chain
    - lnpbp_identity - optional
    - lnpbp
9. bp-core
    - bp-dbc
    - bp-seals
    - bp-core
10. rgb-core

## Wallet & networking layer

1. lightning_encoding
    - lightning_encoding_derive
    - lightning_encoding
2. invoices
    - lnpbp_invoices
3. lnp-core
    - lnp2p
    - lnp-core
4. rgb-std
5. storm-core

## Nodes

1. internet2 -- will be replaced in v0.10/v0.11
    - inet2_addr -- optional
    - internet2
2. microservices -- will be replaced in v0.10/v0.11
3. storm-stored
    - store_rpc
    - store_daemon
    - store-cli
4. storm-node
    - storm_rpc
    - storm_node
    - storm-cli
5. rgb-node
    - rgb_rpc
    - rgb_node
    - rgb-cli
6. lnp-node
    - lnp_rpc
    - lnp_node
    - lnp-cli
7. lnpbp-nodes
