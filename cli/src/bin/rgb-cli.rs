#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_RGB_CLI"))
        .status()
        .expect("rgb-cli binary not found")
        .exit_ok()
}
