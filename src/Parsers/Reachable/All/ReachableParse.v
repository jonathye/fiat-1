(** * Every parse tree has a corresponding minimal parse tree *)
Require Import Coq.Program.Basics.
Require Import Coq.Strings.String Coq.Lists.List Coq.Setoids.Setoid Coq.Classes.RelationClasses Coq.Classes.Morphisms.
Require Import Fiat.Parsers.ContextFreeGrammar.Core.
Require Import Fiat.Parsers.ContextFreeGrammar.Properties.
Require Import Fiat.Parsers.StringLike.ForallChars.
Require Import Fiat.Parsers.Reachable.All.Reachable.
Require Import Fiat.Parsers.Reachable.All.MinimalReachable.
Require Import Fiat.Parsers.BaseTypes.
Require Import Fiat.Parsers.BaseTypesLemmas.
Require Import Fiat.Parsers.Reachable.All.Reachable.
Require Import Fiat.Parsers.Reachable.All.MinimalReachableOfReachable.
Require Import Fiat.Common.

Set Implicit Arguments.
Local Open Scope string_like_scope.

Section cfg.
  Context {Char} {HSL : StringLike Char} {HSLP : StringLikeProperties Char} {G : grammar Char}.
  Context {predata : parser_computational_predataT}
          {rdata' : @parser_removal_dataT' _ G predata}.

  Definition forall_chars_reachable_from_parse_of_item'
             (forall_chars_reachable_from_parse_of_productions
              : forall valid0 pats
                       (str : String) (p : parse_of G str pats)
                       (Hforall : Forall_parse_of (fun _ nt' => is_valid_nonterminal valid0 nt') p),
                  forall_chars str (fun ch => inhabited (reachable_from_productions G ch valid0 pats)))
             {valid0 it}
             (str : String) (p : parse_of_item G str it)
             (Hforall : Forall_parse_of_item (fun _ nt' => is_valid_nonterminal valid0 nt') p)
  : forall_chars str (fun ch => inhabited (reachable_from_item G ch valid0 it)).
  Proof.
    destruct p as [ | nt ? p ].
    { rewrite <- forall_chars_singleton by eassumption.
      repeat constructor. }
    { specialize (forall_chars_reachable_from_parse_of_productions valid0 (G nt) str p (snd Hforall)).
      revert forall_chars_reachable_from_parse_of_productions.
      apply forall_chars_Proper; [ reflexivity | intros ? [H'] ].
      constructor.
      constructor; simpl in *; [ exact (fst Hforall) | assumption ]. }
  Defined.

  Fixpoint forall_chars_reachable_from_parse_of_productions
             {valid0 pats}
             (str : String) (p : parse_of G str pats)
             (Hforall : Forall_parse_of (fun _ nt' => is_valid_nonterminal valid0 nt') p)
             {struct p}
  : forall_chars str (fun ch => inhabited (reachable_from_productions G ch valid0 pats))
  with forall_chars_reachable_from_parse_of_production
         {valid0 pat}
         (str : String) (p : parse_of_production G str pat)
         (Hforall : Forall_parse_of_production (fun _ nt' => is_valid_nonterminal valid0 nt') p)
         {struct p}
       : forall_chars str (fun ch => inhabited (reachable_from_production G ch valid0 pat)).
  Proof.
    { destruct p as [ ?? p | ?? p ]; simpl in *.
      { generalize (forall_chars_reachable_from_parse_of_production valid0 _ _ p Hforall).
        apply forall_chars_Proper; [ reflexivity | intros ? [H']; constructor ].
        left; assumption. }
      { generalize (forall_chars_reachable_from_parse_of_productions valid0 _ _ p Hforall).
        apply forall_chars_Proper; [ reflexivity | intros ? [H']; constructor ].
        right; assumption. } }
    { destruct p as [ | ?? p ]; simpl in *.
      { apply forall_chars_nil; assumption. }
      { rewrite forall_chars__split; split.
        { generalize (@forall_chars_reachable_from_parse_of_item' forall_chars_reachable_from_parse_of_productions valid0 _ _ _ (fst Hforall)).
          apply forall_chars_Proper; [ reflexivity | intros ? [H']; constructor ].
          left; assumption. }
        { generalize (@forall_chars_reachable_from_parse_of_production valid0 _ _ _ (snd Hforall)).
          apply forall_chars_Proper; [ reflexivity | intros ? [H']; constructor ].
          right; assumption. } } }
  Defined.

  Definition forall_chars_reachable_from_parse_of_item
             {valid0 it}
             (str : String) (p : parse_of_item G str it)
             (Hforall : Forall_parse_of_item (fun _ nt' => is_valid_nonterminal valid0 nt') p)
  : forall_chars str (fun ch => inhabited (reachable_from_item G ch valid0 it))
    := @forall_chars_reachable_from_parse_of_item' (@forall_chars_reachable_from_parse_of_productions) valid0 it str p Hforall.

  Definition forall_chars_minimal_reachable_from_parse_of_item
             {valid0 it}
             (str : String) (p : parse_of_item G str it)
             (Hforall : Forall_parse_of_item (fun _ nt' => is_valid_nonterminal valid0 nt') p)
  : forall_chars str (fun ch => inhabited (minimal_reachable_from_item (G := G) ch valid0 it)).
  Proof.
    setoid_rewrite <- minimal_reachable_from_item__iff__reachable_from_item.
    eapply forall_chars_reachable_from_parse_of_item; eassumption.
  Qed.

  Definition forall_chars_minimal_reachable_from_parse_of_production
             {valid0 pat}
             (str : String) (p : parse_of_production G str pat)
             (Hforall : Forall_parse_of_production (fun _ nt' => is_valid_nonterminal valid0 nt') p)
  : forall_chars str (fun ch => inhabited (minimal_reachable_from_production (G := G) ch valid0 pat)).
  Proof.
    setoid_rewrite <- minimal_reachable_from_production__iff__reachable_from_production.
    eapply forall_chars_reachable_from_parse_of_production; eassumption.
  Qed.

  Definition forall_chars_minimal_reachable_from_parse_of_productions
             {valid0 pats}
             (str : String) (p : parse_of G str pats)
             (Hforall : Forall_parse_of (fun _ nt' => is_valid_nonterminal valid0 nt') p)
  : forall_chars str (fun ch => inhabited (minimal_reachable_from_productions (G := G) ch valid0 pats)).
  Proof.
    setoid_rewrite <- minimal_reachable_from_productions__iff__reachable_from_productions.
    eapply forall_chars_reachable_from_parse_of_productions; eassumption.
  Qed.
End cfg.
