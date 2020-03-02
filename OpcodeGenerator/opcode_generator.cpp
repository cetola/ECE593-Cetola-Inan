#include "opcode_generator.h"
#include <stdlib.h>
#include <string.h>

uint32_t get_register(void)
{
    uint32_t reg;
    do
    {
        reg = rand() % 32;
    } while (reg >= 1 && reg <= 4); // Registers x1-x4 are reserved
    return reg;
}

uint32_t get_imm12(void)
{
    if ((rand() % 2) == 0) //Half of the time it is 0, otherwise 12 bit value
        return 0;
    return (uint16_t)(rand() % 0x0FFF);
}

uint32_t get_imm20(void)
{
    if ((rand() % 2) == 0) //Half of the time is is 0, otherwise 20 bit value
        return 0;
    uint32_t value = rand();
#if RAND_MAX < 0x000FFFFF
    value ^= rand() << 15; //Or 15 bit random number with 15 bits shifted up
#endif
    return (uint16_t)(value % 0x000FFFFF); //Cuts bits down to 20
}

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

extern "C" uint32_t get_instruction(void)
{
    switch (rand() % 12)
    {
    case 0:	// LB
        return get_load(get_register(), get_register(), get_imm12());
    case 1:	// SB
        return get_store(get_register(), get_register(), get_imm12());
    case 2: // SLL
        return get_arithmetic(ARITH_SLL, get_register(), get_register(), get_register()); //Tells which arithmetc instruction does
    case 3: // SRL
        return get_arithmetic(ARITH_SRL, get_register(), get_register(), get_register());
    case 4: // ADD
        return get_arithmetic(ARITH_ADD, get_register(), get_register(), get_register());
    case 5: // SUB
        return get_arithmetic(ARITH_SUB, get_register(), get_register(), get_register());
    case 6: // XOR
        return get_arithmetic(ARITH_XOR, get_register(), get_register(), get_register());
    case 7: // OR
        return get_arithmetic(ARITH_OR, get_register(), get_register(), get_register());
    case 8: // AND
        return get_arithmetic(ARITH_AND, get_register(), get_register(), get_register());
    case 9: // BEQ
        return get_cond_branch(get_register(), get_register(), get_imm12());
    case 10:    // JAL
        return get_jal(get_register(), get_imm20());
    case 11:    // SCALL
        // TODO: not found in ISA reference
        return 0x00000033;  // NOP
    default:
        abort(); //If something should not happen
    }
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

extern "C" void make_add_test(svBitVecVal *buf, uint32_t buf_words)
{
    if (buf_words > 256)
        buf_words = 256;
    uint32_t const_addr = 4 * (buf_words - 2);
    uint32_t *buf32 = (uint32_t *)buf;
    buf32[const_addr/4] = 0x12; //This is a constant (second to last word)
    buf32[const_addr/4+1] = 0x3456; //This is also a constant (last word)
    buf32[0] = get_load32(0, 5, const_addr); //Load 2 constants into registers
    buf32[1] = get_load32(0, 6, const_addr+4);
    for (uint32_t i = 2; i < const_addr/4; i++)
    {
        buf32[i] = get_arithmetic(ARITH_ADD, 5, 6, 6);
    }
    buf32[const_addr/4-1] = 0x00000067u;   // JALR $
}

extern "C" void make_sub_test(svBitVecVal *buf, uint32_t buf_words)
{
    uint32_t *buf32 = (uint32_t *)buf;
    memset(buf32, 0, 4*buf_words);  // TODO
}

extern "C" void make_random_test(svBitVecVal *buf, uint32_t buf_words)
{
    uint32_t *buf32 = (uint32_t *)buf;
    memset(buf32, 0, 4*buf_words);  // TODO
}
