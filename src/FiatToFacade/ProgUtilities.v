Require Import Superset.
Require Import StringMap.

Ltac rewrite_Eq_in_goal :=
  match goal with
    | [ H: StringMap.Equal _ _ |- SomeSCAs _ _ ] =>
      rewrite H
    | [ H: StringMap.Equal _ _ |- AllADTs _ _ ] =>
      rewrite H
    | [ H: StringMap.Equal _ _ |- StringMap.MapsTo _ _ _ ] =>
      rewrite H              
  end.
