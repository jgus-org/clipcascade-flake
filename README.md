# clipcascade-flake

A Nix flake that provides the server for [ClipCascade](https://github.com/Sathvik-Rao/ClipCascade), a self-hosted, end-to-end-encrypted clipboard sync tool, packaged from the release jar upstream publishes. Only the server is published here — ClipCascade's desktop and mobile clients come from upstream.

## Outputs

- `packages.<system>.clipcascade-server` — the server, runnable as `clipcascade-server`. `packages.<system>.default` is the same derivation.
- `packages.<system>.update-version`, `packages.<system>.update-branches` — maintenance outputs, not needed to consume the flake.

`<system>` covers `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. There are no overlays, devShells, or apps.

## Consuming it

```nix
inputs.clipcascade = {
  url = "github:jgus-org/clipcascade-flake";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-lib.follows = "flake-lib";
};
```

then take `inputs.clipcascade.packages.${system}.clipcascade-server`, which is what a service or image installs. `nix run github:jgus-org/clipcascade-flake` starts it in the foreground.

## Runtime assumptions

The package installs upstream's server jar and launches it through `java -jar` using a Nix-store headless JDK, so nothing outside the Nix store is needed at run time. Upstream names the jar for the JRE major it builds against (`ClipCascade-Server-JRE_21.jar`), and this flake pairs it with nixpkgs' `jdk21_headless`; a newer JVM runs the jar, an older one refuses to load it.

Upstream runs the server on port 8080, with a health endpoint at `/health`. Behaviour is set through `CC_*` environment variables — message-size limits and the peer-to-peer setting among them — as documented in the `docker-compose.yml` upstream attaches to each release. The server ships with upstream's default administrator credentials, `admin` / `admin123`; replace them before the port is reachable by anyone else.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
