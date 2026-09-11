{
  description = "Typed BDD scenarios for Tasty, built with GHC 9.12.3";
  nixConfig = {
    extra-substituters = [ "https://cache.iog.io" ];
    extra-trusted-public-keys =
      [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ];
  };
  inputs = {
    haskellNix.url =
      "github:input-output-hk/haskell.nix/8b447d7f57d62fab9249f79bb916bc891e29b9d0";
    hackageNix = {
      url =
        "github:input-output-hk/hackage.nix/b6b4aa4bd699f743238da45c7f43da5a26a822f7";
      flake = false;
    };
    haskellNix.inputs.hackage.follows = "hackageNix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    lintNixpkgs.url =
      "github:NixOS/nixpkgs/647e5c14cbd5067f44ac86b74f014962df460840";
    mkdocs.url =
      "github:paolino/dev-assets/60fcec8ed6ec760e60cf92a41e6713d77ce49900?dir=mkdocs";
  };
  outputs = { nixpkgs, haskellNix, lintNixpkgs, mkdocs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ haskellNix.overlay ];
      };
      lintPkgs = import lintNixpkgs { inherit system; };
      project = import ./nix/project.nix { inherit pkgs lintPkgs; };
      components = project.hsPkgs.tasty-bdd.components;
      sourceDist = import ./nix/source-dist.nix {
        pkgs = lintPkgs;
        src = ./.;
      };
      archiveProject = import ./nix/project.nix {
        inherit pkgs lintPkgs;
        src = "${sourceDist}/source";
      };
      checks = import ./nix/checks.nix {
        inherit pkgs lintPkgs components;
        archiveComponents = archiveProject.hsPkgs.tasty-bdd.components;
        src = ./.;
        docsShell = mkdocs.devShells.${system}.default;
      };
    in {
      packages.${system} = {
        default = components.library;
        tests = components.tests.test;
        example = components.tests.example;
        docs = checks.docs;
        source-dist = sourceDist;
      };
      devShells.${system}.default = project.shell;
      checks.${system} = builtins.removeAttrs checks [ "apps" ];
      apps.${system} = builtins.mapAttrs (_: app: {
        type = "app";
        meta.description = "Run the tasty-bdd ${app.name} check";
        program = pkgs.lib.getExe app;
      }) checks.apps;
    };
}
