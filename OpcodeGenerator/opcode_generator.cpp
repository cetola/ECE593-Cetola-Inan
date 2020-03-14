#include "opcode_generator.h"
#include <stdlib.h>
#include <string.h>

uint32_t reg1, reg2, destReg, arithVal1, arithVal2;

/*
 * Initialize some basic values to avoid errors
 */
extern "C" void initGen(void)
{
    reg1 = 5;
    reg2 = 6;
    destReg = 7;
    arithVal1 = 1;
    arithVal2 = 2;
}

/*
 * Setter functions for registers and test values
 */
extern "C" void setReg(uint32_t v1, uint32_t v2, uint32_t, v3)
{
    reg1 = v1;
    reg2 = v2;
    destReg = v3;
}

extern "C" void setArith(uint32_t v1, uint32_t v2)
{
    arithVal1 = v1;
    arithVal2 = v2;
}

/*
Get Opcode Functions

This functions get opcodes by the type of operation. The deatils can be viewed
in the spec PDF in this repo, or online. See the readme for details.

*/

uint32_t get_arithmetic(arithmetic_op_t funct, uint32_t rs1, uint32_t rs2, uint32_t rd) //From page 19
{
    return (uint32_t)OPCODE_OP | (uint32_t)funct | (rd << 7) | (rs1 << 15) | (rs2 << 20);
}

uint32_t get_load(uint32_t rs1, uint32_t rd, uint32_t imm) //From page 24
{
    static const uint32_t funct3 = 0x04;   // LBU (no sign extend)
    return (uint32_t)OPCODE_LOAD | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (imm << 20);
}

uint32_t get_load32(uint32_t rs1, uint32_t rd, uint32_t imm) //From page 24
{
    static const uint32_t funct3 = 0x02;    // LW
    return (uint32_t)OPCODE_LOAD | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (imm << 20);
}

uint32_t get_store(uint32_t rs1, uint32_t rs2, uint32_t imm) //From page 24
{
    uint32_t imm_high = (imm >> 5) & 0x7F, imm_low = imm & 0x1F;
    return (uint32_t)OPCODE_STORE | (rs1 << 15) | (rs2 << 20) | (imm_high << 25) | (imm_low << 7);
}

uint32_t get_cond_branch(uint32_t rs1, uint32_t rs2, uint32_t imm) //From page 22
{
    uint32_t imm12 = (imm >> 12) & 1, imm5 = (imm >> 5) & 0x3F,
            imm1 = (imm >> 1) & 0xF, imm11 = (imm >> 11) & 1;
    return (uint32_t)OPCODE_BRANCH | (rs2 << 20) | (rs1 << 15) | (imm12 << 31) | (imm5 << 25) | (imm1 << 9) | (imm11 << 7);
}

uint32_t get_jal(uint32_t rd, uint32_t imm) //From page 21
{
    uint32_t imm1 = (imm >> 1) & 0x03FF, imm11 = (imm >> 11) & 1,
        imm12 = (imm > 12) & 0xFF, imm20 = (imm >> 20) & 1;
    return (uint32_t)OPCODE_JAL | (rd << 7) | (imm20 << 31) | (imm1 << 21) | (imm11 << 20) | (imm12 << 12);
}

extern "C" void make_loadstore_test(svBitVecVal *buf, uint32_t buf_words)
{
    if (buf_words > 256)
        buf_words = 256;
    const uint32_t TEST_ADDRESS = 0x000003fc;
    uint32_t *buf32 = (uint32_t *)buf;
    // Assuming little-endian
    // Load 0x12, 0x34, 0x56, 0x78 into x9, x8, x7, x6 respectively
    buf32[buf_words-1] = 0x12345678;
    buf32[0] = get_load(0, 6, 4*(buf_words-1));
    buf32[1] = get_load(0, 7, 4*(buf_words-1) + 1);
    buf32[2] = get_load(0, 8, 4*(buf_words-1) + 2);
    buf32[3] = get_load(0, 9, 4*(buf_words-1) + 3);
    for (uint32_t i = 4, reg = 0; i + 1 < buf_words - 2; i += 2, reg++)
    {
        buf32[i] = get_store(0, 6 + (reg % 4), TEST_ADDRESS);
        buf32[i+1] = get_load(0, 5, TEST_ADDRESS);
    }
    buf32[buf_words-2] = 0x00000067u;   // JALR $
}

extern "C" void make_test(arithmetic_op_t op, svBitVecVal *buf, uint32_t buf_words)
{
    if (buf_words > 256)
        buf_words = 256;
    uint32_t const_addr = 4 * (buf_words - 2);
    uint32_t *buf32 = (uint32_t *)buf;
    buf32[const_addr/4] = arithVal1;
    buf32[const_addr/4+1] = arithVal2;
    buf32[0] = get_load32(0, reg1, const_addr); //Load 2 constants into registers
    buf32[1] = get_load32(0, reg2, const_addr+4);
    for (uint32_t i = 2; i < const_addr/4; i++)
    {
        buf32[i] = get_arithmetic(op, reg1, reg2, destReg);
    }
    buf32[const_addr/4-1] = 0x00000067u;   // JALR $
}
