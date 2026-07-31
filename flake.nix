{
  description = "Development environment for Tauri 2.0 + Svelte TypeScript";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        # Rust toolchain (stable)
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
          ];
        };

        # System dependencies required by Tauri 2.0 (Linux)
        libraries = with pkgs; [
          webkitgtk_4_1
          gtk3
          cairo
          gdk-pixbuf
          glib
          dbus
          openssl_3_6
          librsvg
          pango
          harfbuzz
        ];

        # Build tools required by pkg-config and Cargo
        buildInputs = with pkgs; [
          pkg-config
          gobject-introspection
          cargo-tauri # Tauri CLI 2.x
          rustToolchain

          # Node runtime & package managers
          nodejs_22
          corepack # provides pnpm, yarn, etc.
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = buildInputs ++ libraries;

          # Set up library paths so Tauri & Cargo can find WebKitGTK and GTK libs
          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" libraries}"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}"

            # Prevent WebKitGTK from crashing under certain Wayland/NVIDIA configurations
            export WEBKIT_DISABLE_COMPOSITING_MODE=1

            # Fix SVG rendering and GTK icons
            export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"

            echo "🚀 Tauri 2.0 + Svelte Dev Environment Ready!"
            echo "Node: $(node --version)"
            echo "Rust: $(rustc --version)"
            echo "Tauri CLI: $(cargo tauri --version)"
          '';
        };
      }
    );
}
