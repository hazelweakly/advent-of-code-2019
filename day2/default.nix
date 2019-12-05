{ pkgs ? import <nixpkgs> { } }:
with builtins;
with pkgs.lib;

let
  # "YoU cAn'T jUsT pArSe sHiT bY uSiNg jSoN fOr eVeRyThInG"
  vm = {
    pc = 0;
    program = fromJSON ("[" + readFile ./input + "]");
  };

  fix1202 = v@{ program, ... }:
    v // {
      program = write 2 2 (write 12 1 program);
    };

  read = n: xs: elemAt xs n;
  write = e: n: xs: (lists.take n xs) ++ [ e ] ++ (lists.drop (n + 1) xs);

  opMap = {
    "1" = ops.add;
    "2" = ops.mult;
    "99" = ops.halt;
  };

  load = { pc ? 0, program }:
    let
      op = lists.elemAt program (0 + pc);
      r0 = lists.elemAt program (1 + pc);
      r1 = lists.elemAt program (2 + pc);
      s = lists.elemAt program (3 + pc);
      program' = opMap."${toString op}" r0 r1 s program;
    in if op == 99 then {
      inherit pc program;
    } else {
      pc = pc + 4;
      program = program';
    };

  ops = {
    add = r0: r1: s: xs:
      let
        a = read r0 xs;
        b = read r1 xs;
        xs' = write (a + b) s xs;
      in xs';

    mult = r0: r1: s: xs:
      let
        a = read r0 xs;
        b = read r1 xs;
        xs' = write (a * b) s xs;
      in xs';

    halt = a: a;
  };

in { answer = { one = fixedPoints.converge load (fix1202 vm); }; }
