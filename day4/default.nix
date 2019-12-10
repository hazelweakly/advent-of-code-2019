{ pkgs ? import <nixpkgs> { }, lib ? import ../lib.nix { } }:
with builtins;
with pkgs.lib;
with rec {
  input = "146810-612564";
  min = toInt (substring 0 6 input);
  max = toInt (substring 7 6 input);
  possibles = map toString (range min max);

  iterPairs = f: s: init (imap0 f (stringToCharacters s));
  # hasAdjacent = s: any id (iterPairs (i: c: c == substring (i+1) 1 s) s);
  hasAdjacent = s: length (filter isList (split "11[2-90]?|22|33|44|55|66|77|88|99|00" s)) > 0;
  removeTriples = s: concatStrings (map (x: if !isList x then x else "-") (split "1{3,}|2{3,}|3{3,}|4{3,}|5{3,}|6{3,}|7{3,}|8{3,}|9{3,}|0{3,}" s));
  allAscending = s: all id (iterPairs (i: c: c <= substring (i+1) 1 s) s);
};

{
  inherit allAscending hasAdjacent removeTriples strings iterPairs;
  one = count (s: hasAdjacent s && allAscending s) possibles;
  # two = count (s: hasAdjacent s && allAscending s) (map removeTriples possibles);
}
