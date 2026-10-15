# Nix-based Connect IQ build environment

## Package the downloaded Garmin SDK Manager ZIP into the Nix store (Linux x86_64)

The flake can consume the official ZIP you downloaded locally and package its contents into the Nix store. This avoids keeping an extracted executable in a mutable Downloads directory and lets `nix run` launch the exact manager from its store path.

```sh
CIQ_SDKMANAGER_ZIP="$HOME/Downloads/connectiq-sdk-manager-linux.zip" \
  nix run --impure .#sdkmanager
```

The `--impure` flag is required because the flake reads `CIQ_SDKMANAGER_ZIP` from the environment during evaluation. Use an absolute path. Nix copies the ZIP into the store as a source input, unpacks it in a derivation, and the app launches the resulting `$out/bin/sdkmanager` inside the upstream FHS runtime.

You can also build the packaged SDK Manager without launching it:

```sh
CIQ_SDKMANAGER_ZIP="$HOME/Downloads/connectiq-sdk-manager-linux.zip" \
  nix build --impure .#sdkmanager
```

The resulting `result` symlink points to the unpacked SDK Manager in `/nix/store`. The original ZIP is also copied into the store as a derivation input. This does **not** publish the proprietary archive to a shared/public Nix binary cache; it only makes it available in your local Nix store (and any cache you explicitly configure and are authorized to use).

If you don't set `CIQ_SDKMANAGER_ZIP`, the app falls back to a separately extracted executable or the `CIQ_SDKMANAGER` environment variable:

```sh
CIQ_SDKMANAGER="$HOME/path/to/bin/sdkmanager" nix run .#sdkmanager
```

For troubleshooting the runtime environment interactively, an optional shell is also available:

```sh
nix develop .#sdkmanager
```

The upstream environment currently supports `x86_64-linux` and explicitly permits legacy `libsoup` and `webkitgtk` packages marked insecure by Nixpkgs. Use it only if you accept that compatibility trade-off. The app is intentionally only exposed on Linux x86_64.

## Enter the Monkey C development shell

```sh
nix develop
```

If the SDK is installed in a non-standard location:

```sh
CIQ_SDK="$HOME/ConnectIQ/Sdks/connectiq-sdk-lin-<version>" nix develop
```

The normal development shell searches common SDK installation locations and adds `bin/` to `PATH` when it finds `monkeyc`.

## Checks and build

```sh
ciq-check                 # XML/project structure and Edge 840 target checks
ciq-build                 # compile PRG for edge840
ciq-test                  # static checks + compile smoke test
```

If the installed SDK requires a developer key for compilation, set:

```sh
export CIQ_DEVELOPER_KEY="$HOME/.Garmin/ConnectIQ/developer_key.der"
ciq-build
```

The path is an example; use the actual location of your key. Do not commit the key to version control.

## Simulator and device tests

The included `ciq-test` runs static checks and a compile smoke test. It does not run automated Monkey C unit tests: this project currently has no unit-test suite, and simulator invocation varies with SDK installation and setup. Launch the simulator from the installed SDK, select an Edge 840, and validate restart persistence, new-activity reset, ascent/descent transitions, GPS jitter, FIT fields, notifications, and long-session behaviour on the simulator and a real device.

## Reproducibility

Run `nix flake lock` and commit the resulting `flake.lock` for repeatable dependency revisions. Garmin's SDK is installed separately, so record the SDK version used for release builds.
