{
  description = "NJM OS Pure-Java Android Build Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
  };

  outputs = { self, nixpkgs, android-nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      
      sdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
        build-tools-34-0-0
        platforms-android-34
        platform-tools
      ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          sdk
          pkgs.jdk17
          pkgs.zip
          pkgs.apksigner
        ];
      };
    };
}
