#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_DESCRIPTOR_WALLET_btc-hot"))
        .status()
        .expect("btc-hot binary not found")
        .exit_ok()
}
