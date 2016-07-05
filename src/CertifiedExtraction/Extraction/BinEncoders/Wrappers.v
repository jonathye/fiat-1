Require Import Coq.Program.Program.

Require Import
        Fiat.CertifiedExtraction.Core
        Fiat.CertifiedExtraction.FacadeWrappers.
Require Import
        Fiat.CertifiedExtraction.Extraction.BinEncoders.Basics
        Fiat.CertifiedExtraction.Extraction.BinEncoders.Properties
        Fiat.CertifiedExtraction.Extraction.BinEncoders.Map8.
Require Import
        Bedrock.Arrays.
Require Export
        Bedrock.Platform.Facade.examples.QsADTs.
Require Import Bedrock.Word.

Unset Implicit Arguments.

Definition AsciiToByte (a: Ascii.ascii) : B :=
  match a with
  | Ascii.Ascii x x0 x1 x2 x3 x4 x5 x6 =>
    Word.WS x (Word.WS x0 (Word.WS x1 (Word.WS x2 (Word.WS x3 (Word.WS x4 (Word.WS x5 (Word.WS x6 Word.WO)))))))
  end.

Lemma AsciiToByte_ByteToAscii :
  forall a, (ByteToAscii (AsciiToByte a)) = a.
Proof.
  destruct a; reflexivity.
Qed.

Lemma whd_wtl {n} :
  forall w: word (S n), w = WS (whd w) (wtl w).
Proof.
  intros.
  destruct (shatter_word_S w) as (b & w' & p).
  rewrite p; reflexivity.
Qed.

Lemma ByteToAscii_AsciiToByte :
  forall b, (AsciiToByte (ByteToAscii b)) = b.
Proof.
  intros; unfold ByteToAscii.
  shatter_word b; reflexivity.
Qed.

Lemma AsciiToByte_inj :
  forall a1 a2,
    AsciiToByte a1 = AsciiToByte a2 ->
    a1 = a2.
Proof.
  intros.
  rewrite <- (AsciiToByte_ByteToAscii a1), <- (AsciiToByte_ByteToAscii a2), H; reflexivity.
Qed.

Fixpoint StringToByteString s :=
  match s with
  | EmptyString => nil
  | String hd tl => cons (AsciiToByte hd) (StringToByteString tl)
  end.

Lemma StringToByteString_inj :
  forall s1 s2,
    StringToByteString s1 = StringToByteString s2 ->
    s1 = s2.
Proof.
  induction s1; destruct s2;
    repeat match goal with
           | _ => congruence
           | _ => progress intros
           | _ => progress simpl in *
           | _ => progress f_equal
           | _ => solve [eauto using AsciiToByte_inj]
           | [ H: cons _ _ = cons _ _ |- _ ] => inversion H; subst; clear H
           end.
Qed.

Lemma WrapString_inj {capacity} :
  forall v v' : string,
    ByteString capacity (StringToByteString v) =
    ByteString capacity (StringToByteString v') ->
    v = v'.
Proof.
  inversion 1; eauto using StringToByteString_inj.
Qed.

Definition WrapString {capacity: W} : FacadeWrapper ADTValue string :=
  {| wrap x := ByteString capacity (StringToByteString x);
     wrap_inj := WrapString_inj |}.

Lemma WrapListByte_inj {capacity} :
  forall v v' : byteString,
    ByteString capacity v = ByteString capacity v' ->
    v = v'.
Proof.
  inversion 1; eauto.
Qed.

Instance WrapListByte {capacity: W} : FacadeWrapper ADTValue byteString :=
  {| wrap bs := ByteString capacity bs;
     wrap_inj := WrapListByte_inj |}.

Open Scope nat_scope.

Lemma pow2_weakly_monotone : forall n m: nat,
    (n <= m)
    -> (pow2 n <= pow2 m).
Proof.
  induction 1; simpl; intuition.
Qed.

Lemma BoundedN_below_pow2__le32 {size}:
  (size <= 32) ->
  forall v : BoundedN size,
    (lt (N.to_nat (proj1_sig v)) (pow2 32)).
Proof.
  intros; eapply Lt.lt_le_trans;
    eauto using BoundedN_below_pow2, pow2_weakly_monotone, BoundedN_below_pow2.
Qed.

Lemma WrapN_le32_inj {av} {size}:
  (size <= 32) ->
  forall v v' : BoundedN size,
    wrap (FacadeWrapper := @FacadeWrapper_SCA av) (NToWord 32 (` v)) =
    wrap (FacadeWrapper := @FacadeWrapper_SCA av) (NToWord 32 (` v')) ->
    v = v'.
Proof.
  intros; rewrite !NToWord_nat in H0.
  apply wrap_inj, natToWord_inj, N2Nat.inj in H0;
  eauto using exist_irrel', UipComparison.UIP, BoundedN_below_pow2__le32.
Qed.

Definition WrapN_le32 {av} (n: nat) (p: n <= 32) : FacadeWrapper (Value av) (BoundedN n) :=
  {| wrap x := wrap (NToWord 32 (` x));
     wrap_inj := WrapN_le32_inj p |}.

Definition WrapN_error {av} (n: nat) : (if Compare_dec.le_dec n 32 then
                                        FacadeWrapper (Value av) (BoundedN n)
                                      else True).
  destruct (Compare_dec.le_dec n 32); auto using WrapN_le32.
Defined.

Instance WrapN8 : FacadeWrapper (Value ADTValue) (BoundedN 8) := WrapN_error 8.
Instance WrapN16 : FacadeWrapper (Value ADTValue) (BoundedN 16) := WrapN_error 16.
