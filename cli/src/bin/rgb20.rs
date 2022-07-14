#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_RGB20")).status().expect("rgb20 binary not found").exit_ok()
}
