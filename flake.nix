{
  description = "NJM jezični procesor";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    devShells.aarch64-linux.default =
      let pkgs = nixpkgs.legacyPackages.aarch64-linux;
      in pkgs.mkShell {
        packages = with pkgs; [
          git
          clang
        ];
      };
  };
}
