{
  description = "Search CVE from the command line and a web app";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShell.x86_64-linux =
      pkgs.mkShell {
        buildInputs = with pkgs; [
          pkg-config
          roswell
          sbcl
          gcc
          quicklispPackagesClisp.cffi-grovel
          libuv
          lispPackages.cl-libuv
          # normally stuff goes in here
        ];
        shellHook = ''
              export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath([pkgs.openssl])}:${pkgs.lib.makeLibraryPath([pkgs.libuv])}
            '';
      };
  };
}
