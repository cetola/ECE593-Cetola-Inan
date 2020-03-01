CFLAGS?=-g -O2 -Wall
CXXFLAGS?=-g -O2 -Wall
CC:=$(CXX)
LD:=$(CXX)

all: opcode_generator

opcode_generator: main.o opcode_generator.o

clean:
	-rm -f opcode_generator *.o

.PHONY: clean all
