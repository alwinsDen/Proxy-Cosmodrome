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
        fn get_process_stats(pid: u32) -> String;
        fn test_trigger_click();
    }

    extern "Swift" {
        fn on_command_output(instance_id: String, output: String);
        fn on_command_done(instance_id: String, exit_code: i32);
        fn on_process_started(instance_id: String, pid: u32);
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
                ffi::on_command_done(instance_id, -1);
                return;
            }
        };

        let pid = child.id();
        RUNNING_PIDS.lock().unwrap().insert(instance_id.clone(), pid);
        ffi::on_process_started(instance_id.clone(), pid);

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

        let exit_code = match child.wait() {
            Ok(status) => status.code().unwrap_or(-1),
            Err(_) => -1,
        };
        let _ = stdout_handle.join();
        let _ = stderr_handle.join();

        RUNNING_PIDS.lock().unwrap().remove(&instance_id);
        ffi::on_command_done(instance_id, exit_code);
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

fn get_process_stats(pid: u32) -> String {
    println!("PROCESS PID: {}", pid.to_string());
    let output = Command::new("ps")
        .arg("-o")
        .arg("pid,%cpu,%mem,etime")
        .arg("-p")
        .arg(pid.to_string())
        .output();

    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            let lines: Vec<&str> = stdout.lines().collect();
            if lines.len() >= 2 {
                let parts: Vec<&str> = lines[1].split_whitespace().collect();
                if parts.len() >= 4 {
                    return format!(
                        r#"{{"cpu":"{}","mem":"{}","uptime":"{}"}}"#,
                        parts[1], parts[2], parts[3]
                    );
                }
                format!("ERROR: Failed to parse ps output: '{}'", lines[1])
            } else if out.status.success() {
                format!("ERROR: No process data for pid {}", pid)
            } else {
                format!("ERROR: ps exited with status {}", out.status)
            }
        }
        Err(e) => format!("ERROR: {}", e),
    }
}

fn test_trigger_click(){
    println!("Swift-rust FFI test!");
}
