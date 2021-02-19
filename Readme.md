# ISA Definition Parser

This parser is used to parse ISA Definition File, which looks like:

```c
INST_CLASS(s_type, <7.imm11_5><5.rs2><5.rs1><3.funct3><5.imm4_0><7.opcode>) {
    DECODE() {
        simm32 = SIGN_EXT((imm11_5 << 5) | imm4_0, 11);
    }
    DISASM() {
        ASM_FORMAT("[inst] [rs2], [rs1], %d", simm32);
    }
}

INST(bne, <7.bimm12hi><5.rs2><5.rs1>001<5.bimm12lo>1100011) {
    EXECUTE() {
        if (GPR[rs1] != GPR[rs2])
            JUMP_TO(PC + simm32);
    }
}

```

## TODO

 * [] Clean up 'shift/reduce conflicts' in racc rules.

## Refer To

[Risc-v Spec](https://riscv.org/technical/specifications/)

[rexical github](https://github.com/tenderlove/rexical)
[racc github](https://github.com/ruby/racc)

[C Lang Spec](https://www2.cs.arizona.edu/~debray/Teaching/CSc453/DOCS/cminusminusspec.html)

