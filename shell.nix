{ pkgs ? import <nixpkgs> {} }:
(pkgs.mkShell {
  name = "netlogo";
  nativeBuildInputs = with pkgs; [
      netlogo
  ];
  shellHook = ''
    alias openproject="GDK_SCALE=2 netlogo $(pwd)/src/DarwinSMA.nlogo";
  '';
})
