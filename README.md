# Verify Ibex Pedagogically (VIP)

## Testing the Ibex core in a didactic world.

Ibex is a 2-stage in-order 32b RISC-V processor core. Ibex has been designed to be small and efficient. ​Figure 1 shows a block diagram of the core. Via two parameters, the core is configurable to support four ISA configurations:

1. RV32E [bit] Embedded mode on or off (16 integer registers only)
2. RV32M [bit] Mult/Div on or off

We will ignore two of these configurations (register RV32E). We will start with RV32M off and will use the last configuration (RV32M on) as a stretch goal. We will most likely ignore Physical Memory Protection (PMP) unless we find ourselves with completed stretch goals.
