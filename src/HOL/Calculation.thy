(*  Title:      HOL/Calculation.thy
    ID:         $Id$
    Author:     Markus Wenzel, TU Muenchen

Setup transitivity rules for calculational proofs.  Note that in the
list below later rules have priority.
*)

theory Calculation = Int:;


theorems [trans] = HOL.ssubst;                          (*  =  x  x  *)
theorems [trans] = HOL.subst[COMP swap_prems_rl];       (*  x  =  x  *)

theorems [trans] = Divides.dvd_trans;                   (* dvd dvd dvd *)

theorems [trans] = Ord.order_less_trans;                (*  <  <  <  *)
theorems [trans] = Ord.order_le_less_trans;             (*  <= <  <  *)
theorems [trans] = Ord.order_less_le_trans;             (*  <  <= <  *)
theorems [trans] = Ord.order_trans;                     (*  <= <= <= *)
theorems [trans] = Ord.order_antisym;                   (*  <= <= =  *)

theorem [trans]: "[| x <= y; y = z |] ==> x <= z";	(*  <= =  <= *)
  by (rule HOL.subst);

theorem [trans]: "[| x = y; y <= z |] ==> x <= z";	(*  =  <= <= *)
  by (rule HOL.ssubst);

theorem [trans]: "[| x < y; y = z |] ==> x < z";	(*  <  =  <  *)
  by (rule HOL.subst);

theorem [trans]: "[| x = y; y < z |] ==> x < z";	(*  =  <  <  *)
  by (rule HOL.ssubst);

theorems [trans] = HOL.trans                            (*  =  =  =  *)


end;
