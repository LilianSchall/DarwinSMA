{ pkgs ? import <nixpkgs> {} }:
(pkgs.mkShell {
  name = "netlogo";
  nativeBuildInputs = with pkgs; [
      netlogo
  ];
})
