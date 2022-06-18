#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_STORM_CLI"))
        .status()
        .expect("storm-cli binary not found")
        .exit_ok()
}
