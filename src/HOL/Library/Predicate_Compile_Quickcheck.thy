(* Author: Lukas Bulwahn, TU Muenchen *)

header {* A Prototype of Quickcheck based on the Predicate Compiler *}

theory Predicate_Compile_Quickcheck
imports Main Predicate_Compile_Alternative_Defs
begin

ML_file "../Tools/Predicate_Compile/predicate_compile_quickcheck.ML"

setup {* Predicate_Compile_Quickcheck.setup *}

end
