use std::path::PathBuf;
use std::fs;

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
    }

    extern "Swift" {
        //
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
            Ok(_) => {},
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