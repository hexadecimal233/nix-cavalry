{ pkgs, lib ? pkgs.lib }:

let
  version = "2.7.2";
  pname = "cavalry";

  src = pkgs.fetchurl {
    url = "https://cavalry.studio/downloads/latest/Cavalry.msi";
    hash = "sha256-H+ye9QZCf5BvWwqsrnAvRIolSY4CHZvxVXAggaOkNoY=";
  };

  cavalryReg = pkgs.writeText "cavalry.reg" ''
    REGEDIT4
    [HKEY_CURRENT_USER\Software\Wine\DllOverrides]
    "icuuc"="native,builtin"
    "icuin"="native,builtin"
    "winemenubuilder.exe"=""
  '';

  wrapper = pkgs.writeShellScriptBin pname ''
    set -euo pipefail

    export PATH="${pkgs.wineWow64Packages.stable}/bin:${pkgs.winetricks}/bin:$PATH"
    PREFIX_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/cavalry"
    VERSION_FILE="$PREFIX_DIR/.cavalry-version"

    # Version check: rebuild prefix when package updates
    if [ ! -f "$VERSION_FILE" ]; then
      echo "nix-cavalry: first run — setting up Wine prefix..."
      mkdir -p "$PREFIX_DIR"
      export WINEPREFIX="$PREFIX_DIR"
      export WINEARCH="win64"
      export WINEDLLOVERRIDES="mscoree="

      wine wineboot --init
      wine regedit /S "${cavalryReg}"
      winetricks -q corefonts fontsmooth=rgb dxvk
      wineserver -w

      wine msiexec /i ${src} /quiet /norestart
      wineserver -w

      echo "${version}" > "$VERSION_FILE"
      echo "nix-cavalry: setup complete."
    elif [ "$(cat "$VERSION_FILE")" != "${version}" ]; then
      echo "nix-cavalry: version update — reinstalling Cavalry..."
      export WINEPREFIX="$PREFIX_DIR"
      export WINEARCH="win64"
      export WINEDLLOVERRIDES="mscoree="

      # Only reinstall MSI, everything else (registry, fonts, DXVK) stays
      wine msiexec /i ${src} /quiet /norestart
      wineserver -w

      echo "${version}" > "$VERSION_FILE"
      echo "nix-cavalry: update complete."
    fi

    export WINEPREFIX="$PREFIX_DIR"
    export WINEARCH="win64"
    export WINEDLLOVERRIDES="mscoree="
    export WINEDEBUG="-all"

    exec wine "C:\Program Files\Cavalry\Cavalry.exe" "''${@}"
  '';

  mimeXml = pkgs.runCommand "cavalry-mime" {} ''
    mkdir -p $out/share/mime/packages
    cat > $out/share/mime/packages/cavalry.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-cavalry-cv">
    <comment>Cavalry Scene</comment>
    <sub-class-of type="text/plain"/>
    <glob pattern="*.cv"/>
  </mime-type>
  <mime-type type="application/x-cavalry-pal">
    <comment>Cavalry Palette</comment>
    <sub-class-of type="text/plain"/>
    <glob pattern="*.pal"/>
  </mime-type>
</mime-info>
EOF
  '';

  cavalryIcon = pkgs.runCommand "cavalry-icons" {
    nativeBuildInputs = [ pkgs.icoutils pkgs.imagemagick pkgs.msitools ];
  } ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    EXTRACT=/tmp/cav-icons-$$

    # App icon: extract Cavalry.exe resource (IDI_ICON1)
    msiextract -C "$EXTRACT" ${src} Cavalry/Cavalry.exe
    wrestool -x -t 14 "$EXTRACT/Cavalry/Cavalry.exe" | \
      magick ico:- -resize 256x256 $out/share/icons/hicolor/256x256/apps/cavalry.png

    # File-type icons from MSI
    msiextract -C "$EXTRACT" ${src} Cavalry/cavProjectIcon.ico Cavalry/cavPaletteIcon.ico
    magick "$EXTRACT/Cavalry/cavProjectIcon.ico" -resize 256x256 $out/share/icons/hicolor/256x256/apps/application-x-cavalry-cv.png
    magick "$EXTRACT/Cavalry/cavPaletteIcon.ico" -resize 256x256 $out/share/icons/hicolor/256x256/apps/application-x-cavalry-pal.png

    rm -rf "$EXTRACT"
  '';

in
pkgs.symlinkJoin {
  name = "${pname}-${version}";
  inherit pname version;

  paths = [
    wrapper
    mimeXml
    cavalryIcon
    (pkgs.makeDesktopItem {
      name = pname;
      exec = "${wrapper}/bin/${pname} %U";
      icon = pname;
      desktopName = "Cavalry";
      comment = "Cavalry Motion Graphics";
      type = "Application";
      categories = [ "Graphics" "2DGraphics" "X-Animation" ];
      mimeTypes = [
        "x-scheme-handler/cavalry"
        "application/x-cavalry-cv"
        "application/x-cavalry-pal"
      ];
      keywords = [ "animation" "motion" "graphics" "2D" "vector" ];
      startupWMClass = "cavalry.exe";
    })
  ];

  meta = with lib; {
    description = "2D animation & motion graphics software";
    homepage = "https://cavalry.studio";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
