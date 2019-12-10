{ pkgs ? import <nixpkgs> { }, lib ? import ../lib.nix { } }:
with builtins;
with pkgs.lib;
with rec {
  possibles = map toString (range 146810 612564);

  initialState = {
    char = "";
    ascending = true;
    adjacent = [ ];
    valid = false;
    any = false;
    exact = false;
  };

  transition = state: c: rec {
    char = c;
    ascending = state.ascending && c >= state.char;

    adjacent = [ c ] ++ optionals (c == state.char) state.adjacent;

    valid = exact || length adjacent == 2;
    # NB: Technically the "greater-than" here is unnecessary and just == is sufficient.
    any = state.any || length adjacent >= 2;

    # Without this separately from "valid", some corner cases will crop up:
    # 1233444 <- should be valid, but because the 4444 is last there's no nice
    #            way to track "have already seen a match of exactly two"
    # 1234566 <- shjould be valid, but if you attempt to check if the third
    #            item is different than the two, it'll fail because there's no
    #            third item at the end of a list
    exact = state.exact || (c != state.char && length state.adjacent == 2);
  };

  list =
    map (foldl' transition initialState) (map stringToCharacters possibles);
};

{
  one = count (s: s.any && s.ascending) list;
  two = count (a: a.valid && a.ascending) list;
}
