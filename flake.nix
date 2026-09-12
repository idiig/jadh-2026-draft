{
  description = "kokin-kugire — draft writing env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { pkgs, lib, ... }:
        let
          rEnv = pkgs.rWrapper.override {
            packages = with pkgs.rPackages; [
              tidyverse
              ggdist
              ggridges
              ggokabeito
              scales
              svglite
              knitr
              kableExtra
              rmarkdown
              rstatix
            ];
          };
        in {
          devShells.default = lib.mkForce (pkgs.mkShell {
            packages = with pkgs; [
              librsvg
              imagemagick
              pdf2svg
              inkscape
              typst
              zip
              unzip
              quarto     # render qmd reports
              rEnv       # R with report/plot packages
            ];

            shellHook = ''
              export QUARTO_R="${rEnv}/bin/R"
            '';
          });
        };
    };
}
