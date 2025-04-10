// SPDX-License-Identifier: GPL-2.0
/*
 * Copyright (C) 2025 Xi Ruoyao <xry111@xry111.site>. All Rights Reserved.
 *
 * Based on https://lore.kernel.org/all/20250224122541.65045-1-xry111@xry111.site/.
 * Based on arch/loongarch/vdso/vgetrandom-chacha.S.
 */

#define SZREG 8
#define REG_S sd
#define REG_L ld

.text

.option	arch, +zbb
.macro	ROTRI	rd rs imm
	roriw	\rd, \rs, \imm
.endm

.macro	OP_4REG	op d0 d1 d2 d3 s0 s1 s2 s3
	\op	\d0, \d0, \s0
	\op	\d1, \d1, \s1
	\op	\d2, \d2, \s2
	\op	\d3, \d3, \s3
.endm

/*
 *	a0: output bytes
 * 	a1: input bytes
 */
.global chacha20
.type chacha20, @function
.align 1
chacha20:

#define output		a0
#define input		a1
#define i		a2
#define state0		a3
#define state1		a4
#define state2		a5
#define state3		a6
#define state4		a7
#define state5		t0
#define state6		t1
#define state7		t2
#define state8		t3
#define state9		t4
#define state10		t5
#define state11		t6
#define state12		s0
#define state13		s1
#define state14		s2
#define state15		s3
#define copy0		s4
#define copy1		s5
#define copy2		s6
#define copy3		s7

/* Packs to be used with OP_4REG */
#define line0		state0, state1, state2, state3
#define line1		state4, state5, state6, state7
#define line2		state8, state9, state10, state11
#define line3		state12, state13, state14, state15

#define line1_perm	state5, state6, state7, state4
#define line2_perm	state10, state11, state8, state9
#define line3_perm	state15, state12, state13, state14

#define copy		copy0, copy1, copy2, copy3

#define _16		16, 16, 16, 16
#define _20		20, 20, 20, 20
#define _24		24, 24, 24, 24
#define _25		25, 25, 25, 25

	addi		sp, sp, -8*SZREG
	REG_S		s0,         (sp)
	REG_S		s1,    SZREG(sp)
	REG_S		s2,  2*SZREG(sp)
	REG_S		s3,  3*SZREG(sp)
	REG_S		s4,  4*SZREG(sp)
	REG_S		s5,  5*SZREG(sp)
	REG_S		s6,  6*SZREG(sp)
	REG_S		s7,  7*SZREG(sp)

	lw		state0, (input)
	lw		state1, 4(input)
	lw		state2, 8(input)
	lw		state3, 12(input)
	mv		copy0, state0
	mv		copy1, state1
	mv		copy2, state2
	mv		copy3, state3
	lw		state4, 16(input)
	lw		state5, 20(input)
	lw		state6, 24(input)
	lw		state7, 28(input)
	lw		state8, 32(input)
	lw		state9, 36(input)
	lw		state10, 40(input)
	lw		state11, 44(input)
	lw		state12, 48(input)
	lw		state13, 52(input)
	lw		state14, 56(input)
	lw		state15, 60(input)

	li		i, 10
	.p2align	4
.Lpermute:
	/* odd round */
	OP_4REG	addw	line0, line1
	OP_4REG	xor	line3, line0
	OP_4REG	ROTRI	line3, _16

	OP_4REG	addw	line2, line3
	OP_4REG	xor	line1, line2
	OP_4REG	ROTRI	line1, _20

	OP_4REG	addw	line0, line1
	OP_4REG	xor	line3, line0
	OP_4REG	ROTRI	line3, _24

	OP_4REG	addw	line2, line3
	OP_4REG	xor	line1, line2
	OP_4REG	ROTRI	line1, _25

	/* even round */
	OP_4REG	addw	line0, line1_perm
	OP_4REG	xor	line3_perm, line0
	OP_4REG	ROTRI	line3_perm, _16

	OP_4REG	addw	line2_perm, line3_perm
	OP_4REG	xor	line1_perm, line2_perm
	OP_4REG	ROTRI	line1_perm, _20

	OP_4REG	addw	line0, line1_perm
	OP_4REG	xor	line3_perm, line0
	OP_4REG	ROTRI	line3_perm, _24

	OP_4REG	addw	line2_perm, line3_perm
	OP_4REG	xor	line1_perm, line2_perm
	OP_4REG	ROTRI	line1_perm, _25

	addi		i, i, -1
	bnez		i, .Lpermute

	OP_4REG	addw	line0, copy
	sw		state0, (output)
	sw		state1, 4(output)
	sw		state2, 8(output)
	sw		state3, 12(output)

	lw		copy0, 16(input)
	lw		copy1, 20(input)
	lw		copy2, 24(input)
	lw		copy3, 28(input)
	OP_4REG	addw	line1, copy
	sw		state4, 16(output)
	sw		state5, 20(output)
	sw		state6, 24(output)
	sw		state7, 28(output)

	lw		copy0, 32(input)
	lw		copy1, 36(input)
	lw		copy2, 40(input)
	lw		copy3, 44(input)
	OP_4REG	addw	line2, copy
	sw		state8, 32(output)
	sw		state9, 36(output)
	sw		state10, 40(output)
	sw		state11, 44(output)

	lw		copy0, 48(input)
	lw		copy1, 52(input)
	lw		copy2, 56(input)
	lw		copy3, 60(input)
	OP_4REG	addw	line3, copy
	sw		state12, 48(output)
	sw		state13, 52(output)
	sw		state14, 56(output)
	sw		state15, 60(output)

	REG_L		s0,         (sp)
	REG_L		s1,    SZREG(sp)
	REG_L		s2,  2*SZREG(sp)
	REG_L		s3,  3*SZREG(sp)
	REG_L		s4,  4*SZREG(sp)
	REG_L		s5,  5*SZREG(sp)
	REG_L		s6,  6*SZREG(sp)
	REG_L		s7,  7*SZREG(sp)
	addi		sp, sp, 8*SZREG

	ret

# vim: ts=8
