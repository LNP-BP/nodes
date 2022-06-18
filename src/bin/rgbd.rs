#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_RGB_NODE_rgbd"))
        .status()
        .expect("rgbd binary not found")
        .exit_ok()
}
