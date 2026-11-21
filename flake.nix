{
  description = "Isolated CMake/Ninja investigation shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/a799d3e3886da994fa307f817a6bc705ae538eeb";
  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [ gcc ninja git python3 cmake gnumake pkg-config curl zip unzip gnutar gzip perl openssl zlib patchelf strace ];
    };
  };
}
