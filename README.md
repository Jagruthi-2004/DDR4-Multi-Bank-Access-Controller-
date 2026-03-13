# DDR4-Multi-Bank-Access-Controller-
A Verilog HDL implementation of a DDR4 Memory Controller supporting 4 independent bank groups with FSM-based command sequencing for Read, Write, Activate, and Precharge operations.

Architecture Overview
                    ┌─────────────────────────────────┐
                    │   DDR4_mult_bank_access_Controller│
                    │                                   │
         addr ───►  │  ┌──────────┐  ┌──────────┐      │
         wdata ──►  │  │Bank Grp 0│  │Bank Grp 1│      │
         read_en ►  │  └──────────┘  └──────────┘      │
         write_en►  │  ┌──────────┐  ┌──────────┐      │
         bg_en ──►  │  │Bank Grp 2│  │Bank Grp 3│      │
                    │  └──────────┘  └──────────┘      │
                    │         Output MUX                │
                    └────────────┬────────────────────-─┘
                                 │
                         ddr4_dq, ddr4_addr,
                         ddr4_ba, ddr4_bg,
                         ddr4_ras_n/cas_n/we_n/cs_n



FSM State Diagram
        ┌──────┐
  ───►  │ IDLE │ ◄─────────────────┐
        └──┬───┘                   │
           │ read_en/write_en      │
           ▼                       │
        ┌──────────┐               │
        │ ACTIVATE │               │
        └──┬───────┘               │
           │                       │
     ┌─────┴──────┐                │
     ▼            ▼                │
  ┌──────┐    ┌───────┐            │
  │ READ │    │ WRITE │            │
  └──┬───┘    └───┬───┘            │
     └─────┬──────┘                │
           ▼                       │
        ┌──────────┐               │
        │PRECHARGE │ ──────────────┘
        └──────────┘
