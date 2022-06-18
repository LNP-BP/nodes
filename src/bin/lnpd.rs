#![feature(exit_status_error)]

use std::process::{ExitStatusError, Command};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_LNP_NODE_lnpd"))
        .status()
        .expect("lnpd binary not found")
        .exit_ok()
}
