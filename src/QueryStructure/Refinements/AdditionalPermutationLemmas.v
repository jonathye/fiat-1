Require Export Permutation.
Require Import AdditionalLemmas List.

Unset Implicit Arguments.

Lemma NoDup_Permutation_rewrite {A} :
  forall (l l' : list A),
    Permutation l l' -> NoDup l -> NoDup l'.
Proof.
  intros; induction H.
  + econstructor.
  + inversion H0; subst; econstructor; eauto.
    unfold not; intros; apply H3; apply Permutation_sym in H;
    eapply Permutation_in; eauto.
  + inversion H0; subst; inversion H3; subst; repeat econstructor; eauto.
    * unfold not; intros; destruct H; eauto.
      apply H2; econstructor; eauto.
    * unfold not; intros; apply H2; econstructor 2; eauto.
  + eauto.
Qed.

Lemma NoDup_modulo_permutation :
  forall {A} (seq: list A),
    NoDup seq <-> (exists seq', NoDup seq' /\ Permutation seq seq').
Proof.
  split; intros * H;
  [ exists seq; intuition | ].
  destruct H as [ seq' (no_dup & perm) ].
  symmetry in perm.
  eapply NoDup_Permutation_rewrite; eauto.
Qed.

Lemma NoDup_slice :
  forall {A} a b c,
    @NoDup A (a ++ b ++ c) -> NoDup (a ++ c).
Proof.
  induction b; simpl; intros.
  - trivial.
  - apply IHb.
    eapply NoDup_remove_1; eauto.
Qed.

Lemma NoDup_app_inv :
  forall {A} a b,
    @NoDup A (a ++ b) ->
    forall x,
      List.In x a -> ~ List.In x b.
Proof.
  intros * no_dup * in_a.
  apply in_split in in_a.
  destruct in_a as [ a1 [ a2 _eq ] ]; subst.
  rewrite <- app_assoc, <- app_comm_cons in no_dup.
  apply NoDup_remove_2 in no_dup.
  repeat rewrite in_app_iff in no_dup; intuition.
Qed.

Lemma NoDup_app_swap :
  forall {A} a b,
    @NoDup A (a ++ b) ->
    @NoDup A (b ++ a).
Proof.
  intros.
  eapply NoDup_Permutation_rewrite; try apply Permutation_app_comm; assumption.
Qed.

Lemma NoDup_app_inv' :
  forall {A} a b c,
    @NoDup A (a ++ b ++ c) ->
    forall x,
      List.In x a \/ List.In x c -> ~ List.In x b.
Proof.
  intros * no_dup * [ in_a | in_c ];
  [ | rewrite app_assoc in no_dup; apply NoDup_app_swap in no_dup ];
  eapply NoDup_app_inv in no_dup; eauto;
  intuition.
Qed.

Lemma permutation_cons_in :
  forall {A} {s1 s2 item},
    Permutation (s1) (item :: s2) ->
    @List.In A item s1.
Proof.
  intros.
  eapply Permutation_in;
    try symmetry; eauto; intuition.
Qed.

Lemma permutation_map :
  forall {A B} f seq seq',
    Permutation seq' (@map A B f seq) ->
    exists seq0,
      seq' = map f seq0.
Proof.
  induction seq; simpl; intros.

  exists (@nil A); eauto.
  symmetry in H; apply Permutation_nil in H; subst; trivial.

  pose proof (permutation_cons_in H) as f_in.
  apply in_split in f_in.
  destruct f_in as [ l1 [ l2 f_in ] ].
  subst.

  rewrite <- Permutation_middle in H.
  apply Permutation_cons_inv in H.
  specialize (IHseq _ H).
  destruct IHseq as [ seq0 IHseq ].

  apply app_map_inv in IHseq.
  destruct IHseq as [ l1' [ l2' (seq0_eq_app & l1l1' & l2l2') ] ].

  exists (l1' ++ a :: l2').
  rewrite map_app.
  simpl.
  subst; intuition.
Qed.

Lemma permutation_map_base :
  forall {A} {B} (f: B -> A) {shuffled: list A} {l1},
    Permutation shuffled l1 ->
    forall l1',
      List.map f l1' = l1 ->
      exists l',
        List.map f l' = shuffled /\
        Permutation l' l1'.
Proof.
  induction shuffled; simpl; intros.

  apply Permutation_nil in H; subst.
  apply map_eq_nil in H0; subst.
  exists (@nil B); simpl; intuition.

  symmetry in H.
  pose proof (permutation_cons_in H) as in_l1.
  apply in_split in in_l1.
  destruct in_l1 as [ l2 [ l3 l1_split ] ].
  rewrite l1_split in H, H0; clear l1_split l1.
  rewrite <- Permutation_middle in H.
  apply Permutation_cons_inv in H.
  symmetry in H.
  specialize (IHshuffled _ H).

  symmetry in H0.
  apply app_map_inv in H0.
  destruct H0 as [ l2' [ l3' (l1'_app & l2l2' & l3l3') ] ].
  apply cons_map_inv in l3l3'.
  destruct l3l3' as [ a' [ l3'' ( ? &  ? & ?) ] ]; subst.
  specialize (IHshuffled (l2' ++ l3'')); rewrite map_app in IHshuffled.
  specialize (IHshuffled eq_refl).
  destruct IHshuffled as [ l' (map_eq & perm) ].
  exists (a' :: l'); subst; simpl.
  rewrite <- Permutation_middle; split; eauto.
Qed.

Lemma permutation_map_app :
  forall {A} {B} (f: B -> A) {l1 l2} {shuffled: list A},
    Permutation shuffled (l1 ++ l2) ->
    forall l1' l2',
      List.map f l1' = l1 ->
      List.map f l2' = l2 ->
      exists l',
        List.map f l' = shuffled /\
        Permutation l' (l1' ++ l2').
Proof.
  induction l2; simpl; intros.

  eapply permutation_map_base; eauto.
  rewrite map_app; f_equal; assumption.

  symmetry in H1. apply cons_map_inv in H1.
  destruct H1 as [ a' [ l2'' ( ? & ? & ? ) ] ]; subst.
  rewrite <- Permutation_middle in H.
  pose proof (permutation_cons_in H) as f_in.
  apply in_split in f_in.
  destruct f_in as [ s1 [ s2 ? ] ]; subst.
  rewrite <- Permutation_middle in H.
  apply Permutation_cons_inv in H.

  specialize (IHl2 _ H l1' l2'' eq_refl eq_refl).
  destruct IHl2 as [l' (map_eq & perm)].
  symmetry in map_eq.
  apply app_map_inv in map_eq.
  destruct map_eq as [ l1'' [ l2''' ( ? & ? & ? ) ] ]; subst.
  exists (l1'' ++ a' :: l2''').
  rewrite map_app; simpl.
  split; [ trivial | ].
  repeat rewrite <- Permutation_middle; eauto.
Qed.

Require Import Program.

Lemma permutation_map_cons :
  forall {A} {B} (f: B -> A) {x1 l2} {shuffled: list A},
    Permutation shuffled (x1 :: l2) ->
    forall x1' l2',
      f x1' = x1 ->
      List.map f l2' = l2 ->
      exists l',
        List.map f l' = shuffled /\
        Permutation l' (x1' :: l2').
Proof.
  intros.
  replace (x1' :: l2') with ([x1'] ++ l2') by reflexivity.
  subst; eapply permutation_map_app; eauto; simpl; assumption.
Qed.

Lemma permutation_singleton :
  forall {A} seq x,
    @Permutation A seq [x] -> seq = [x].
Proof.
  induction seq; simpl; intros.

  apply Permutation_nil in H; intuition.
  pose proof (Permutation_length H) as len; simpl in len.
  inversion len.
  destruct seq; simpl in *; try discriminate.
  apply Permutation_length_1 in H; congruence.
Qed.

Require Import SetoidList.

Lemma InA_app_swap {A} eqA :
  Equivalence eqA
  -> forall (a : A) l l',
       InA eqA a (l ++ l') -> InA eqA a (l' ++ l).
Proof.
  intros; eapply InA_app_iff;
  eapply InA_app_iff in H0; eauto; intuition.
Qed.

Lemma InA_app_cons_swap {A} eqA :
  Equivalence eqA
  -> forall (a a' : A) l l',
       InA eqA a (l ++ (a' :: l')) <-> InA eqA a ((a' :: l) ++ l').
Proof.
  split; intros.
  - eapply InA_app_swap; eauto.
    intros; eapply InA_app_iff;
    eapply InA_app_iff in H0; eauto; intuition.
    inversion H; subst; eauto.
  - eapply InA_app_swap; eauto.
    intros; eapply InA_app_iff;
    eapply InA_app_iff in H0; eauto; intuition.
    inversion H; subst; eauto.
Qed.
