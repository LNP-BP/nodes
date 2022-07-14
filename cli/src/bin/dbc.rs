#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_BP_CORE_dbc"))
        .status()
        .expect("dbc binary not found")
        .exit_ok()
}
