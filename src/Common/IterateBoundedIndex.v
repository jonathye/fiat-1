Require Import Coq.Arith.Arith Coq.Lists.List Coq.Sets.Ensembles Coq.Strings.String ADTSynthesis.Common
        ADTSynthesis.Common.ilist ADTSynthesis.Common.StringBound ADTSynthesis.Common.DecideableEnsembles.

Fixpoint app_assoc {A : Set} (As As' As'' : list A):
  As ++ (As' ++ As'') = (As ++ As') ++ As'' :=
  match As as As return
        As ++ (As' ++ As'') = (As ++ As') ++ As'' with
    | nil => eq_refl _
    | a :: As => (f_equal (fun l => a :: l) (app_assoc As As' As''))
  end.

Lemma app_comm_cons' {A : Set}:
  forall (a : A) As As',
    As ++ (a :: As') = (As ++ (a :: nil)) ++ As'.
Proof.
  intros; rewrite <- app_assoc; reflexivity.
Defined.

Section Iterate_Ensemble.

  Definition Ensemble_BoundedIndex_app_comm_cons {A : Set}
             (a : A)
             (As As' : list A)
             (P : Ensemble (BoundedIndex (As ++ a :: As')))
  : Ensemble (BoundedIndex ((As ++ (a :: nil)) ++ As')).
    rewrite app_comm_cons' in P; exact P.
  Defined.

  Definition BoundedIndex_app_comm_cons {A : Set}
             (a : A)
             (As As' : list A)
             (a' : BoundedIndex (As ++ a :: As'))
  : BoundedIndex ((As ++ (a :: nil)) ++ As').
    rewrite app_comm_cons' in a'; exact a'.
  Defined.

  Lemma ibound_BoundedIndex_app_comm_cons {A : Set}
        (a : A)
        (As As' : list A)
        (a' : BoundedIndex (As ++ a :: As'))
  : ibound a' = ibound (BoundedIndex_app_comm_cons a As As' a').
  Proof.
    unfold BoundedIndex_app_comm_cons, eq_rec, eq_rect; simpl.
    destruct (app_comm_cons' a As As'); reflexivity.
  Qed.

  Program Fixpoint Iterate_Ensemble_BoundedIndex'
          {A : Set}
          (Visited Remaining : list A)
          (P : Ensemble (BoundedIndex (Visited ++ Remaining))) : Prop :=
    match Remaining with
      | nil => True
      | a :: Remaining' =>
        P {| bindex := a;
             indexb := {| ibound := List.length Visited;
                          boundi := _ |} |}
        /\ Iterate_Ensemble_BoundedIndex' (Visited ++ (a :: nil)) Remaining' _
    end.
  Next Obligation.
    clear P; induction Visited; simpl; auto.
  Defined.
  Next Obligation.
    exact (Ensemble_BoundedIndex_app_comm_cons _ _ _ P).
  Defined.

  (* Iterating with a filter. *)
  Program Fixpoint Iterate_Ensemble_BoundedIndex_filter'
          {A : Set}
          (Visited Remaining : list A)
          (filter : nat -> bool)
          (P : Ensemble (BoundedIndex (Visited ++ Remaining))) : Prop :=
    match Remaining with
      | nil => True
      | a :: Remaining' =>
        if filter (List.length Visited)
        then
          P {| bindex := a;
               indexb := {| ibound := List.length Visited;
                            boundi := _ |} |}
          /\ Iterate_Ensemble_BoundedIndex_filter' (Visited ++ (a :: nil)) Remaining' filter _
        else
          Iterate_Ensemble_BoundedIndex_filter' (Visited ++ (a :: nil)) Remaining' filter _
    end.
  Next Obligation.
    clear filter P; induction Visited; simpl; auto.
  Defined.
  Next Obligation.
    exact (Ensemble_BoundedIndex_app_comm_cons _ _ _ P).
  Defined.
  Next Obligation.
    exact (Ensemble_BoundedIndex_app_comm_cons _ _ _ P).
  Defined.

  Lemma Ensemble_BoundedIndex_app_equiv {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
        (a : A) (As As' : list A)
        (P : Ensemble (BoundedIndex (As ++ a :: As')))
  : forall idx idx' n nth nth',
      P {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|} <->
      Ensemble_BoundedIndex_app_comm_cons a As As' P
                                          {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|}.
  Proof.
    split; unfold Ensemble_BoundedIndex_app_comm_cons, BoundedIndex_app_comm_cons, app_comm_cons'; simpl;
    unfold eq_rec, eq_rect, eq_ind, eq_rect; destruct (app_assoc As (a :: nil) As'); auto;
    generalize (indexb_ibound_eq
                  {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst;
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec _); eauto.
  Qed.

  Lemma BoundedIndex_app_comm_cons_nth_eq {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall
      (As As' : list A)
      a a' a'' n nth nth',
      {| bindex := a; indexb := {| ibound := n; boundi := nth |}|} =
      BoundedIndex_app_comm_cons a' As As' {| bindex := a''; indexb := {| ibound := n; boundi := nth' |}|}.
  Proof.
    intros.
    unfold BoundedIndex_app_comm_cons, eq_rec, eq_rect; simpl.
    destruct (app_comm_cons' a' As As').
    generalize (indexb_ibound_eq
                  {| bindex := a''; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := a; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst.
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth'); reflexivity.
  Defined.

  Lemma Ensemble_BoundedIndex_nth_eq {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall
      (As : list A)
      (P : Ensemble (BoundedIndex As))
      a a' n nth nth',
      P {| bindex := a; indexb := {| ibound := n; boundi := nth |}|} ->
      P {| bindex := a'; indexb := {| ibound := n; boundi := nth' |}|}.
  Proof.
    intros;
    generalize (indexb_ibound_eq
                  {| bindex := a'; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := a; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst.
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth'); eassumption.
  Defined.

  Lemma nth_error_app {A : Set} :
    forall (a : A) (As As' : list A) n,
      nth_error As n = Some a ->
      nth_error (As ++ As') n = Some a.
  Proof.
    induction As; destruct n; simpl; intros; try discriminate; auto.
  Defined.

  Lemma Ensemble_nth_error_app
        {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall a (As As' : list A) nth'
           (P : Ensemble (BoundedIndex (As ++ (a :: As')))),
      P {| bindex := a;
           indexb := {| ibound := Datatypes.length As;
                        boundi := nth' |} |}
      -> (forall (a' : A) (n : nat) (nth : nth_error As n = Some a'),
            P {| bindex := a';
                 indexb := {|
                            ibound := n;
                            boundi := nth_error_app As (a :: As') n nth |} |})
      -> forall (a' : A) (n : nat) (nth : nth_error (As ++ (a :: nil)) n = Some a'),
           Ensemble_BoundedIndex_app_comm_cons a As As' P
                                               {| bindex := a';
                                                  indexb := {| ibound := n;
                                                               boundi := nth_error_app (As ++ (a :: nil)) As' n nth |} |}.
  Proof.
    intros.
    destruct (eq_nat_dec (List.length As) n ); subst.
    - rewrite (BoundedIndex_app_comm_cons_nth_eq
                 A_eq_dec As As' _ (List.length As)
                 (nth_error_app (As ++ (a :: nil)) As'
                                (Datatypes.length As) nth)
                 nth').
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Ensemble_BoundedIndex_app_equiv; eauto.
    - assert (nth_error As n = Some a') by
          (revert n nth n0; clear; induction As; destruct n; simpl; intros;
           try congruence;
           [destruct n; discriminate
           | eauto]).
      generalize (H0 _ _ H1); intros.
      erewrite (BoundedIndex_app_comm_cons_nth_eq
                  A_eq_dec As As' _ n
                  (nth_error_app (As ++ (a :: nil)) As'
                                 n nth)).
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Ensemble_BoundedIndex_app_equiv; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc; simpl; apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
  Qed.

  Lemma Ensemble_nth_error_app_filter
        {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall a (As As' : list A) nth'
           (P : Ensemble (BoundedIndex (As ++ (a :: As'))))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (filter (Datatypes.length As) ->
       P {| bindex := a;
            indexb := {| ibound := Datatypes.length As;
                         boundi := nth' |} |})
      -> (forall (a' : A) (n : nat) (nth : nth_error As n = Some a'),
            filter n ->
            P {| bindex := a';
                 indexb := {|
                            ibound := n;
                            boundi := nth_error_app As (a :: As') n nth |} |})
      -> forall (a' : A) (n : nat) (nth : nth_error (As ++ (a :: nil)) n = Some a'),
           filter n ->
           Ensemble_BoundedIndex_app_comm_cons a As As' P
                                               {| bindex := a';
                                                  indexb := {| ibound := n;
                                                               boundi := nth_error_app (As ++ (a :: nil)) As' n nth |} |}.
  Proof.
    intros.
    destruct (eq_nat_dec (List.length As) n ); subst.
    - rewrite (BoundedIndex_app_comm_cons_nth_eq
                 A_eq_dec As As' _  (List.length As)
                 (nth_error_app (As ++ (a :: nil)) As'
                                (Datatypes.length As) nth)
                 nth').
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Ensemble_BoundedIndex_app_equiv; auto.
    - assert (nth_error As n = Some a') by
          (generalize n nth n0; clear; induction As; destruct n; simpl; intros;
           try congruence;
           [destruct n; discriminate
           | eauto]).
      generalize (H0 _ _ H2 H1); intros.

      erewrite (BoundedIndex_app_comm_cons_nth_eq
                  A_eq_dec As As' _ n
                  (nth_error_app (As ++ (a :: nil)) As'
                                 n nth)).
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Ensemble_BoundedIndex_app_equiv; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc; simpl; apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
  Qed.

  Fixpoint app_nil_r'
           {A : Type}
           (n : nat)
           (l : list A)
           (a_opt : option A)
           (nth_l : nth_error (l ++ []) n = a_opt)
  :  nth_error l n = a_opt :=
    match l return nth_error (l ++ []) n = a_opt
                   -> nth_error l n = a_opt with
      | nil => fun nth_l => nth_l
      | a :: l' => match n return
                         nth_error ((a :: l') ++ []) n = a_opt
                         -> nth_error (a :: l') n = a_opt
                   with
                     | 0 => fun nth_l => nth_l
                     | S n' => @app_nil_r' A n' l' a_opt
                   end
    end nth_l.

  Lemma Iterate_Ensemble_equiv' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Ensemble (BoundedIndex (Visited ++ Remaining))),
      (forall a n (nth : nth_error Visited n = Some a),
         P {| bindex := a;
              indexb := {| ibound := n;
                           boundi := nth_error_app _ _ _ nth |} |})
      -> (Iterate_Ensemble_BoundedIndex' Visited Remaining P ->
          forall idx, P idx).
    intros; destruct idx as [idx [n nth_n] ]; simpl in *.
    revert Visited P H H0 idx n nth_n; induction Remaining; simpl; intros.
    - eapply Ensemble_BoundedIndex_nth_eq with (a := idx); auto.
    - split_and.
      assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining) n = Some idx)
        as nth_n'
          by (rewrite <- app_assoc; simpl; assumption).
      generalize (IHRemaining _ _ (Ensemble_nth_error_app A_eq_dec _ _ _ P H1 H) H2 _ _ nth_n').
      unfold Ensemble_BoundedIndex_app_comm_cons, eq_rect; destruct (app_comm_cons' a Visited Remaining).
      intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n); eauto.
      Grab Existential Variables.
      apply app_nil_r'; assumption.
  Qed.

  Lemma Iterate_Ensemble_equiv'' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Ensemble (BoundedIndex (Visited ++ Remaining))),
      (forall idx, P idx)
      -> Iterate_Ensemble_BoundedIndex' Visited Remaining P.
    induction Remaining; simpl; auto.
    intros; split; eauto.
    eapply IHRemaining; intros; eauto.
    intros; destruct idx as [idx [n nth_n] ]; simpl in *.
    eapply Ensemble_BoundedIndex_app_equiv; eauto.
    Grab Existential Variables.
    rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
  Qed.

  Lemma Iterate_Ensemble_equiv_filter' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Ensemble (BoundedIndex (Visited ++ Remaining)))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (forall a n (nth : nth_error Visited n = Some a),
         filter n ->
         P {| bindex := a;
              indexb := {| ibound := n;
                           boundi := nth_error_app _ _ _ nth |} |})
      -> (Iterate_Ensemble_BoundedIndex_filter' Visited Remaining
                                                (@dec _ _ filter_dec) P ->
          forall idx, filter (ibound (indexb idx)) -> P idx).
  Proof.
    intros; destruct idx as [idx [n nth_n] ]; simpl in *.
    revert Visited filter filter_dec P H H0 idx n nth_n H1;
      induction Remaining; simpl; intros.
    - eapply Ensemble_BoundedIndex_nth_eq with (a := idx); auto.
    - revert H0; case_eq (dec (Datatypes.length Visited)); intros.
      + split_and.
        assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining) n = Some idx)
          as nth_n'
            by (rewrite <- app_assoc; simpl; assumption).
        generalize (IHRemaining
                      _ filter filter_dec _
                      (Ensemble_nth_error_app_filter
                         A_eq_dec _ _ _
                         P filter_dec (fun _ => H3) H)
                      H4 _ _ nth_n').
        unfold Ensemble_BoundedIndex_app_comm_cons, eq_rect.
        destruct (app_comm_cons' a Visited Remaining).
        clear H.
        intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n); eauto.
      + assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining) n = Some idx)
          as nth_n'
            by (rewrite <- app_assoc; simpl; assumption).
        assert (forall P, filter (Datatypes.length Visited) -> P)
          as H' by
              (intros P' filt_a; apply dec_decides_P in filt_a;
               congruence).
        assert (nth_error (Visited ++ (a :: Remaining))
                          (Datatypes.length Visited) = Some a)
          as nth_a
            by (clear; induction Visited; simpl; auto).
        generalize (IHRemaining
                      _ filter filter_dec _
                      (Ensemble_nth_error_app_filter
                         A_eq_dec _ _ nth_a P
                         filter_dec (H' _) H)
                      H2 _ _ nth_n').
        unfold Ensemble_BoundedIndex_app_comm_cons, eq_rect.
        destruct (app_comm_cons' a Visited Remaining).
        clear H.
        intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n); eauto.
        Grab Existential Variables.
        apply app_nil_r'; assumption.
  Qed.

  Lemma Iterate_Ensemble_equiv_filter'' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Ensemble (BoundedIndex (Visited ++ Remaining)))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (forall idx, filter (ibound (indexb idx)) -> P idx)
      -> Iterate_Ensemble_BoundedIndex_filter'
           Visited Remaining
           (@dec _ _ filter_dec) P.
  Proof.
    induction Remaining; simpl; auto.
    intros; case_eq (dec (Datatypes.length Visited)); try split; eauto.
    - eapply H; apply dec_decides_P; simpl; auto.
    - eapply IHRemaining; intros; eauto.
      intros; destruct idx as [idx [n nth_n] ]; simpl in *.
      eapply Ensemble_BoundedIndex_app_equiv; eauto.
    - intros; eapply IHRemaining; intros; eauto.
      intros; destruct idx as [idx [n nth_n] ]; simpl in *.
      eapply Ensemble_BoundedIndex_app_equiv; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
      rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
  Qed.

  Definition Iterate_Ensemble_BoundedIndex
             (Bound : list string)
             (P : Ensemble (BoundedIndex Bound)) : Prop :=
    Iterate_Ensemble_BoundedIndex' nil Bound P.

  Corollary Iterate_Ensemble_BoundedIndex_equiv
  : forall (Bound : list string)
           (P : Ensemble (BoundedIndex Bound)),
      Iterate_Ensemble_BoundedIndex P <->
      forall idx, P idx.
  Proof.
    split; intros.
    eapply Iterate_Ensemble_equiv' with (Visited := nil);
      eauto using string_dec; destruct n; simpl; discriminate.
    eapply Iterate_Ensemble_equiv'' with (Visited := nil);
      eauto using string_dec.
  Qed.

  Definition Iterate_Ensemble_BoundedIndex_filter
             (Bound : list string)
             (filter : nat -> bool)
             (P : Ensemble (BoundedIndex Bound))
  : Prop :=
    Iterate_Ensemble_BoundedIndex_filter' nil Bound filter P.

  Corollary Iterate_Ensemble_BoundedIndex_filter_equiv
  : forall (Bound : list string)
           (P : Ensemble (BoundedIndex Bound))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      Iterate_Ensemble_BoundedIndex_filter dec P <->
      forall idx : BoundedIndex Bound, filter (ibound idx) -> P idx.
  Proof.
    split; intros.
    - eapply Iterate_Ensemble_equiv_filter' with (Visited := nil);
      eauto using string_dec; destruct n; simpl; discriminate.
    - eapply Iterate_Ensemble_equiv_filter'' with (Visited := nil);
      eauto using string_dec.
  Qed.

End Iterate_Ensemble.

(* Always expand these iterations. *)
Arguments Iterate_Ensemble_BoundedIndex_filter _ _ _ / .
Arguments Iterate_Ensemble_BoundedIndex _ _ / .

Section Iterate_Dep_Type.

  Local Notation Dep_Type A := (A -> Type).

  Definition Dep_Type_BoundedIndex_app_comm_cons {A : Set}
             (a : A)
             (As As' : list A)
             (P : Dep_Type (BoundedIndex (As ++ a :: As')))
  : Dep_Type (BoundedIndex ((As ++ (a :: nil)) ++ As')).
    rewrite app_comm_cons' in P; exact P.
  Defined.

  Program Fixpoint Iterate_Dep_Type_BoundedIndex'
          {A : Set}
          (Visited Remaining : list A)
          (P : Dep_Type (BoundedIndex (Visited ++ Remaining))) : Type :=
    match Remaining with
      | nil => unit
      | a :: Remaining' =>
        prod (P {| bindex := a;
                   indexb := {| ibound := List.length Visited;
                                boundi := _ |} |})
             (Iterate_Dep_Type_BoundedIndex' (Visited ++ (a :: nil)) Remaining' _)
    end.
  Next Obligation.
    clear P; induction Visited; simpl; auto.
  Defined.
  Next Obligation.
    exact (Dep_Type_BoundedIndex_app_comm_cons _ _ _ P H).
  Defined.

  (* Iterating with a filter. *)
  Program Fixpoint Iterate_Dep_Type_BoundedIndex_filter'
          {A : Set}
          (Visited Remaining : list A)
          (filter : nat -> bool)
          (P : Dep_Type (BoundedIndex (Visited ++ Remaining))) : Type :=
    match Remaining with
      | nil => unit
      | a :: Remaining' =>
        if filter (List.length Visited)
        then
          prod
            (P {| bindex := a;
                  indexb := {| ibound := List.length Visited;
                               boundi := _ |} |})
            (Iterate_Dep_Type_BoundedIndex_filter' (Visited ++ (a :: nil)) Remaining' filter _)
        else
          Iterate_Dep_Type_BoundedIndex_filter' (Visited ++ (a :: nil)) Remaining' filter _
    end.
  Next Obligation.
    clear filter P; induction Visited; simpl; auto.
  Defined.
  Next Obligation.
    exact (Dep_Type_BoundedIndex_app_comm_cons _ _ _ P H).
  Defined.
  Next Obligation.
    exact (Dep_Type_BoundedIndex_app_comm_cons _ _ _ P H).
  Defined.

  Lemma Dep_Type_BoundedIndex_app_equiv_1 {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
        (a : A) (As As' : list A)
        (P : Dep_Type (BoundedIndex (As ++ a :: As')))
  : forall idx idx' n nth nth',
      P {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|} ->
      Dep_Type_BoundedIndex_app_comm_cons a As As' P
                                          {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|}.
  Proof.
    unfold Dep_Type_BoundedIndex_app_comm_cons, BoundedIndex_app_comm_cons, app_comm_cons'; simpl;
    unfold eq_rec, eq_rect, eq_ind, eq_rect; destruct (app_assoc As (a :: nil) As'); auto;
    intros;
    generalize (indexb_ibound_eq
                  {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst;
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec _); eauto.
  Qed.

  Lemma Dep_Type_BoundedIndex_app_equiv_2 {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
        (a : A) (As As' : list A)
        (P : Dep_Type (BoundedIndex (As ++ a :: As')))
  : forall idx idx' n nth nth',
      Dep_Type_BoundedIndex_app_comm_cons a As As' P
                                          {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|} ->
      P {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|}.
  Proof.
    unfold Dep_Type_BoundedIndex_app_comm_cons, BoundedIndex_app_comm_cons, app_comm_cons'; simpl;
    unfold eq_rec, eq_rect, eq_ind, eq_rect; destruct (app_assoc As (a :: nil) As'); auto;
    intros;
    generalize (indexb_ibound_eq
                  {| bindex := idx'; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := idx; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst;
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec _); eauto.
  Qed.

  Lemma Dep_Type_BoundedIndex_nth_eq {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall
      (As : list A)
      (P : Dep_Type (BoundedIndex As))
      a a' n nth nth',
      P {| bindex := a; indexb := {| ibound := n; boundi := nth |}|} ->
      P {| bindex := a'; indexb := {| ibound := n; boundi := nth' |}|}.
  Proof.
    intros;
    generalize (indexb_ibound_eq
                  {| bindex := a'; indexb := {| ibound := n; boundi := nth' |}|}
                  {| bindex := a; indexb := {| ibound := n; boundi := nth |}|}
                  eq_refl); simpl; intros; subst.
    erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth'); eassumption.
  Defined.

  Lemma Dep_Type_nth_error_app
        {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall a (As As' : list A) nth'
           (P : Dep_Type (BoundedIndex (As ++ (a :: As')))),
      P {| bindex := a;
           indexb := {| ibound := Datatypes.length As;
                        boundi := nth' |} |}
      -> (forall (a' : A) (n : nat) (nth : nth_error As n = Some a'),
            P {| bindex := a';
                 indexb := {|
                            ibound := n;
                            boundi := nth_error_app As (a :: As') n nth |} |})
      -> forall (a' : A) (n : nat) (nth : nth_error (As ++ (a :: nil)) n = Some a'),
           Dep_Type_BoundedIndex_app_comm_cons a As As' P
                                               {| bindex := a';
                                                  indexb := {| ibound := n;
                                                               boundi := nth_error_app (As ++ (a :: nil)) As' n nth |} |}.
  Proof.
    intros.
    destruct (eq_nat_dec (List.length As) n ); subst.
    - rewrite (BoundedIndex_app_comm_cons_nth_eq
                 A_eq_dec As As' _ (List.length As)
                 (nth_error_app (As ++ (a :: nil)) As'
                                (Datatypes.length As) nth)
                 nth').
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
    - assert (nth_error As n = Some a') by
          (revert n nth n0; clear; induction As; destruct n; simpl; intros;
           try congruence;
           [destruct n; discriminate
           | eauto]).
      generalize (X0 _ _ H); intros.
      erewrite (BoundedIndex_app_comm_cons_nth_eq
                  A_eq_dec As As' _ n
                  (nth_error_app (As ++ (a :: nil)) As'
                                 n nth)).
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc; simpl; apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
  Qed.

  Lemma Dep_Type_nth_error_app_filter
        {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall a (As As' : list A) nth'
           (P : Dep_Type (BoundedIndex (As ++ (a :: As'))))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (filter (Datatypes.length As) ->
       P {| bindex := a;
            indexb := {| ibound := Datatypes.length As;
                         boundi := nth' |} |})
      -> (forall (a' : A) (n : nat) (nth : nth_error As n = Some a'),
            filter n ->
            P {| bindex := a';
                 indexb := {|
                            ibound := n;
                            boundi := nth_error_app As (a :: As') n nth |} |})
      -> forall (a' : A) (n : nat) (nth : nth_error (As ++ (a :: nil)) n = Some a'),
           filter n ->
           Dep_Type_BoundedIndex_app_comm_cons a As As' P
                                               {| bindex := a';
                                                  indexb := {| ibound := n;
                                                               boundi := nth_error_app (As ++ (a :: nil)) As' n nth |} |}.
  Proof.
    intros.
    destruct (eq_nat_dec (List.length As) n ); subst.
    - rewrite (BoundedIndex_app_comm_cons_nth_eq
                 A_eq_dec As As' _  (List.length As)
                 (nth_error_app (As ++ (a :: nil)) As'
                                (Datatypes.length As) nth)
                 nth').
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Dep_Type_BoundedIndex_app_equiv_1; auto.
    - assert (nth_error As n = Some a') by
          (generalize n nth n0; clear; induction As; destruct n; simpl; intros;
           try congruence;
           [destruct n; discriminate
           | eauto]).
      generalize (X0 _ _ H0 H); intros.
      erewrite (BoundedIndex_app_comm_cons_nth_eq
                  A_eq_dec As As' _ n
                  (nth_error_app (As ++ (a :: nil)) As'
                                 n nth)).
      erewrite <- BoundedIndex_app_comm_cons_nth_eq; eauto.
      eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc; simpl; apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
      apply nth_error_app; eassumption.
  Qed.

  Fixpoint Iterate_Dep_Type_equiv' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
        (Remaining Visited : list A)
        (P : Dep_Type (BoundedIndex (Visited ++ Remaining)))
        (X : forall a n (nth : nth_error Visited n = Some a),
               P {| bindex := a;
                    indexb := {| ibound := n;
                                 boundi := nth_error_app _ _ _ nth |} |})
        (X0 : Iterate_Dep_Type_BoundedIndex' Visited Remaining P)
        idx n nth_n
        {struct Remaining}
  : P {| bindex := idx;
         indexb := {| ibound := n;
                      boundi := nth_n |} |}.
  refine (match Remaining return
                forall (P : Dep_Type (BoundedIndex (Visited ++ Remaining)))
                       (X : forall a n (nth : nth_error Visited n = Some a),
                              P {| bindex := a;
                                   indexb := {| ibound := n;
                                                boundi := nth_error_app _ _ _ nth |} |})
                       (X0 : Iterate_Dep_Type_BoundedIndex' Visited Remaining P)
                       idx n (nth_n : nth_error (Visited ++ Remaining) n = Some idx),
                  P {| bindex := idx;
                       indexb := {| ibound := n;
                                    boundi := nth_n |} |}
          with
            | nil => _
            | a :: Remaining' => _
          end P X X0 idx n nth_n); intros; eauto.
  - intros; eapply Dep_Type_BoundedIndex_nth_eq with (a := idx0); eauto.
  - split_and.
      assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining') n0 = Some idx0)
        as nth_n'
          by (rewrite <- app_assoc; simpl; assumption).
      generalize (Iterate_Dep_Type_equiv' _ A_eq_dec _ _ _ (Dep_Type_nth_error_app A_eq_dec _ _ _ P0 (fst X2) X1) (snd X2) _ _ nth_n').
      unfold Dep_Type_BoundedIndex_app_comm_cons, eq_rect; destruct (app_comm_cons' a Visited Remaining').
      intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n0); eauto.
      Grab Existential Variables.
      apply app_nil_r'; assumption.
  Defined.

  Lemma Iterate_Dep_Type_equiv'' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Dep_Type (BoundedIndex (Visited ++ Remaining))),
      (forall idx, P idx)
      -> Iterate_Dep_Type_BoundedIndex' Visited Remaining P.
  Proof.
    induction Remaining; simpl; econstructor; eauto.
    eapply IHRemaining; intros; eauto.
    intros; destruct idx as [idx [n nth_n] ]; simpl in *.
    eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
    Grab Existential Variables.
    rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
  Defined.

    Lemma Iterate_Dep_Type_equiv_filter' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Dep_Type (BoundedIndex (Visited ++ Remaining)))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (forall a n (nth : nth_error Visited n = Some a),
         filter n ->
         P {| bindex := a;
              indexb := {| ibound := n;
                           boundi := nth_error_app _ _ _ nth |} |})
      -> (Iterate_Dep_Type_BoundedIndex_filter' Visited Remaining
                                                (@dec _ _ filter_dec) P ->
          forall idx, filter (ibound (indexb idx)) -> P idx).
  Proof.
    intros; destruct idx as [idx [n nth_n] ]; simpl in *.
    revert Visited filter filter_dec P X X0 idx n nth_n H;
      induction Remaining; simpl; intros.
    - eapply Dep_Type_BoundedIndex_nth_eq with (a := idx); auto.
    - revert X0; case_eq (dec (Datatypes.length Visited)); intros.
      + split_and.
        assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining) n = Some idx)
          as nth_n'
            by (rewrite <- app_assoc; simpl; assumption).
        generalize (IHRemaining
                      _ filter filter_dec _
                      (Dep_Type_nth_error_app_filter
                         A_eq_dec _ _ _
                         P filter_dec (fun _ => (fst X0)) X)
                      (snd X0) _ _ nth_n').
        unfold Dep_Type_BoundedIndex_app_comm_cons, eq_rect.
        destruct (app_comm_cons' a Visited Remaining).
        clear X.
        intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n); eauto.
      + assert (nth_error ((Visited ++ (a :: nil)) ++ Remaining) n = Some idx)
          as nth_n'
            by (rewrite <- app_assoc; simpl; assumption).
        assert (forall P, filter (Datatypes.length Visited) -> P)
          as H' by
              (intros P' filt_a; apply dec_decides_P in filt_a;
               congruence).
        assert (nth_error (Visited ++ (a :: Remaining))
                          (Datatypes.length Visited) = Some a)
          as nth_a
            by (clear; induction Visited; simpl; auto).
        generalize (IHRemaining
                      _ filter filter_dec _
                      (Dep_Type_nth_error_app_filter
                         A_eq_dec _ _ nth_a P
                         filter_dec (H' _) X)
                      X0 _ _ nth_n').
        unfold Dep_Type_BoundedIndex_app_comm_cons, eq_rect.
        destruct (app_comm_cons' a Visited Remaining).
        clear X.
        intros; erewrite (eq_proofs_unicity_Opt_A A_eq_dec nth_n); eauto.
        Grab Existential Variables.
        rewrite app_nil_r in nth_n; assumption.
  Qed.

  Lemma Iterate_Dep_Type_equiv_filter'' {A : Set}
        (A_eq_dec : forall a a' : A, {a = a'} + {a <> a'})
  : forall (Remaining Visited : list A)
           (P : Dep_Type (BoundedIndex (Visited ++ Remaining)))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (forall idx, filter (ibound (indexb idx)) -> P idx)
      -> Iterate_Dep_Type_BoundedIndex_filter'
           Visited Remaining
           (@dec _ _ filter_dec) P.
  Proof.
    induction Remaining; simpl; try constructor.
    intros; case_eq (dec (Datatypes.length Visited)); try split; intros; eauto.
    - eapply X; apply dec_decides_P; simpl; auto.
    - eapply IHRemaining; intros; eauto.
      intros; destruct idx as [idx [n nth_n] ]; simpl in *.
      eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
    - intros; eapply IHRemaining; intros; eauto.
      intros; destruct idx as [idx [n nth_n] ]; simpl in *.
      eapply Dep_Type_BoundedIndex_app_equiv_1; eauto.
      Grab Existential Variables.
      rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
      rewrite <- app_assoc in nth_n; simpl in nth_n; eassumption.
  Qed.

  Definition Iterate_Dep_Type_BoundedIndex
             (Bound : list string)
             (P : Dep_Type (BoundedIndex Bound)) : Type :=
    Iterate_Dep_Type_BoundedIndex' nil Bound P.

  Corollary Iterate_Dep_Type_BoundedIndex_equiv_1
  : forall (Bound : list string)
           (P : Dep_Type (BoundedIndex Bound)),
      Iterate_Dep_Type_BoundedIndex P ->
      forall idx, P idx.
  Proof.
    destruct idx as [idx [n nth_n]].
    eapply (Iterate_Dep_Type_equiv' string_dec Bound nil P); eauto;
    destruct n0; simpl; discriminate.
  Defined.

  Corollary Iterate_Dep_Type_BoundedIndex_equiv_2
  : forall (Bound : list string)
           (P : Dep_Type (BoundedIndex Bound)),
      (forall idx, P idx)
      -> Iterate_Dep_Type_BoundedIndex P.
  Proof.
    intros.
    eapply Iterate_Dep_Type_equiv'' with (Visited := nil);
      eauto using string_dec.
  Qed.

  Definition Iterate_Dep_Type_BoundedIndex_filter
             (Bound : list string)
             (filter : nat -> bool)
             (P : Dep_Type (BoundedIndex Bound))
  : Type :=
    Iterate_Dep_Type_BoundedIndex_filter' nil Bound filter P.

  Corollary Iterate_Dep_Type_BoundedIndex_filter_equiv_1
  : forall (Bound : list string)
           (P : Dep_Type (BoundedIndex Bound))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      Iterate_Dep_Type_BoundedIndex_filter dec P ->
      forall idx : BoundedIndex Bound, filter (ibound idx) -> P idx.
  Proof.
    intros; eapply Iterate_Dep_Type_equiv_filter' with (Visited := nil);
    eauto using string_dec; destruct n; simpl; discriminate.
  Qed.

  Corollary Iterate_Dep_Type_BoundedIndex_filter_equiv_2
  : forall (Bound : list string)
           (P : Dep_Type (BoundedIndex Bound))
           (filter : Ensemble nat)
           (filter_dec : DecideableEnsemble filter),
      (forall idx : BoundedIndex Bound, filter (ibound idx) -> P idx)
      -> Iterate_Dep_Type_BoundedIndex_filter dec P.
  Proof.
    intros; eapply Iterate_Dep_Type_equiv_filter'' with (Visited := nil);
    eauto using string_dec.
  Qed.

End Iterate_Dep_Type.

(* Always expand these iterations as well. *)
Arguments Iterate_Dep_Type_BoundedIndex_filter _ _ _ / .
Arguments Iterate_Dep_Type_BoundedIndex _ _ / .
Arguments Dep_Type_BoundedIndex_app_comm_cons _ _ _ _ _ _ / .
