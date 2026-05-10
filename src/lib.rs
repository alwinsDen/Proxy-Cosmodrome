//pub use ffi::print_hello_swift;

#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        fn print_hello_rusted();
    }

    extern "Swift" {
        //
    }
}

fn print_hello_rusted() {
    println!("Hello from Rusts")
}