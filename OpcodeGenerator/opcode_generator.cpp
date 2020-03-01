#include "opcode_generator.h"
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

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

uint32_t get_arithmetic(arithmetic_op_t funct) //From page 19
{
    uint32_t rd = get_register(), rs1 = get_register(), rs2 = get_register();
    return (uint32_t)OPCODE_OP | (uint32_t)funct | (rd << 7) | (rs1 << 15) | (rs2 << 20);
}

uint32_t get_load(void) //From page 24
{
    uint32_t imm = get_imm12(), rd = get_register(), rs1 = get_register();
    return (uint32_t)OPCODE_LOAD | (rd << 7) | (rs1 << 15) | (imm << 20);
}

uint32_t get_store(void) //From page 24
{
    uint32_t imm = get_imm12(), rs1 = get_register(), rs2 = get_register();
    uint32_t imm_high = (imm >> 5) & 0x7F, imm_low = imm & 0x1F;
    return (uint32_t)OPCODE_STORE | (rs1 << 15) | (rs2 << 20) | (imm_high << 25) | (imm_low << 7);
}

uint32_t get_cond_branch(void) //From page 22
{
    uint32_t imm = get_imm12(), rs1 = get_register(), rs2 = get_register();
    uint32_t imm_12 = (imm >> 12) & 1, (imm5 >> 5) & 0x3F,
            imm1 = (imm >> 1) & 0xF, imm11 = (imm >> 11) & 1;
    return (uint32_t)OPCODE_BRANCH | (rs2 << 20) | (rs1 << 15) | (imm12 << 31) | (imm5 << 25) | (imm1 << 9) | (imm11 << 7);
}

uint32_t get_jal(void) //From page 21
{
    uint32_t imm = get_imm20(), rd = get_register();
    uint32_t imm1 = (imm >> 1) & 0x03FF, imm11 = (imm >> 11) & 1,
        imm12 = (imm > 12) & 0xFF, imm20 = (imm >> 20) & 1;
    return (uint32_t)OPCODE_JAL | (rd << 7) | (imm20 << 31) | (imm1 << 21) | (imm11 << 20) | (imm12 << 12);
}

uint32_t get_instruction(void)
{
    switch (rand() % 12)
    {
    case 0:	// LB
        return get_load();
    case 1:	// SB
        return get_store();
    case 2: // SLL
        return get_arithmetic(ARITH_SLL); //Tells which arithmetc instruction does
    case 3: // SRL
        return get_arithmetic(ARITH_SRL);
    case 4: // ADD
        return get_arithmetic(ARITH_ADD);
    case 5: // SUB
        return get_arithmetic(ARITH_SUB);
    case 6: // XOR
        return get_arithmetic(ARITH_XOR);
    case 7: // OR
        return get_arithmetic(ARITH_OR);
    case 8: // AND
        return get_arithmetic(ARITH_AND);
    case 9: // BEQ
        return get_cond_branch();
    case 10:    // JAL
        return get_jal();
    case 11:    // SCALL
        // TODO: not found in ISA reference
        return 0x00000033;  // NOP
    default:
        abort(); //If something should not happen
    }
}

#ifdef __cplusplus
}
#endif
