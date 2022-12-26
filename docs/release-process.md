Order of repo/crate compillation for a new LNP/BP release:

## Prerequisites

- amplify
  - amplify_derive
  - amplify_num
  - amplify_apfloat
- lnpbp_secp256k1zkp

## Main order

1. strict_encoding
    - strict_encoding
    - strict_encoding_test
    - encoding_derive_helpers - optional
    - strict_encoding_derive - optional
2. stens
3. rust-aluvm
4. client_side_validation
    - confined_encoding
    - commit_verify
    - single_use_Seals
    - client_side_validation
5. bp-foundation
    - bitcoin_blockchain
    - bitcoin_scripts
6. descriptor-wallet
    - slip132 - optional
    - bitcoin_hd
    - descriptors
    - bitcoin_online
    - psdbt
    - descriptor-wallet
7. rust-lnpbp
    - lnpbp_bech32
    - lnpbp_elgamal - optional
    - lnpbp_chain
    - lnpbp_identity
8. lightning_encoding
9. bp-core
    - bp-dbc
    - bp-seals
    - bp-core
10. rgb-core
11. lnp-core
12. storm-core
13. lnpbp_invoices
14. rgb-std
15. rgb_node
    - rgb_rpc
    - rgb_node
    - rgb-cli
16. lnp-core
    - lnp2p
    - lnp-core
17. storm-core
18. stored
19. storm_node
    - storm_rpc
    - storm_node
    - storm-cli
20. lnp_node
    - lnp_rpc
    - lnp_node
    - lnp-cli
21. lnpbp-nodes
