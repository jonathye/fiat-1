(** * Definition of Context Free Grammars *)
Require Import Coq.Strings.String Coq.Lists.List Coq.Program.Program.
Require Export Fiat.Parsers.StringLike.Core.
Require Import Fiat.Parsers.ContextFreeGrammar.
Require Import Fiat.Parsers.BaseTypes.

Set Implicit Arguments.

Local Open Scope string_like_scope.
Local Open Scope type_scope.

Section cfg.
  Context {Char : Type} {HSL : StringLike Char} (G : grammar Char)
          {predata : parser_computational_predataT}.

  Definition item_valid (it : item Char)
    := match it with
         | Terminal _ => True
         | NonTerminal nt' => is_true (is_valid_nonterminal initial_nonterminals_data nt')
       end.

  Definition production_valid pat
    := List.Forall item_valid pat.

  Definition productions_valid pats
    := List.Forall production_valid pats.

  Definition grammar_valid
    := forall nt, is_true (is_valid_nonterminal initial_nonterminals_data nt)
                  -> productions_valid (Lookup G nt).
End cfg.
