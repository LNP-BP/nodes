#![feature(exit_status_error)]

use std::process::{Command, ExitStatusError};

fn main() -> Result<(), ExitStatusError> {
    Command::new(env!("CARGO_BIN_FILE_STORM_NODE_downpourd"))
        .status()
        .expect("downpourd binary not found")
        .exit_ok()
}
