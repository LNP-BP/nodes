Order of repo/crate compillation for a new LNP/BP release:

Prerequisites:
- amplify
  - amplify_derive
  - amplify_num
  - amplify_apfloat
- lnpbp_secp256k1zkp

1. strict_encoding
  - strict_encoding
  - strict_encoding_test
  - encoding_derive_helpers - optional
  - strict_encoding_derive - optional
2. stens
3. client_side_validation
  - confined_encoding
  - commit_verify
  - single_use_Seals
  - client_side_validation
4. lightning_encoding
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
8. bp-core
  - bp-dbc
  - bp-seals
  - bp-core
9. rgb-core
10. lnp-core
11. storm-core
12. lnpbp_invoices
13. rgb-std
14. rgb_node
  - rgb_rpc
  - rgb_node
  - rgb-cli
15. lnp-core
  - lnp2p
  - lnp-core
16. storm-core
17. stored
18. storm_node
  - storm_rpc
  - storm_node
  - storm-cli
19. lnp_node
  - lnp_rpc
  - lnp_node
  - lnp-cli
20. lnpbp-nodes
