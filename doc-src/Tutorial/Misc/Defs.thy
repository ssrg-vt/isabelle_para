Defs = Types +
consts nand, exor :: gate
defs nand_def "nand A B == ~(A & B)"
     exor_def "exor A B == A & ~B | ~A & B"
end
