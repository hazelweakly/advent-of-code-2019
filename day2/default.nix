{ pkgs ? import <nixpkgs> { } }:
with builtins;
with pkgs.lib;

let
  # "YoU cAn'T jUsT pArSe sHiT bY uSiNg jSoN fOr eVeRyThInG"
  vm = {
    pc = 0;
    mem = fromJSON ("[" + readFile ./input + "]");
  };

  fix1202 = { noun ? 12, verb ? 2, mem, ... }: {
    mem = write verb 2 (write noun 1 mem);
  };

  read = n: xs: elemAt xs n;
  write = e: n: xs: (lists.take n xs) ++ [ e ] ++ (lists.drop (n + 1) xs);

  opMap = {
    "1" = ops.add;
    "2" = ops.mult;
    "99" = ops.halt;
  };

  load = vm@{ pc ? 0, mem }:
    let
      op = lists.elemAt mem pc;
      lp = i:
        if length mem >= i then {
          "p${toString (i - 1)}" = lists.elemAt mem (pc + i);
        } else
          { };
    in opMap.${toString op} (vm // lp 1 // lp 2 // lp 3);

  binOp = f:
    { pc, p0, p1, p2, mem }:
    let
      a1 = read p0 mem;
      a2 = read p1 mem;
    in {
      pc = pc + 4;
      mem = write (f a1 a2) p2 mem;
    };

  ops = {
    add = binOp (a: b: a + b);
    mult = binOp (a: b: a * b);
    halt = { pc, mem, ... }: { inherit pc mem; };
  };

  inputs = lists.crossLists (noun: verb: { inherit noun verb; }) [
    (lists.range 0 99)
    (lists.range 0 99)
  ];

  run = args:
    let vm' = fixedPoints.converge load (vm // fix1202 (vm // args));
    in { result = lists.elemAt vm'.mem 0; } // args;

in {
  answer = {
    one = (run {
      noun = 12;
      verb = 2;
    }).result;
    two = let
      result = lists.findFirst (x: x.result == 19690720) (abort "impossible")
        (map run inputs);
    in 100 * result.noun + result.verb;
  };
}
