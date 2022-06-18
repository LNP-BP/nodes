#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_STORE_CLI"))
        .status()
        .expect("store-cli binary not found")
        .exit_ok()
}
