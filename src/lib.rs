use std::collections::HashMap;
use std::fs;
use std::io::{BufRead, BufReader};
use std::os::unix::process::CommandExt;
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::sync::{LazyLock, Mutex};
use std::thread;

static RUNNING_PIDS: LazyLock<Mutex<HashMap<String, u32>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

fn config_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".proxy-cosmodrome")
}

fn config_file() -> PathBuf {
    config_dir().join("default-configs.json")
}

#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        fn print_hello_rusted();
        fn get_config_dir() -> String;
        fn load_config() -> String;
        fn save_config(json: String) -> bool;
        fn run_command_streaming(command: String, working_dir: String, instance_id: String);
        fn kill_process(instance_id: String);
    }

    extern "Swift" {
        fn on_command_output(instance_id: String, output: String);
        fn on_command_done(instance_id: String);
    }
}

fn print_hello_rusted() {
    println!("Created by alwin, alwinsden.com")
}

fn get_config_dir() -> String {
    config_dir().to_string_lossy().to_string()
}

fn load_config() -> String {
    let file = config_file();

    if !file.exists() {
        if let Err(e) = fs::create_dir_all(config_dir()) {
            return format!("ERROR: Failed to create config directory: {}", e);
        }

        let dir_path = config_dir().to_string_lossy().to_string();
        let initial = format!("{{\n  \"base_config_location\": \"{}\"\n}}\n", dir_path);

        match fs::write(&file, &initial) {
            Ok(_) => {}
            Err(e) => return format!("ERROR: Failed to write default config: {}", e),
        }
    }

    match fs::read_to_string(&file) {
        Ok(content) => content,
        Err(e) => format!("ERROR: Failed to read config: {}", e),
    }
}

fn save_config(json: String) -> bool {
    let file = config_file();

    match fs::write(&file, &json) {
        Ok(_) => true,
        Err(_) => false,
    }
}

fn run_command_streaming(command: String, working_dir: String, instance_id: String) {
    let shell = std::env::var("SHELL").unwrap_or_else(|_| "zsh".to_string());
    let full_command = format!("cd \"{}\" && {}", working_dir, command);

    thread::spawn(move || {
        let mut child = match Command::new(&shell)
            .arg("-l")
            .arg("-c")
            .arg(&full_command)
            .process_group(0)
            .env_clear()
            .env("HOME", std::env::var("HOME").unwrap_or_default())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
        {
            Ok(child) => child,
            Err(e) => {
                ffi::on_command_output(instance_id.clone(), format!("ERROR: {}\n", e));
                ffi::on_command_done(instance_id);
                return;
            }
        };

        let pid = child.id();
        RUNNING_PIDS.lock().unwrap().insert(instance_id.clone(), pid);

        let stdout_handle = {
            let id = instance_id.clone();
            let stdout = child.stdout.take();
            thread::spawn(move || {
                if let Some(stdout) = stdout {
                    let reader = BufReader::new(stdout);
                    for line in reader.lines() {
                        match line {
                            Ok(text) => {
                                ffi::on_command_output(id.clone(), text + "\n");
                            }
                            Err(_) => break,
                        }
                    }
                }
            })
        };

        let stderr_handle = {
            let id = instance_id.clone();
            let stderr = child.stderr.take();
            thread::spawn(move || {
                if let Some(stderr) = stderr {
                    let reader = BufReader::new(stderr);
                    for line in reader.lines() {
                        match line {
                            Ok(text) => {
                                ffi::on_command_output(id.clone(), text + "\n");
                            }
                            Err(_) => break,
                        }
                    }
                }
            })
        };

        child.wait().ok();
        let _ = stdout_handle.join();
        let _ = stderr_handle.join();

        RUNNING_PIDS.lock().unwrap().remove(&instance_id);
        ffi::on_command_done(instance_id);
    });
}

fn kill_process(instance_id: String) {
    let pid = RUNNING_PIDS.lock().unwrap().remove(&instance_id);
    if let Some(pid) = pid {
        let _ = std::process::Command::new("kill")
            .arg("-TERM")
            .arg(format!("-{}", pid))
            .status();
    }
}
