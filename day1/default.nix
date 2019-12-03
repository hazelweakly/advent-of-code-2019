{ pkgs ? <nixpkgs>, lib ? import "${pkgs}/lib", strings ? lib.strings
, fixedPoints ? lib.fixedPoints }:
with builtins;
let
  floor = n: bitOr n 0;

  fuelRequired = mass: (floor (mass / 3)) - 2;

  sum = xs: foldl' (a: b: a + b) 0 xs;

  rd = p:
    map strings.toInt
    (filter (x: !(isList x) && (x != "")) (split "\n" (readFile p)));

  fuelRequired' = n:
    let n' = fuelRequired n;
    in if n' <= 0 then 0 else n' + (fuelRequired' n');
in {
  answer = {
    one = sum (map fuelRequired (rd ./input));
    two = sum (map fuelRequired' (rd ./input));
  };
}
