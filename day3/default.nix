{ pkgs ? import <nixpkgs> { }, lib ? import ../lib.nix { } }:
with builtins;
with pkgs.lib;
with rec {
  abs = n: if n >= 0 then n else -n;
  minimum = xs: head (sort (a: b: a < b) xs);
  min = a: b: if a < b then a else b;
  mhat = s: let
            s' = splitString "," x;
            s0 = toInt (elemAt s 0);
            s1 = toInt (elemAt s 1);
  in (abs s0) + (abs s1);
  manhat = m: abs (m.fst) + abs (m.snd);

  lenthz = l: xs: if xs == [] then l else lenthz (l+1) (tail xs);

  toMove = s: rec {
    dir = substring 0 1 s;
    len = toInt (removePrefix dir s);
  };

  consume = m: xs: ys:
    if xs == []
    then if ys == []
      then m
      else m
    else if ys == []
      then m
      else
        let x = head xs;
            y = head ys;
            x' = tail xs;
            y' = tail ys;
        in
        consume (m+1) (tail xs) (tail ys);
            # if x == y then consume (min (mhat x) m) (tail xs) (tail ys)
            # else
            #   if x < y then consume m (tail xs) ys else consume m xs (tail ys);


    # let
    #   lx = xs == [];
    #   ly = ys == [];
    #   x = if !lx then head xs else m;
    #   y = if !ly then head ys else m;
    #
    #   s = splitString "," x;
    #   s0 = toInt (elemAt s 0);
    #   s1 = toInt (elemAt s 1);
    #
    #   xy = if x == y && x < m then (abs s0) + (abs s1) else m;
    # in
    #   # if lx == 0 || ly == 0 then m else consume xy (tail xs) (tail ys);
    #   if lx == 0 || ly == 0 then m else consume (m+1) (tail xs) (tail ys);

  rd = map (l: map toMove (lib.splitOn "," l)) (lib.toLines ./input);
};

let
  start = {
    path = { };
    pos = {
      fst = 0;
      snd = 0;
    };
  };

  # Method 1; attrsets
  move = f: path: pos: {
    U = l:
      let xs = range (pos.snd) (pos.snd + l);
      in {
        path = foldl' f path (map (x: {
          snd = x;
          fst = pos.fst;
        }) xs);
        pos = pos // { snd = pos.snd + l; };
      };

    D = l:
      let xs = (range (pos.snd - l) (pos.snd));
      in {
        path = foldl' f path (map (x: {
          snd = x;
          fst = pos.fst;
        }) xs);
        pos = pos // { snd = pos.snd - l; };
      };

    R = l:
      let xs = range (pos.fst) (pos.fst + l);
      in {
        path = foldl' f path (map (x: {
          fst = x;
          snd = pos.snd;
        }) xs);
        pos = pos // { fst = pos.fst + l; };
      };

    L = l:
      let xs = range (pos.fst - l) (pos.fst);
      in {
        path = foldl' f path (map (x: {
          snd = pos.snd;
          fst = x;
        }) xs);
        pos = pos // { fst = pos.fst - l; };
      };
  };

  advance = f: { path, pos }: { dir, len }: (move f path pos).${dir} len;

  incPath = o: m:
    recursiveUpdate o
    (setAttrByPath [ (toString m.fst) (toString m.snd) ] true);

  incPath' = o: m:
    let
      p = [ (toString m.fst) (toString m.snd) ];
      mn = if o ? "min" then o.min else 2000;
      m' = manhat m;
    in o // {
      min = if attrByPath p false o && mn > m' && m' != 0 then manhat m else mn;
    };
  # in if hasAttrByPath p o && (o.min or ) <= m' then builtins.trace (o.min or "missing") o // { min = m'; } else o;

  # Method 2: strings
  start2 = {
    path = [ "0,0" ];
    pos = "0,0";
  };

  i2p = a: b: "${toString a},${toString b}";

  move2 = p: l:
    let
      s = splitString "," p;
      x = toInt (elemAt s 0);
      y = toInt (elemAt s 1);
      mx = map (i2p x);
      my = map (flip i2p y);
    in {
      U = let xs = range y (y + l);
      in {
        path = mx xs;
        pos = i2p x (y + l);
      };
      D = let xs = range (y - l) y;
      in {
        path = mx xs;
        pos = i2p x (y - l);
      };
      R = let xs = range x (x + l);
      in {
        path = my xs;
        pos = i2p (x + l) y;
      };
      L = let xs = range (x - l) x;
      in {
        path = my xs;
        pos = i2p (x - l) y;
      };
    };

  advance2 = a: c:
    let move' = (move2 (a.pos) c.len).${c.dir};
    in move' // { path = a.path ++ move'.path; };

  strToPair = s: {
    fst = toInt (elemAt (splitString "," s) 0);
    snd = toInt (elemAt (splitString "," s) 1);
  };

in rec {
  path1 = elemAt rd 4;
  path2 = elemAt rd 5;

  # Method 1; using sets
  wire1 = foldl' (advance incPath) start path1;
  wire2 = foldl' (advance incPath') (wire1 // { pos = start.pos; }) path2;

  answer = minimum (map (l:
    if l == [ "0" "0" ] then
      1000
    else
      abs (toInt (elemAt l 0)) + abs (toInt (elemAt l 1))) (collect isList
        (mapAttrsRecursive const
          (filterAttrsRecursive (n: v: v != true) wire2.path))));

  # Method 2; using strings. FAR more efficient.
  wire12 = sort (a: b: a < b) (foldl' advance2 start2 path1).path;
  wire22 = sort (a: b: a < b) (foldl' advance2 start2 path2).path;

  wirez = consume 2000 wire12 wire22;
  wirezz = compareLists (a: b: if a < "z" && b < "z" then 0 else 1) wire12 wire22;

  # Seriously Nix? You can't iterate over long lists without barfing?
  lulwut = (lenthz 0 wire22) + (lenthz 0 wire12);

  answer2 = minimum (map (p:
    let p' = (strToPair p);
    in if p == "0,0" then 1000 else abs (p'.fst) + abs (p'.snd))
    (intersectLists wire12.path wire22.path));
}
