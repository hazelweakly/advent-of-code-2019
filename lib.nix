{ pkgs ? import <nixpkgs> { } }:
with builtins;
with pkgs.lib;
rec {
  splitOn = c: f: filter (x: !(isList x) && (x != "")) (split c f);
  toLines = f: splitOn "\n" (readFile f);
}
