Require Import StringMap.
Require Import StringMapFacts.
Require Import FiatToFacade.Utilities.
Require Import FiatToFacade.StringMapNotations.

Lemma MapsTo_unique :
  forall {A} map key (v1 v2: A),
    StringMap.MapsTo key v1 map ->  
    StringMap.MapsTo key v2 map ->  
    v1 = v2.
Proof.
  intros;
  rewrite StringMapFacts.find_mapsto_iff in *;
  eq_transitive; autoinj; assumption.
Qed.

Lemma not_in_remove_eq :
  forall {elt} k m,
    ~ @StringMap.In elt k m ->
    StringMap.Equal 
      m (StringMap.remove k m).
Proof.
  unfold StringMap.Equal; intros ** k'.
  destruct (StringMap.E.eq_dec k k'); subst.

  rewrite StringMapFacts.not_in_find, StringMapFacts.remove_eq_o by trivial;
    reflexivity.

  rewrite StringMapFacts.remove_neq_o by trivial;
    reflexivity.
Qed.

Lemma not_in_empty :
  forall {elt} k,
    ~ @StringMap.In elt k ∅ .
Proof.
  intros ** _in; rewrite <- StringMapFacts.empty_in_iff; eassumption.
Qed.

Lemma mapsto_eq_add :
  forall {elt} m k (v: elt) m',
    StringMap.Equal m ([k >> v]::m') ->
    m[k >> v].
Proof.
  intros * h; rewrite h; StringMapFacts.map_iff; intuition.
Qed.

Ltac mapsto_eq_add :=
  match goal with
    | [ H: StringMap.Equal _ _ |- _ ] =>
      let H' := fresh in
      pose proof H as H';
        apply mapsto_eq_add in H'
  end.

Ltac remove_not_in :=
  match goal with
    | [ H: ~ StringMap.In ?k ?m, H': context[StringMap.remove ?k ?m] |- _] =>
      setoid_rewrite <- (not_in_remove_eq k m H) in H'
  end.
 
Ltac subst_find :=
  match goal with 
    | [H: StringMap.find ?a ?b = _, 
       H': context[StringMap.find ?a ?b] |- _] =>
      setoid_rewrite H in H'
    | [H: StringMap.find ?a ?b = _
       |- context[StringMap.find ?a ?b]] =>
      setoid_rewrite H
    | [H: StringMap.MapsTo ?k ?v ?m, 
       H': context[StringMap.find ?k ?m] |- _] =>
      rewrite StringMapFacts.find_mapsto_iff in H;
        setoid_rewrite H in H';
        rewrite <- StringMapFacts.find_mapsto_iff in H
    | [H : StringMap.MapsTo ?k ?v ?m
       |- context[StringMap.find ?k ?m]] =>
      rewrite StringMapFacts.find_mapsto_iff in H;
        setoid_rewrite H;
        rewrite <- StringMapFacts.find_mapsto_iff in H
  end. (* TODO: use instead of calling StringMapFacts.find_mapsto_iff everywhere. *)

Ltac map_iff_solve' fallback :=
  repeat setoid_rewrite not_or;
  match goal with
    | [ |- ?A /\ ?B ] => split; map_iff_solve' fallback
    | [ |- (?a = ?a /\ _) \/ (?a <> ?a /\ _) ] => left; split; [ apply eq_refl | map_iff_solve' fallback ]
    | [ |- (?a = ?b /\ _) \/ (?a <> ?b /\ _) ] => right; split; [ congruence | map_iff_solve' fallback ]
    | _ => fallback
  end.

Ltac map_iff_solve fallback :=
  StringMapFacts.map_iff;
  map_iff_solve' fallback.

Ltac map_iff_solve_evar' fallback :=
  repeat setoid_rewrite not_or;
  match goal with
    | |- ?A /\ ?B => split; map_iff_solve_evar' fallback
    | |- ?a = ?ev /\ ?b = ?b \/ ?a <> ?ev /\ _ =>
      is_evar ev; left; split; [ apply eq_refl | reflexivity ]
    | |- ?a = ?a /\ _ \/ ?a <> ?a /\ _ =>
      left; split; [ apply eq_refl | map_iff_solve_evar' fallback ]
    | |- ?a = ?b /\ _ \/ ?a <> ?b /\ _ =>
      right; split; [ | map_iff_solve_evar' fallback ]; congruence
    | _ => fallback
  end.

Ltac map_iff_solve_evar fallback :=
  StringMapFacts.map_iff; map_iff_solve_evar' fallback.

Ltac auto_mapsto_unique :=
  try rewrite <- StringMapFacts.find_mapsto_iff in *;
  repeat progress match goal with
                    | [H: StringMap.MapsTo ?k ?v ?st, H': StringMap.MapsTo ?k ?v' ?st |- _] =>
                      let h := fresh in
                      pose proof (MapsTo_unique st k v v' H H') as h;
                        first [discriminate | injection h; clear H]
                  end.

Ltac simpl_find_add_remove :=
  match goal with
    | [ |- context[StringMap.find ?k (StringMap.remove ?k ?m)] ] =>
      rewrite (@StringMapFacts.remove_eq_o _ m k k) by reflexivity
    | [ H: ?k <> ?k' |- context[StringMap.find ?k (StringMap.remove ?k' ?m)] ] =>
      rewrite (@StringMapFacts.remove_neq_o _ m k' k) by congruence
    | [ H: ?k' <> ?k |- context[StringMap.find ?k (StringMap.remove ?k' ?m)] ] =>
      rewrite (@StringMapFacts.remove_neq_o _ m k' k) by congruence
    | [ |- context[StringMap.find ?k (StringMap.add ?k ?v ?m)] ] =>
      rewrite (@StringMapFacts.add_eq_o _ m k k v (eq_refl _)) by reflexivity
    | [ H: ?k' <> ?k |- context[StringMap.find ?k (StringMap.add ?k' ?v ?m)] ] =>
      rewrite (@StringMapFacts.add_neq_o _ m k' k v) by congruence
    | [ H: ?k <> ?k' |- context[StringMap.find ?k (StringMap.add ?k' ?v ?m)] ] =>
      rewrite (@StringMapFacts.add_neq_o _ m k' k v) by congruence
    | [ |- context[StringMap.find ?k (StringMap.empty _)] ] =>
      rewrite (StringMapFacts.empty_o _ k)
  end.

Lemma StringMap_remove_add_neq :
  forall {elt} {k1 k2 v} (map: StringMap.t elt),
    k1 <> k2 ->
    StringMap.Equal (StringMap.remove k2 (StringMap.add k1 v map)) (StringMap.add k1 v (StringMap.remove k2 map)).
Proof.
  unfold StringMap.Equal; intros ** k'.
  destruct (StringMap.E.eq_dec k' k1), (StringMap.E.eq_dec k' k2);
    subst; repeat simpl_find_add_remove; congruence.
Qed.

Lemma StringMap_remove_add_eq :
  forall {elt} {k1 k2 v} (map: StringMap.t elt),
    k1 = k2 ->
    StringMap.Equal (StringMap.remove k2 (StringMap.add k1 v map)) (StringMap.remove k2 map).
Proof.
  unfold StringMap.Equal; intros ** k'.
  destruct (StringMap.E.eq_dec k' k1), (StringMap.E.eq_dec k' k2);
    subst; repeat simpl_find_add_remove; congruence.
Qed.

Lemma StringMap_remove_empty :
  forall {elt : Type} (k : StringMap.key),
    StringMap.Equal (StringMap.remove (elt:=elt) k ∅) ∅ .
Proof.
  unfold StringMap.Equal; intros ** k'.
  destruct (StringMap.E.eq_dec k' k);
    subst; repeat simpl_find_add_remove; congruence.
Qed.

Ltac trickle_deletion :=
  repeat match goal with
           | [ |- context[StringMap.remove ?k (StringMap.add ?k' ?v ?m)] ] =>
             first [ rewrite (@StringMap_remove_add_eq _ k' k) by congruence |
                     rewrite (@StringMap_remove_add_neq _ k' k) by congruence ]
           | [ |- context[StringMap.remove _ ∅] ] => rewrite StringMap_remove_empty
         end.
     
Lemma MapsTo_swap :
  forall {elt} {k1 k2 v1 v2} {map: StringMap.t elt},
    k1 <> k2 ->
    forall k v,
      ([k1 >> v1]::[k2 >> v2]::map)[k >> v] <->
      ([k2 >> v2]::[k1 >> v1]::map)[k >> v].
Proof.
  intros; StringMapFacts.map_iff.
  destruct (StringMap.E.eq_dec k k1) as [ eq0 | neq0 ];
    destruct (StringMap.E.eq_dec k k2) as [ eq1 | neq1 ];
    try rewrite !eq0 in *;
    try rewrite !eq1 in *;
    split; intros;
    map_iff_solve' idtac;
    intuition.
Qed.

Lemma add_add_add :
  forall {elt} st k v,
    @StringMap.Equal elt
                     ([k >> v]::[k >> v]::st)
                     ([k >> v]::st).
Proof.
  intros; unfold StringMap.Equal;
  intros k'; destruct (StringMap.E.eq_dec k k'); subst.
  repeat rewrite StringMapFacts.add_eq_o; reflexivity.
  repeat rewrite StringMapFacts.add_neq_o; congruence.
Qed.

Lemma add_add_add' :
  forall {elt} st k v v',
    @StringMap.Equal elt
                     ([k >> v]::[k >> v']::st)
                     ([k >> v]::st).
Proof.
  intros; unfold StringMap.Equal;
  intros k'; destruct (StringMap.E.eq_dec k k'); subst.
  repeat rewrite StringMapFacts.add_eq_o; reflexivity.
  repeat rewrite StringMapFacts.add_neq_o; congruence.
Qed.

Lemma add_noop :
  forall {A: Type} {k: StringMap.key} {v: A} {map},
    StringMap.find k map = Some v ->
    StringMap.Equal (StringMap.add k v map) map.
Proof.
  unfold StringMap.Equal; intros ** k';
  destruct (StringMap.E.eq_dec k k');
  subst;
  [ rewrite StringMapFacts.add_eq_o | rewrite StringMapFacts.add_neq_o ];
  auto.
Qed.

Lemma MapsTo_swap_Eq :
  forall {elt} k1 v1 k2 v2 map,
    k1 <> k2 ->
    @StringMap.Equal elt
                     ([k1 >> v1]::[k2 >> v2]::map)
                     ([k2 >> v2]::[k1 >> v1]::map).
Proof.
  intros; apply StringMapFacts.Equal_mapsto_iff.
  eauto using MapsTo_swap.
Qed.
