# Install VSR Player on NixOS

The flake exports `packages.x86_64-linux.vsr-player` and makes it the default package. It uses the upstream release with its patched libmpv. The flake lock pins the Qt and FFmpeg versions used to build this package.

```bash
nix build github:SINGH-RAJVEER/vsr-player#vsr-player
nixbox flake add SINGH-RAJVEER/vsr-player --output packages.x86_64-linux.vsr-player --target home-manager
```

For NVIDIA effects, enable the NixOS NVIDIA driver and install the Video Effects SDK runtime once as your desktop user. The runtime installer downloads the pinned wheel from NVIDIA, verifies its SHA-256 hash, and extracts the libraries where VSR Player looks for them. It requires about 600 MB for the download and additional disk space for the extracted runtime.

```bash
vsr-player-install-vfx
vsr-player video.mkv
```

Upstream requires an RTX 20-series or newer for VSR and Ada or Blackwell for its default frame interpolation backend. Open a video and check the player logs for VFX initialization before relying on upscaling.
