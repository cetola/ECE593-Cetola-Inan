// opcode_generator.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include "opcode_generator.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void print_instruction(uint32_t word)
{
    uint8_t opcode = word & 0x7F;
    printf("opcode=0x%08x op=0x%02x ", word, opcode);
    switch (opcode)
    {
    case OPCODE_OP:
        printf("R-type rd=%d rs1=%d rs2=%d funct3=0x%x funct7=0x%x\n",
            (word >> 7) & 0x1F,
            (word >> 15) & 0x1F,
            (word >> 20) & 0x1F,
            (word >> 12) & 0x07,
            (word >> 25) & 0x7F);
        break;
    case OPCODE_LOAD:
        printf("I-type (LOAD) rd=%d rs1=%d funct3=%d imm=0x%x\n",
            (word >> 7) & 0x1F,
            (word >> 15) & 0x1F,
            (word >> 12) & 0x07,
            (word >> 20) & 0x0FFF);
        break;
    case OPCODE_STORE:
    {
        uint32_t imm_high = (word >> 25) & 0x7F, imm_low = (word >> 7) & 0x1F;
        printf("S-type (STORE) rs1=%d rs2=%d funct3=%d imm=0x%x\n",
            (word >> 15) & 0x1F,
            (word >> 20) & 0x1F,
            (word >> 12) & 0x07,
            (imm_high << 5) | imm_low);
        break;
    }
    case OPCODE_BRANCH:
    {
        uint32_t imm12 = (word >> 31) & 1, imm5 = (word >> 25) & 0x3F,
            imm1 = (word >> 8) & 0x0F, imm11 = (word >> 7) & 1;
        printf("B-type rs1=%d rs2=%d funct3=%d imm=0x%x\n",
            (word >> 15) & 0x1F,
            (word >> 20) & 0x1F,
            (word >> 12) & 0x07,
            (imm1 << 1) | (imm5 << 5) | (imm11 << 11) | (imm12 << 12));
        break;
    }
    case OPCODE_JAL:
    {
        uint32_t imm20 = (word >> 31) & 1, imm1 = (word >> 21) & 0x3FF,
            imm11 = (word >> 20) & 1, imm12 = (word >> 12) & 0xFF;
        printf("J-type (JAL) rd=%d imm=0x%x\n",
            (word >> 7) & 0x1F,
            (imm1 << 1) | (imm11 << 11) | (imm12 << 12) | (imm20 << 20));
        break;
    }
    default:
        puts(" (unrecognized instruction)");
        break;
    }
}

int main()
{
#if 0
    srand((unsigned int)time(NULL));
    for (int i = 0; i < 100; i++)
    {
        uint32_t word = get_instruction();
        print_instruction(word);
    }
#endif
    uint32_t buf[64];
    //make_loadstore_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_add_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_sub_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_xor_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_and_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_or_test(buf, sizeof(buf)/sizeof(uint32_t));
    //make_sll_test(buf, sizeof(buf)/sizeof(uint32_t));
    make_srl_test(buf, sizeof(buf)/sizeof(uint32_t));
    for (int i = 0; i < 64; i++)
    {
        printf("0x%04x: ", i * 4);
        print_instruction(buf[i]);
    }
    return 0;
}
