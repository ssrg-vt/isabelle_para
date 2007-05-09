(*  Title:      HOL/Fun.thy
    ID:         $Id$
    Author:     Tobias Nipkow, Cambridge University Computer Laboratory
    Copyright   1994  University of Cambridge
*)

header {* Notions about functions *}

theory Fun
imports Set
begin

constdefs
  fun_upd :: "('a => 'b) => 'a => 'b => ('a => 'b)"
  "fun_upd f a b == % x. if x=a then b else f x"

nonterminals
  updbinds updbind
syntax
  "_updbind" :: "['a, 'a] => updbind"             ("(2_ :=/ _)")
  ""         :: "updbind => updbinds"             ("_")
  "_updbinds":: "[updbind, updbinds] => updbinds" ("_,/ _")
  "_Update"  :: "['a, updbinds] => 'a"            ("_/'((_)')" [1000,0] 900)

translations
  "_Update f (_updbinds b bs)"  == "_Update (_Update f b) bs"
  "f(x:=y)"                     == "fun_upd f x y"

(* Hint: to define the sum of two functions (or maps), use sum_case.
         A nice infix syntax could be defined (in Datatype.thy or below) by
consts
  fun_sum :: "('a => 'c) => ('b => 'c) => (('a+'b) => 'c)" (infixr "'(+')"80)
translations
 "fun_sum" == sum_case
*)

definition
  override_on :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'a set \<Rightarrow> 'a \<Rightarrow> 'b"
where
  "override_on f g A = (\<lambda>a. if a \<in> A then g a else f a)"

definition
  id :: "'a \<Rightarrow> 'a"
where
  "id = (\<lambda>x. x)"

definition
  comp :: "('b \<Rightarrow> 'c) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'c" (infixl "o" 55)
where
  "f o g = (\<lambda>x. f (g x))"

notation (xsymbols)
  comp  (infixl "\<circ>" 55)

notation (HTML output)
  comp  (infixl "\<circ>" 55)

text{*compatibility*}
lemmas o_def = comp_def

constdefs
  inj_on :: "['a => 'b, 'a set] => bool"         (*injective*)
  "inj_on f A == ! x:A. ! y:A. f(x)=f(y) --> x=y"

text{*A common special case: functions injective over the entire domain type.*}

abbreviation
  "inj f == inj_on f UNIV"

constdefs
  surj :: "('a => 'b) => bool"                   (*surjective*)
  "surj f == ! y. ? x. y=f(x)"

  bij :: "('a => 'b) => bool"                    (*bijective*)
  "bij f == inj f & surj f"



text{*As a simplification rule, it replaces all function equalities by
  first-order equalities.*}
lemma expand_fun_eq: "f = g \<longleftrightarrow> (\<forall>x. f x = g x)"
apply (rule iffI)
apply (simp (no_asm_simp))
apply (rule ext)
apply (simp (no_asm_simp))
done

lemma apply_inverse:
    "[| f(x)=u;  !!x. P(x) ==> g(f(x)) = x;  P(x) |] ==> x=g(u)"
by auto


text{*The Identity Function: @{term id}*}
lemma id_apply [simp]: "id x = x"
by (simp add: id_def)

lemma inj_on_id[simp]: "inj_on id A"
by (simp add: inj_on_def) 

lemma inj_on_id2[simp]: "inj_on (%x. x) A"
by (simp add: inj_on_def) 

lemma surj_id[simp]: "surj id"
by (simp add: surj_def) 

lemma bij_id[simp]: "bij id"
by (simp add: bij_def inj_on_id surj_id) 



subsection{*The Composition Operator: @{term "f \<circ> g"}*}

lemma o_apply [simp]: "(f o g) x = f (g x)"
by (simp add: comp_def)

lemma o_assoc: "f o (g o h) = f o g o h"
by (simp add: comp_def)

lemma id_o [simp]: "id o g = g"
by (simp add: comp_def)

lemma o_id [simp]: "f o id = f"
by (simp add: comp_def)

lemma image_compose: "(f o g) ` r = f`(g`r)"
by (simp add: comp_def, blast)

lemma image_eq_UN: "f`A = (UN x:A. {f x})"
by blast

lemma UN_o: "UNION A (g o f) = UNION (f`A) g"
by (unfold comp_def, blast)


subsection{*The Injectivity Predicate, @{term inj}*}

text{*NB: @{term inj} now just translates to @{term inj_on}*}


text{*For Proofs in @{text "Tools/datatype_rep_proofs"}*}
lemma datatype_injI:
    "(!! x. ALL y. f(x) = f(y) --> x=y) ==> inj(f)"
by (simp add: inj_on_def)

theorem range_ex1_eq: "inj f \<Longrightarrow> b : range f = (EX! x. b = f x)"
  by (unfold inj_on_def, blast)

lemma injD: "[| inj(f); f(x) = f(y) |] ==> x=y"
by (simp add: inj_on_def)

(*Useful with the simplifier*)
lemma inj_eq: "inj(f) ==> (f(x) = f(y)) = (x=y)"
by (force simp add: inj_on_def)


subsection{*The Predicate @{term inj_on}: Injectivity On A Restricted Domain*}

lemma inj_onI:
    "(!! x y. [|  x:A;  y:A;  f(x) = f(y) |] ==> x=y) ==> inj_on f A"
by (simp add: inj_on_def)

lemma inj_on_inverseI: "(!!x. x:A ==> g(f(x)) = x) ==> inj_on f A"
by (auto dest:  arg_cong [of concl: g] simp add: inj_on_def)

lemma inj_onD: "[| inj_on f A;  f(x)=f(y);  x:A;  y:A |] ==> x=y"
by (unfold inj_on_def, blast)

lemma inj_on_iff: "[| inj_on f A;  x:A;  y:A |] ==> (f(x)=f(y)) = (x=y)"
by (blast dest!: inj_onD)

lemma comp_inj_on:
     "[| inj_on f A;  inj_on g (f`A) |] ==> inj_on (g o f) A"
by (simp add: comp_def inj_on_def)

lemma inj_on_imageI: "inj_on (g o f) A \<Longrightarrow> inj_on g (f ` A)"
apply(simp add:inj_on_def image_def)
apply blast
done

lemma inj_on_image_iff: "\<lbrakk> ALL x:A. ALL y:A. (g(f x) = g(f y)) = (g x = g y);
  inj_on f A \<rbrakk> \<Longrightarrow> inj_on g (f ` A) = inj_on g A"
apply(unfold inj_on_def)
apply blast
done

lemma inj_on_contraD: "[| inj_on f A;  ~x=y;  x:A;  y:A |] ==> ~ f(x)=f(y)"
by (unfold inj_on_def, blast)

lemma inj_singleton: "inj (%s. {s})"
by (simp add: inj_on_def)

lemma inj_on_empty[iff]: "inj_on f {}"
by(simp add: inj_on_def)

lemma subset_inj_on: "[| inj_on f B; A <= B |] ==> inj_on f A"
by (unfold inj_on_def, blast)

lemma inj_on_Un:
 "inj_on f (A Un B) =
  (inj_on f A & inj_on f B & f`(A-B) Int f`(B-A) = {})"
apply(unfold inj_on_def)
apply (blast intro:sym)
done

lemma inj_on_insert[iff]:
  "inj_on f (insert a A) = (inj_on f A & f a ~: f`(A-{a}))"
apply(unfold inj_on_def)
apply (blast intro:sym)
done

lemma inj_on_diff: "inj_on f A ==> inj_on f (A-B)"
apply(unfold inj_on_def)
apply (blast)
done


subsection{*The Predicate @{term surj}: Surjectivity*}

lemma surjI: "(!! x. g(f x) = x) ==> surj g"
apply (simp add: surj_def)
apply (blast intro: sym)
done

lemma surj_range: "surj f ==> range f = UNIV"
by (auto simp add: surj_def)

lemma surjD: "surj f ==> EX x. y = f x"
by (simp add: surj_def)

lemma surjE: "surj f ==> (!!x. y = f x ==> C) ==> C"
by (simp add: surj_def, blast)

lemma comp_surj: "[| surj f;  surj g |] ==> surj (g o f)"
apply (simp add: comp_def surj_def, clarify)
apply (drule_tac x = y in spec, clarify)
apply (drule_tac x = x in spec, blast)
done



subsection{*The Predicate @{term bij}: Bijectivity*}

lemma bijI: "[| inj f; surj f |] ==> bij f"
by (simp add: bij_def)

lemma bij_is_inj: "bij f ==> inj f"
by (simp add: bij_def)

lemma bij_is_surj: "bij f ==> surj f"
by (simp add: bij_def)


subsection{*Facts About the Identity Function*}

text{*We seem to need both the @{term id} forms and the @{term "\<lambda>x. x"}
forms. The latter can arise by rewriting, while @{term id} may be used
explicitly.*}

lemma image_ident [simp]: "(%x. x) ` Y = Y"
by blast

lemma image_id [simp]: "id ` Y = Y"
by (simp add: id_def)

lemma vimage_ident [simp]: "(%x. x) -` Y = Y"
by blast

lemma vimage_id [simp]: "id -` A = A"
by (simp add: id_def)

lemma vimage_image_eq: "f -` (f ` A) = {y. EX x:A. f x = f y}"
by (blast intro: sym)

lemma image_vimage_subset: "f ` (f -` A) <= A"
by blast

lemma image_vimage_eq [simp]: "f ` (f -` A) = A Int range f"
by blast

lemma surj_image_vimage_eq: "surj f ==> f ` (f -` A) = A"
by (simp add: surj_range)

lemma inj_vimage_image_eq: "inj f ==> f -` (f ` A) = A"
by (simp add: inj_on_def, blast)

lemma vimage_subsetD: "surj f ==> f -` B <= A ==> B <= f ` A"
apply (unfold surj_def)
apply (blast intro: sym)
done

lemma vimage_subsetI: "inj f ==> B <= f ` A ==> f -` B <= A"
by (unfold inj_on_def, blast)

lemma vimage_subset_eq: "bij f ==> (f -` B <= A) = (B <= f ` A)"
apply (unfold bij_def)
apply (blast del: subsetI intro: vimage_subsetI vimage_subsetD)
done

lemma image_Int_subset: "f`(A Int B) <= f`A Int f`B"
by blast

lemma image_diff_subset: "f`A - f`B <= f`(A - B)"
by blast

lemma inj_on_image_Int:
   "[| inj_on f C;  A<=C;  B<=C |] ==> f`(A Int B) = f`A Int f`B"
apply (simp add: inj_on_def, blast)
done

lemma inj_on_image_set_diff:
   "[| inj_on f C;  A<=C;  B<=C |] ==> f`(A-B) = f`A - f`B"
apply (simp add: inj_on_def, blast)
done

lemma image_Int: "inj f ==> f`(A Int B) = f`A Int f`B"
by (simp add: inj_on_def, blast)

lemma image_set_diff: "inj f ==> f`(A-B) = f`A - f`B"
by (simp add: inj_on_def, blast)

lemma inj_image_mem_iff: "inj f ==> (f a : f`A) = (a : A)"
by (blast dest: injD)

lemma inj_image_subset_iff: "inj f ==> (f`A <= f`B) = (A<=B)"
by (simp add: inj_on_def, blast)

lemma inj_image_eq_iff: "inj f ==> (f`A = f`B) = (A = B)"
by (blast dest: injD)

lemma image_UN: "(f ` (UNION A B)) = (UN x:A.(f ` (B x)))"
by blast

(*injectivity's required.  Left-to-right inclusion holds even if A is empty*)
lemma image_INT:
   "[| inj_on f C;  ALL x:A. B x <= C;  j:A |]
    ==> f ` (INTER A B) = (INT x:A. f ` B x)"
apply (simp add: inj_on_def, blast)
done

(*Compare with image_INT: no use of inj_on, and if f is surjective then
  it doesn't matter whether A is empty*)
lemma bij_image_INT: "bij f ==> f ` (INTER A B) = (INT x:A. f ` B x)"
apply (simp add: bij_def)
apply (simp add: inj_on_def surj_def, blast)
done

lemma surj_Compl_image_subset: "surj f ==> -(f`A) <= f`(-A)"
by (auto simp add: surj_def)

lemma inj_image_Compl_subset: "inj f ==> f`(-A) <= -(f`A)"
by (auto simp add: inj_on_def)

lemma bij_image_Compl_eq: "bij f ==> f`(-A) = -(f`A)"
apply (simp add: bij_def)
apply (rule equalityI)
apply (simp_all (no_asm_simp) add: inj_image_Compl_subset surj_Compl_image_subset)
done


subsection{*Function Updating*}

lemma fun_upd_idem_iff: "(f(x:=y) = f) = (f x = y)"
apply (simp add: fun_upd_def, safe)
apply (erule subst)
apply (rule_tac [2] ext, auto)
done

(* f x = y ==> f(x:=y) = f *)
lemmas fun_upd_idem = fun_upd_idem_iff [THEN iffD2, standard]

(* f(x := f x) = f *)
lemmas fun_upd_triv = refl [THEN fun_upd_idem]
declare fun_upd_triv [iff]

lemma fun_upd_apply [simp]: "(f(x:=y))z = (if z=x then y else f z)"
by (simp add: fun_upd_def)

(* fun_upd_apply supersedes these two,   but they are useful
   if fun_upd_apply is intentionally removed from the simpset *)
lemma fun_upd_same: "(f(x:=y)) x = y"
by simp

lemma fun_upd_other: "z~=x ==> (f(x:=y)) z = f z"
by simp

lemma fun_upd_upd [simp]: "f(x:=y,x:=z) = f(x:=z)"
by (simp add: expand_fun_eq)

lemma fun_upd_twist: "a ~= c ==> (m(a:=b))(c:=d) = (m(c:=d))(a:=b)"
by (rule ext, auto)

lemma inj_on_fun_updI: "\<lbrakk> inj_on f A; y \<notin> f`A \<rbrakk> \<Longrightarrow> inj_on (f(x:=y)) A"
by(fastsimp simp:inj_on_def image_def)

lemma fun_upd_image:
     "f(x:=y) ` A = (if x \<in> A then insert y (f ` (A-{x})) else f ` A)"
by auto

subsection{* @{text override_on} *}

lemma override_on_emptyset[simp]: "override_on f g {} = f"
by(simp add:override_on_def)

lemma override_on_apply_notin[simp]: "a ~: A ==> (override_on f g A) a = f a"
by(simp add:override_on_def)

lemma override_on_apply_in[simp]: "a : A ==> (override_on f g A) a = g a"
by(simp add:override_on_def)

subsection{* swap *}

definition
  swap :: "'a \<Rightarrow> 'a \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b)"
where
  "swap a b f = f (a := f b, b:= f a)"

lemma swap_self: "swap a a f = f"
by (simp add: swap_def)

lemma swap_commute: "swap a b f = swap b a f"
by (rule ext, simp add: fun_upd_def swap_def)

lemma swap_nilpotent [simp]: "swap a b (swap a b f) = f"
by (rule ext, simp add: fun_upd_def swap_def)

lemma inj_on_imp_inj_on_swap:
  "[|inj_on f A; a \<in> A; b \<in> A|] ==> inj_on (swap a b f) A"
by (simp add: inj_on_def swap_def, blast)

lemma inj_on_swap_iff [simp]:
  assumes A: "a \<in> A" "b \<in> A" shows "inj_on (swap a b f) A = inj_on f A"
proof 
  assume "inj_on (swap a b f) A"
  with A have "inj_on (swap a b (swap a b f)) A" 
    by (iprover intro: inj_on_imp_inj_on_swap) 
  thus "inj_on f A" by simp 
next
  assume "inj_on f A"
  with A show "inj_on (swap a b f) A" by (iprover intro: inj_on_imp_inj_on_swap)
qed

lemma surj_imp_surj_swap: "surj f ==> surj (swap a b f)"
apply (simp add: surj_def swap_def, clarify)
apply (rule_tac P = "y = f b" in case_split_thm, blast)
apply (rule_tac P = "y = f a" in case_split_thm, auto)
  --{*We don't yet have @{text case_tac}*}
done

lemma surj_swap_iff [simp]: "surj (swap a b f) = surj f"
proof 
  assume "surj (swap a b f)"
  hence "surj (swap a b (swap a b f))" by (rule surj_imp_surj_swap) 
  thus "surj f" by simp 
next
  assume "surj f"
  thus "surj (swap a b f)" by (rule surj_imp_surj_swap) 
qed

lemma bij_swap_iff: "bij (swap a b f) = bij f"
by (simp add: bij_def)


subsection {* Order and lattice on functions *}

instance "fun" :: (type, ord) ord
  le_fun_def: "f \<le> g \<equiv> \<forall>x. f x \<le> g x"
  less_fun_def: "f < g \<equiv> f \<le> g \<and> f \<noteq> g" ..

lemmas [code func del] = le_fun_def less_fun_def

instance "fun" :: (type, order) order
  by default
    (auto simp add: le_fun_def less_fun_def expand_fun_eq
       intro: order_trans order_antisym)

lemma le_funI: "(\<And>x. f x \<le> g x) \<Longrightarrow> f \<le> g"
  unfolding le_fun_def by simp

lemma le_funE: "f \<le> g \<Longrightarrow> (f x \<le> g x \<Longrightarrow> P) \<Longrightarrow> P"
  unfolding le_fun_def by simp

lemma le_funD: "f \<le> g \<Longrightarrow> f x \<le> g x"
  unfolding le_fun_def by simp

text {*
  Handy introduction and elimination rules for @{text "\<le>"}
  on unary and binary predicates
*}

lemma predicate1I [Pure.intro!, intro!]:
  assumes PQ: "\<And>x. P x \<Longrightarrow> Q x"
  shows "P \<le> Q"
  apply (rule le_funI)
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate1D [Pure.dest, dest]: "P \<le> Q \<Longrightarrow> P x \<Longrightarrow> Q x"
  apply (erule le_funE)
  apply (erule le_boolE)
  apply assumption+
  done

lemma predicate2I [Pure.intro!, intro!]:
  assumes PQ: "\<And>x y. P x y \<Longrightarrow> Q x y"
  shows "P \<le> Q"
  apply (rule le_funI)+
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate2D [Pure.dest, dest]: "P \<le> Q \<Longrightarrow> P x y \<Longrightarrow> Q x y"
  apply (erule le_funE)+
  apply (erule le_boolE)
  apply assumption+
  done

lemma rev_predicate1D: "P x ==> P <= Q ==> Q x"
  by (rule predicate1D)

lemma rev_predicate2D: "P x y ==> P <= Q ==> Q x y"
  by (rule predicate2D)

instance "fun" :: (type, lattice) lattice
  inf_fun_eq: "inf f g \<equiv> (\<lambda>x. inf (f x) (g x))"
  sup_fun_eq: "sup f g \<equiv> (\<lambda>x. sup (f x) (g x))"
apply intro_classes
unfolding inf_fun_eq sup_fun_eq
apply (auto intro: le_funI)
apply (rule le_funI)
apply (auto dest: le_funD)
apply (rule le_funI)
apply (auto dest: le_funD)
done

lemmas [code func del] = inf_fun_eq sup_fun_eq

instance "fun" :: (type, distrib_lattice) distrib_lattice
  by default (auto simp add: inf_fun_eq sup_fun_eq sup_inf_distrib1)


subsection {* Proof tool setup *} 

text {* simplifies terms of the form
  f(...,x:=y,...,x:=z,...) to f(...,x:=z,...) *}

ML {*
let
  fun gen_fun_upd NONE T _ _ = NONE
    | gen_fun_upd (SOME f) T x y = SOME (Const (@{const_name fun_upd},T) $ f $ x $ y)
  fun dest_fun_T1 (Type (_, T :: Ts)) = T
  fun find_double (t as Const (@{const_name fun_upd},T) $ f $ x $ y) =
    let
      fun find (Const (@{const_name fun_upd},T) $ g $ v $ w) =
            if v aconv x then SOME g else gen_fun_upd (find g) T v w
        | find t = NONE
    in (dest_fun_T1 T, gen_fun_upd (find f) T x y) end
  fun fun_upd_prover ss =
    rtac eq_reflection 1 THEN rtac ext 1 THEN
    simp_tac (Simplifier.inherit_context ss @{simpset}) 1
  val fun_upd2_simproc =
    Simplifier.simproc @{theory}
      "fun_upd2" ["f(v := w, x := y)"]
      (fn _ => fn ss => fn t =>
        case find_double t of (T, NONE) => NONE
        | (T, SOME rhs) =>
            SOME (Goal.prove (Simplifier.the_context ss) [] []
              (Term.equals T $ t $ rhs) (K (fun_upd_prover ss))))
in
  Addsimprocs [fun_upd2_simproc]
end;
*}


subsection {* Code generator setup *}

code_const "op \<circ>"
  (SML infixl 5 "o")
  (Haskell infixr 9 ".")

code_const "id"
  (Haskell "id")


subsection {* ML legacy bindings *} 

ML {*
val set_cs = claset() delrules [equalityI]
*}

ML {*
val id_apply = @{thm id_apply}
val id_def = @{thm id_def}
val o_apply = @{thm o_apply}
val o_assoc = @{thm o_assoc}
val o_def = @{thm o_def}
val injD = @{thm injD}
val datatype_injI = @{thm datatype_injI}
val range_ex1_eq = @{thm range_ex1_eq}
val expand_fun_eq = @{thm expand_fun_eq}
*}

end
