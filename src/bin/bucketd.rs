#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_RGB_NODE_bucketd"))
        .status()
        .expect("bucketd binary not found")
        .exit_ok()
}
