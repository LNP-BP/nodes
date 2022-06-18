#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_BP_NODE_bpd"))
        .status()
        .expect("bpd binary not found")
        .exit_ok()
}
