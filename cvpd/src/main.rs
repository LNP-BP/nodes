extern crate zmq;
extern crate log;
extern crate env_logger;
extern crate toml;
extern crate secp256k1;
extern crate serde;
#[macro_use] extern crate serde_derive;
#[macro_use] extern crate clap;

use std::{io, fs, thread, env, io::Read};
use std::process::Command;
use std::net::{TcpListener, SocketAddr, IpAddr, Ipv4Addr};
use std::path::Path;

use log::*;
use secp256k1::SecretKey;
use serde_derive::Deserialize;

fn default_data_path() -> &'static Path { Path::new("/var/lib/lnp-bp/state") }
fn default_stated_path() -> &'static Path { Path::new("stated") }
fn default_ip_addr() -> IpAddr { IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1)) }
fn default_p2p_if() -> ConfigIf { ConfigIf { port: 6483, ..Default::default() } }
fn default_api_if() -> ConfigIf { ConfigIf { port: 6484, ..Default::default() } }

#[derive(Debug, Serialize, Deserialize, Clone, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct Config<'a> {
    #[serde(borrow)]
    #[serde(default = "default_data_path")]
    pub data_dir: &'a Path,
    #[serde(borrow)]
    #[serde(default = "default_stated_path")]
    pub stated_bin: &'a Path,
    #[serde(default = "default_p2p_if")]
    pub p2p_if: ConfigIf,
    #[serde(default = "default_api_if")]
    pub api_if: ConfigIf,
    #[serde(default)]
    pub node_key: AccessToken,
}

impl<'a> Default for Config<'a> {
    fn default() -> Self {
        Config {
            data_dir: default_data_path(),
            stated_bin: default_stated_path(),
            p2p_if: default_p2p_if(),
            api_if: default_api_if(),
            node_key: AccessToken::default()
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct ConfigIf {
    pub port: u16,
    #[serde(default = "default_ip_addr")]
    pub addr: IpAddr,
}

impl Default for ConfigIf {
    fn default() -> Self {
        ConfigIf {
            port: 0, addr: default_ip_addr()
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Eq, PartialEq)]
struct AccessToken(SecretKey);

impl Default for AccessToken {
    fn default() -> Self {
        AccessToken(SecretKey::from_slice(&[
            0xd2, 0x78, 0x63, 0xc6, 0x58, 0x7a, 0x3f, 0x31, 0x28, 0xfe, 0x13, 0x09, 0x75, 0xc6,
            0xe7, 0x25, 0x0f, 0x3a, 0x70, 0x5d, 0x30, 0x58, 0xa1, 0x9a, 0x84, 0xd1, 0x17, 0xeb, 0xe1,
            0x3a, 0x2a, 0x35
        ]).unwrap())
    }
}


fn main() -> io::Result<()> {
    println!("\ncvpd: client-side validation protocol daemon\n");
    env_logger::init();
    log::set_max_level(LevelFilter::Info);

    // 0. Get current directory
    let cwd :String = match env::current_exe() {
        Ok(c) => c.display().to_string(),
        Err(e) => {
            error!("Error processing environment variable of current_exe: {}", e);
            return Err(io::Error::new(io::ErrorKind::Other, "Can't access current directory"));
        }
    };

    // 1. Read command-line arguments
    info!("Reading command-line arguments");
    let matches = clap_app!(cvpd =>
        (version: "0.1.0")
        (author: "Dr Maxim Orlovsky <orlovsky@pandoracore.com>")
        (about: "Daemon for handling CVP peer communications")
        (@arg CONFIG: -c --config +takes_value "Sets a custom config file")
        (@arg DATA: -d --("data-dir") +takes_value "Directory with state information")
        (@arg STATED: -s --("stated-bin") +takes_value "'Sets a custom config file")
        (@arg P2PPORT: -p --("p2p-port") +takes_value "Port for the P2P interface")
        (@arg P2PADDR: -i --("p2p-addr") +takes_value "IP address to bind to for the P2P interface")
        (@arg APIPORT: -a --("api-port") +takes_value "Port for the client API")
        (@arg APIADDR: -b --("api-addr") +takes_value "IP address to bind to for the client API")
    ).get_matches();

    // 2. Read configuration
    info!("Reading configuration file");
    let config_file = matches.value_of("CONFIG").unwrap_or("/etc/lnp-bp/cvpd.toml");
    let mut config_string = String::new();
    let mut config: Config = match fs::File::open(config_file) {
        Ok(mut config_fh) => {
            match config_fh.read_to_string(&mut config_string) {
                Ok(s) => s,
                Err(e) => {
                    error!("Error reading config file {}: {}", config_file, e);
                    return Err(io::Error::new(io::ErrorKind::NotFound, "Error loading config"));
                },
            };
            match toml::from_str(config_string.as_str()) {
                Ok(conf) => conf,
                Err(e) => {
                    error!("Error parsing config file {}: {}", config_file, e);
                    return Err(io::Error::new(io::ErrorKind::Other, "Error loading config"));
                }
            }
        },
        Err(e) => {
            warn!("Error opening config file {}; default configuration is used", config_file);
            Config::default()
        },
    };
    if let Some(data_dir) = matches.value_of("DATA") {
        config.data_dir = Path::new(data_dir);
    }
    let config = config;

    // 3. Analyse existing states and start stated daemons for each of them
    info!("Swarming `stated` daemons for state stored in {:?}", config.data_dir);
    let mut stated_cmd = Command::new(config.stated_bin);
    let ls = match fs::read_dir(config.data_dir) {
        Ok(ls) => ls,
        Err(err) => {
            error!("State directory {:?} does not exist or can't be accessed", config.data_dir);
            return Err(io::Error::new(io::ErrorKind::NotFound, "Failed to access state directory"));
        },
    };
    for entry in ls {
        let entry = entry?;
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        info!("- for state in {:?}", path);
        match path.as_path().to_str() {
            Some(dir) => match stated_cmd.arg(format!("--data-dir={}", dir)).spawn() {
                Ok(child) => info!("Daemon `stated` for {:?} state has started successfully pid {}", path, child.id()),
                Err(err) => error!("Can't start `stated` daemon for {:?}: {}", path, err),
            },
            None => error!("Can't parse path to the state directory {:?}", path),
        }
    }

    // 4. Open peer port for incoming peer connections with state transfers
    info!("Opening P2P connection port");
    let listener = TcpListener::bind(SocketAddr::from((config.p2p_if.addr, config.p2p_if.port)))?;
    thread::spawn(move || {
        for stream in listener.incoming() {
            // handle_client(stream?);
        }
    });

    // 5. Open API port
    info!("Opening API port");
    let zmq_ctx = zmq::Context::new();
    let pull_socket = zmq_ctx.socket(zmq::PULL)?;
    //let push_socket = zmq_ctx.socket(zmq::PUSH)?;
    pull_socket.bind(format!("tcp://{}:{}", config.api_if.addr, config.api_if.port).as_str())?;
    //push_socket.bind(format!("tcp://{}:{}", config.api_if.addr, config.api_if.port).as_str())?;
    let thread = thread::spawn(move || {
        let mut msg = zmq::Message::new();
        pull_socket.recv(&mut msg, 0);
    });
    info!("Waiting for incoming requests");
    thread.join();

    Ok(())
}
