# Only nightly cargo supports installing binary bundles
rustup toolchain install nightly
rustup update nightly
# This installs all 4 LNP/BP nodes
cargo install --force --all-features bp_node --version "0.8.0-alpha.2"
cargo install --force --all-features lnp_node --version "0.8.0"
cargo install --force --all-features rgb_node --version "0.8.0"
cargo install --force --all-features storm_node --version "0.8.0"
cargo install --force --all-features store_daemon --version "0.8.0"
# This install --forces a dozen of command-line tools for working with LNP/BP stack
cargo install --force --all-features descriptor-wallet --version "0.8.3"
cargo install --force --all-features bp-core --version "0.8.0"
cargo install --force --all-features rgb-std --version "0.8.0"
cargo install --force --all-features rgb20 --version "0.8.0-rc.4"
cargo install --force --all-features bp-cli --version "0.8.0-alpha.2"
cargo install --force --all-features lnp-cli --version "0.8.0"
cargo install --force --all-features rgb-cli --version "0.8.0-rc.1"
cargo install --force --all-features storm-cli --version "0.8.0"
cargo install --force --all-features store-cli --version "0.8.0"
