{
  description = "ClipCascade server: self-hosted, end-to-end-encrypted clipboard sync (Sathvik-Rao/ClipCascade).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    let
      jdkVersion = 21;
      pin = import ./pin.nix;
      inherit (pin) version;
      source = {
        asset = "ClipCascade-Server-JRE_${toString jdkVersion}.jar";
        owner = "Sathvik-Rao";
        repo = "ClipCascade";
        # Release tags are unprefixed (3.2.0), overriding flake-lib's default v${version}.
        tag = "\${version}";
        type = "github-release-asset";
      };
    in
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
        jdk = pkgs."jdk${toString jdkVersion}_headless";

        src = pkgs.fetchurl {
          hash = pin.hash or "";
          url = "https://github.com/${source.owner}/${source.repo}/releases/download/${version}/${source.asset}";
        };

        clipcascade-server = pkgs.stdenvNoCC.mkDerivation {
          inherit src version;
          buildPhase = ''
            runHook preBuild

            makeWrapper ${jdk}/bin/java $out/bin/clipcascade-server \
              --add-flags "-jar $src"

            runHook postBuild
          '';
          dontUnpack = true;
          meta = {
            description = "Self-hosted, end-to-end-encrypted clipboard sync server";
            homepage = "https://github.com/Sathvik-Rao/ClipCascade";
            mainProgram = "clipcascade-server";
            platforms = jdk.meta.platforms;
          };
          nativeBuildInputs = [ pkgs.makeWrapper ];
          pname = "clipcascade-server";
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          inherit clipcascade-server;
          default = clipcascade-server;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            minimumTrackingVersion = "3.2.0";
            pinSchema = "github-asset";
          };
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
          };
        };
      }
    );
}
