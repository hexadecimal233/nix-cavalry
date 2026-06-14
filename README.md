# nix-cavalry

[Cavalry](https://cavalry.studio) motion graphics software packaged for Linux via Wine + Nix.

## Usage

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run github:hexadecimal233/nix-cavalry --impure
```

### NixOS / Home Manager

```nix
{
  inputs.nix-cavalry.url = "github:hexadecimal233/nix-cavalry";
  # ...
  nixpkgs.overlays = [ nix-cavalry.overlays.default ];
  environment.systemPackages = [ pkgs.cavalry ];
}
```

Requires `nixpkgs.config.allowUnfree = true`.

## Architecture

Cavalry installs on first run into `~/.local/share/cavalry/`:

```
First run:   wineboot → winetricks → DXVK → msiexec /i Cavalry.msi
Subsequent:  skip setup, launch directly
Version update: re-run msiexec only, user data preserved
```

No overlayfs, no FUSE, no external frameworks.

## Known issues

| Issue | Workaround |
|-------|-----------|
| Connection viewport black | Use JS Console: `api.connect(source, target)` |
| Canva SSO double launch | Desktop file's `%U` + `MimeType` handle this |

## Credits

- [CavalryOnLinux Gist](https://gist.github.com/micahlt/3c97f834adaf688fe18344c0f546466c)
- [affinity-nix](https://github.com/mrshmllow/affinity-nix)
