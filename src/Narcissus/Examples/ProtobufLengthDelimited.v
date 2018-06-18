Require Import
        Coq.ZArith.BinInt
        Coq.Strings.String
        Coq.Sets.Image
        Coq.Vectors.Vector
        Coq.omega.Omega
        Coq.Logic.Eqdep_dec.

Require Import
        Fiat.Common
        Fiat.CommonEx
        Fiat.Computation
        Fiat.Narcissus.Common.Specs
        Fiat.Narcissus.Common.Sig
        Fiat.Narcissus.Common.WordFacts
        Fiat.Narcissus.Common.ComposeIf
        Fiat.Narcissus.Common.ComposeOpt
        Fiat.Narcissus.BinLib.Core
        Fiat.Narcissus.BinLib.AlignedByteString
        Fiat.Narcissus.BinLib.AlignWord
        Fiat.Narcissus.BinLib.AlignedList
        Fiat.Narcissus.BinLib.AlignedDecoders
        Fiat.Narcissus.Formats.Option
        Fiat.Narcissus.Formats.FixListOpt
        Fiat.Narcissus.Formats.SizedListOpt
        Fiat.Narcissus.Formats.Bool
        Fiat.Narcissus.Formats.WordOpt
        Fiat.Narcissus.Formats.NatOpt
        Fiat.Narcissus.Formats.Vector
        Fiat.Narcissus.Formats.EnumOpt
        Fiat.Narcissus.Formats.SumTypeOpt
        Fiat.Narcissus.Formats.VarintOpt
        Fiat.Narcissus.Formats.StringOpt
        Fiat.Narcissus.Stores.EmptyStore
        Fiat.Narcissus.Automation.Solver.

Section LengthDelimited.

  Context {A : Type}.
  Context {B : Type}.
  Context {cache : Cache}.
  Context {cacheAddNat : CacheAdd cache nat}.
  Context {monoid : Monoid B}.
  Context {monoidUnit : QueueMonoidOpt monoid bool}.

  Variable A_predicate : A -> Prop.
  Variable A_predicate_rest : A -> B -> Prop.
  Variable A_format : FormatM A B.
  Variable A_decode : DecodeM A B.
  Variable A_cache_inv : CacheDecode -> Prop.
  Variable A_format_sz_eq : forall x b1 b2 ce1 ce1' ce2 ce2', A_format x ce1 ↝ (b1, ce1') ->
                                                         A_format x ce2 ↝ (b2, ce2') ->
                                                         bin_measure b1 = bin_measure b2.
  Variable A_format_byte : forall d b ce ce', A_format d ce ↝ (b, ce') -> bin_measure b mod 8 = 0.
  Variable A_decode_lt : forall b cd x b' cd', A_decode b cd = Some (x, b', cd') -> lt_B b' b.
  Variable A_decode_correct : CorrectDecoder monoid A_predicate A_predicate_rest A_format A_decode A_cache_inv.

  Variable Wf_bound : B.
  Variable Wf_decode : forall b, lt_B b Wf_bound -> CacheDecode -> option (A * B * CacheDecode).
  Variable Wf_decode_lt : forall b pf cd x b' cd', Wf_decode b pf cd = Some (x, b', cd') -> lt_B b' b.
  Variable Wf_decode_correct : CorrectDecoderWf monoid A_predicate A_predicate_rest A_format Wf_decode A_cache_inv.

  Definition PB_LengthDelimited_format
    : FormatM (list A) B :=
    (fun xs ce =>
       `(b1, ce1) <- SizedList_format A_format xs ce;
         `(b2, _) <- Varint_format (N.of_nat ((bin_measure b1) / 8)) ce;
         ret (mappend b2 b1, ce1))%comp.

  Definition PB_LengthDelimited_decode
    : DecodeM (list A) B :=
    fun b cd =>
      `(sz, b1, cd1) <- (`(x, b1, cd1) <- Varint_decode b cd;
                          Some (N.to_nat x, b1, cd1));
        SizedList_decode A_decode A_decode_lt
                         (sz * 8) b1 cd.

  Definition PB_LengthDelimitedWf_decode
    : forall b, lt_B b Wf_bound -> CacheDecode -> option (list A * B * CacheDecode).
  Proof.
    refine
      (fun b pf cd =>
         `(sz, b1, cd1) <- (`(x, b1, cd1) <- Decode_w_Measure_lt Varint_decode b cd Varint_decode_lt;
                           Some (N.to_nat x, b1, cd1));
         SizedListWf_decode Wf_bound Wf_decode Wf_decode_lt
                            (sz * 8) (proj1_sig b1) _ cd).
    abstract (destruct b1; simpl; unfold lt_B in *; omega).
  Defined.

  Local Arguments Nat.div : simpl never.
  Theorem PB_LengthDelimited_decode_correct
          (A_cache_inv_OK : cache_inv_Property A_cache_inv (fun P => forall b cd, P cd -> P (addD cd b)))
    : CorrectDecoder monoid
                     (fun xs => forall x, In x xs -> A_predicate x)
                     (SizedList_predicate_rest A_predicate_rest A_format)
                     PB_LengthDelimited_format PB_LengthDelimited_decode A_cache_inv.
  Proof.
    unfold PB_LengthDelimited_format, PB_LengthDelimited_decode.
    split; intros. {
      computes_to_inv2.
      pose proof (Varint_decode_correct (P:=A_cache_inv)) as Hv.
      eapply fun_compose_format_correct
        with (predicate:=fun _ => True) (predicate_rest:=fun _ _ => True) (im:=fun _ => true)
        in Hv.
      edestruct Hv as [[? [? [? ?]]] _]; eauto. clear H4 H5.
      edestruct (SizedList_decode_correct (A:=A)) as [[? [? [? ?]]] _]; try apply H2; eauto.
      intuition. eapply SizedList_format_sz_eq; eauto.
      eexists. repeat split; eauto.
      rewrite <- mappend_assoc. rewrite H3.
      simpl. rewrite Nat.mul_comm.
      assert (bin_measure b0 mod 8 = 0) as L. {
        eapply SizedList_format_byte; eauto.
      }
      apply Nat.div_exact in L; eauto. rewrite <- L; eauto.
      all : auto.
      intros. apply Nnat.Nat2N.id.
      intros. simpl. econstructor. intuition. symmetry. apply Nnat.N2Nat.id.
    } {
      decode_opt_to_inv.
      subst.
      pose proof (Varint_decode_correct (P:=A_cache_inv)) as Hv.
      eapply fun_compose_format_correct
        with (predicate:=fun _ => True) (predicate_rest:=fun _ _ => True) (im:=fun _ => true)
        in Hv.
      edestruct Hv as [_ [? [? [? [? [? [? ?]]]]]]]; eauto.
      rewrite H1. simpl. reflexivity.
      edestruct (SizedList_decode_correct (A:=A)) as [_ [? [? [? [? [? [[? ?] ?]]]]]]]; try apply H2; eauto.
      split; eauto.
      eexists _, _. repeat split; eauto.
      computes_to_econstructor; eauto.
      computes_to_econstructor; eauto.
      apply H11 in H9. simpl fst. rewrite H9. rewrite Nat.div_mul by auto. eauto.
      simpl fst. rewrite <- mappend_assoc. subst. reflexivity.
      all : auto.
      intros. apply Nnat.Nat2N.id.
      intros. simpl. econstructor. intuition. symmetry. apply Nnat.N2Nat.id.
    }
  Qed.

  Theorem PB_LengthDelimitedWf_decode_correct
          (A_cache_inv_OK : cache_inv_Property A_cache_inv (fun P => forall b cd, P cd -> P (addD cd b)))
    : CorrectDecoderWf monoid
                     (fun xs => forall x, In x xs -> A_predicate x)
                     (SizedList_predicate_rest A_predicate_rest A_format)
                     PB_LengthDelimited_format PB_LengthDelimitedWf_decode A_cache_inv.
  Proof.
    unfold PB_LengthDelimited_format, PB_LengthDelimitedWf_decode.
    split; intros. {
      computes_to_inv2.
      assert (lt_B (mappend b0 ext) Wf_bound) as pf'. {
        unfold lt_B in *. rewrite !mappend_measure in pf. rewrite mappend_measure. omega.
      }
      pose proof (Varint_decode_correct (P:=A_cache_inv)) as Hv.
      edestruct Hv as [[? [? [? ?]]] _]; eauto. clear H4 H5.
      edestruct (SizedListWf_decode_correct (A:=A)) as [[? [? [? ?]]] _]; try apply H2; eauto.
      intuition. eapply SizedList_format_sz_eq; eauto.
      eexists. repeat split; eauto.
      edestruct @Decode_w_Measure_lt_eq with (A_decode_lt:=Varint_decode_lt); eauto.
      revert pf. rewrite <- mappend_assoc. intros. rewrite H7.
      simpl. rewrite Nat.mul_comm.
      assert (bin_measure b0 mod 8 = 0) as L. {
        eapply SizedList_format_byte; eauto.
      }
      apply Nat.div_exact in L; eauto. rewrite Nnat.Nat2N.id.
      rewrite <- L; eauto.
      match goal with
      | H : SizedListWf_decode _ _ _ _ _ ?p _ = _ |- 
        SizedListWf_decode _ _ _ _ _ ?p' _ = _ =>
        replace p' with p
      end. apply H4.
      apply le_uniqueness_proof.
    } {
      decode_opt_to_inv.
      subst. apply Decode_w_Measure_lt_eq_inv in H1. destruct x3. simpl in H1.
      pose proof (Varint_decode_correct (P:=A_cache_inv)) as Hv.
      edestruct Hv as [_ [? [? [? [? [? [? ?]]]]]]]; eauto.
      edestruct (SizedListWf_decode_correct (A:=A)) as [_ [? [? [? [? [? [[? ?] ?]]]]]]]; try apply H2; eauto.
      split; eauto.
      eexists _, _. repeat split; eauto.
      computes_to_econstructor; eauto.
      computes_to_econstructor; eauto.
      apply H11 in H9. simpl fst. rewrite H9. rewrite Nat.div_mul by auto. rewrite Nnat.N2Nat.id. eauto.
      simpl fst. rewrite <- mappend_assoc. subst. simpl in *. congruence.
    }
    Grab Existential Variables.
    auto.
  Qed.

  Theorem PB_LengthDelimited_format_sz_eq
    : forall d b1 b2 ce1 ce1' ce2 ce2',
      PB_LengthDelimited_format d ce1 ↝ (b1, ce1') ->
      PB_LengthDelimited_format d ce2 ↝ (b2, ce2') ->
      bin_measure b1 = bin_measure b2.
  Proof.
    unfold PB_LengthDelimited_format. intros.
    computes_to_inv2. rewrite !mappend_measure.
    assert (bin_measure b4 = bin_measure b0). {
      eapply SizedList_format_sz_eq; eauto.
    }
    rewrite H1 in *.
    erewrite Varint_format_sz_eq; eauto.
  Qed.

  Theorem PB_LengthDelimited_decode_lt
    : forall b cd d b' cd',
      PB_LengthDelimited_decode b cd = Some (d, b', cd') -> lt_B b' b.
  Proof.
    unfold PB_LengthDelimited_decode. intros.
    decode_opt_to_inv.
    apply Varint_decode_lt in H.
    apply SizedList_decode_le in H0.
    unfold lt_B, le_B in *. subst. omega.
  Qed.

  Theorem PB_LengthDelimitedWf_decode_lt
    : forall b pf cd d b' cd',
      PB_LengthDelimitedWf_decode b pf cd = Some (d, b', cd') -> lt_B b' b.
  Proof.
    unfold PB_LengthDelimited_decode. intros.
    decode_opt_to_inv.
    apply Decode_w_Measure_lt_eq_inv in H. destruct x3, x0. simpl in *.
    apply SizedListWf_decode_le in H0.
    unfold lt_B, le_B in *. subst. omega.
  Qed.

End LengthDelimited.

Theorem PB_LengthDelimited_format_byte
        {A : Type} (A_format : FormatM A ByteString)
        (A_format_byte : forall d b ce ce', A_format d ce ↝ (b, ce') -> bin_measure b mod 8 = 0)
  : forall d b ce ce',
    PB_LengthDelimited_format A_format d ce ↝ (b, ce') ->
    bin_measure b mod 8 = 0.
Proof.
  unfold PB_LengthDelimited_format.
  intros. computes_to_inv2.
  rewrite @mappend_measure.
  rewrite <- Nat.add_mod_idemp_l by auto.
  rewrite <- Nat.add_mod_idemp_r by auto.
  erewrite Varint_format_byte; eauto.
  erewrite SizedList_format_byte; eauto.
Qed.