#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_RGB_STD_rgb"))
        .status()
        .expect("rgb binary not found")
        .exit_ok()
}
