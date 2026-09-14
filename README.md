# AXI4 UVM Verification

A UVM-based verification environment for an AXI4 memory system, developed by migrating a previously verified class-based SystemVerilog testbench into a reusable and scalable UVM architecture.

The project uses standard UVM methodology including sequences, sequencers, drivers, monitors, agents, analysis ports, configuration mechanisms, factory overrides, scoreboarding, reference modeling, functional coverage, and SystemVerilog Assertions.

---

## Verification Architecture

![UVM Verification Architecture](docs/UVM%20ARC.png)

The verification environment contains two main verification paths:

### Active AXI Agent

The active AXI agent generates and monitors AXI traffic and contains:

```text
AXI Agent
│
├── Sequencer
├── Driver
└── Monitor
```

AXI transactions follow the standard UVM flow:

```text
Sequence
   ↓
Sequencer
   ↓
Driver
   ↓
AXI Interface
   ↓
DUT
   ↓
Monitor
   ├──→ Scoreboard
   └──→ Functional Coverage
```

### Passive Memory Agent

A separate passive memory agent observes the internal memory-side interface without driving any signals.

```text
Memory Agent
│
└── Memory Monitor
       ├──→ Memory Checker
       └──→ Memory Coverage
```

This provides an additional verification layer for checking the internal DUT-to-memory behavior independently from the AXI bus.

---

## Migration from Class-Based Verification

This project represents the migration of an already verified class-based SystemVerilog environment into UVM.

The corrected RTL, AXI interface, and assertions from the previous verification stage were reused as the stable baseline.

The previous manual class-based architecture was reorganized using standard UVM mechanisms:

- Mailbox-based stimulus transfer → **Sequence / Sequencer protocol**
- Manual object creation → **UVM Factory**
- Manual interface passing → **`uvm_config_db`**
- Monitor mailboxes → **UVM Analysis Ports**
- Manual environment execution → **UVM Phases**
- Generator-based stimulus → **Reusable UVM Sequences**
- Monolithic verification structure → **Reusable UVM Agents and Environment**

The goal of this stage was therefore not to redesign the DUT, but to restructure the verification environment using an industry-standard UVM methodology.

---

## UVM Components

### AXI Sequence Item

The AXI transaction object represents complete READ and WRITE operations including:

- Operation type
- Address
- Burst length
- Transfer size
- Write data
- Read data
- AXI response
- Last-beat information

Transactions are created through the UVM Factory and used consistently across the sequence, driver, monitor, scoreboard, and coverage components.

### AXI Sequences

The environment includes directed verification scenarios for:

- Single write
- Single read
- Burst write
- Burst read
- Invalid-address transactions
- 4-KB boundary-crossing transactions
- Coverage-closure scenarios
- Assertion-stress and backpressure scenarios

### AXI Driver

The UVM driver converts high-level AXI transactions into signal-level AXI channel activity.

It uses the standard sequencer-driver handshake:

```systemverilog
seq_item_port.get_next_item(tr);
...
seq_item_port.item_done();
```

### AXI Monitor

The monitor passively observes AXI transactions and reconstructs completed bus activity into transaction objects.

Observed transactions are published using a UVM analysis port so they can be consumed independently by the scoreboard and functional coverage components.

### Reference Model

The reference model maintains an independent software representation of the memory and predicts:

- Expected write behavior
- Expected read data
- Expected AXI response
- Expected burst address sequence
- Valid and invalid transaction behavior
- 4-KB boundary behavior

### AXI Scoreboard

The scoreboard compares monitored DUT behavior against the independent reference model.

Checks include:

- Write response
- Read response
- Burst length
- RDATA values
- Expected address sequence
- WLAST behavior
- RLAST behavior

---

## Factory Override and Delayed Driver

A dedicated `axi_driver_delay` component was implemented to extend the original AXI driver.

The delayed driver is selected using a **UVM Factory Override**, allowing the driver implementation to be replaced without modifying the AXI agent architecture.

This driver introduces controlled, protocol-legal delays and backpressure to exercise AXI stability assertions under realistic stall conditions.

The factory override demonstrates one of the main advantages of UVM: component behavior can be customized while preserving the reusable testbench structure.

---

## Functional Coverage

### AXI Functional Coverage

The AXI coverage model measures:

- READ and WRITE operations
- Valid and invalid addresses
- 4-KB boundary crossing
- Burst lengths
- Transfer sizes
- AXI responses
- Important cross-coverage combinations

Final result:

**100% AXI Functional Coverage — 44/44 bins covered**

### Memory Functional Coverage

The passive memory verification environment independently collects coverage for internal memory activity.

Final result:

**100% Memory Functional Coverage — 16/16 bins covered**

---

## SystemVerilog Assertions

Protocol assertions are used to verify AXI signal stability and correct channel behavior.

The final delayed-driver regression intentionally generated legal stall and backpressure conditions so that previously vacuous stability properties became actively exercised.

Final result:

**100% Assertion Coverage — 16/16 assertions**

with:

**0 assertion failures**

---

## Final Verification Results

| Metric | Final Result |
| --- | ---: |
| AXI Scoreboard | **39 PASS / 0 FAIL** |
| AXI Functional Coverage | **100% (44/44 bins)** |
| Memory Functional Coverage | **100% (16/16 bins)** |
| Assertion Coverage | **100% (16/16 assertions)** |
| Memory Writes Observed | **87** |
| Memory Reads Observed | **87** |
| Successful Memory Read Comparisons | **87** |
| Memory Checker Failures | **0** |
| UVM Warnings | **0** |
| UVM Errors | **0** |
| UVM Fatals | **0** |

The final regression verified the DUT under normal operation, delayed handshakes, and protocol-legal backpressure conditions while maintaining complete functional and assertion coverage.

---

## Repository Structure

```text
AXI4-UVM-Verification/
│
├── rtl/
│   ├── axi4.v
│   └── axi_memory.v
│
├── tb/
│   ├── axi_agent.sv
│   ├── axi_assertions.sv
│   ├── axi_coverage.sv
│   ├── axi_driver.sv
│   ├── axi_driver_delay.sv
│   ├── axi_environment.sv
│   ├── axi_interface.sv
│   ├── axi_monitor.sv
│   ├── axi_reference_model.sv
│   ├── axi_scoreboard.sv
│   ├── axi_sequence.sv
│   ├── axi_sequence_item.sv
│   ├── axi_sequencer.sv
│   ├── axi_tb_top.sv
│   ├── axi_test.sv
│   ├── axi_transaction.sv
│   ├── axi_uvm_pkg.sv
│   │
│   ├── memory_agent.sv
│   ├── memory_checker.sv
│   ├── memory_coverage.sv
│   ├── memory_interface.sv
│   ├── memory_monitor.sv
│   └── memory_transaction.sv
│
├── sim/
│   └── run.do
│
├── docs/
│   ├── Sondos_Ahmed_UVM_project.docx
│   └── UVM ARC.png
│
└── README.md
```

---

## Technical Report

A detailed project report containing the implementation steps, component-level explanations, simulation evidence, and final verification closure is included in the repository.

[View Full Technical Report](docs/Sondos_Ahmed_UVM_project.docx)

---

## Tools and Technologies

**SystemVerilog • UVM • SVA • AXI4 • QuestaSim • UVM Factory • Analysis Ports • Functional Coverage • Reference Modeling • Scoreboarding**

---

## Key Concepts Demonstrated

- UVM testbench architecture
- UVM sequences and sequencers
- Active and passive agents
- UVM Factory registration and override
- `uvm_config_db`
- Analysis ports and subscribers
- Independent reference modeling
- Self-checking scoreboards
- Functional and cross coverage
- SystemVerilog Assertions
- Legal AXI backpressure
- Coverage-driven verification
- Reusable verification components

---

## Key Takeaway

This project demonstrates the transition from a working class-based verification environment to a structured and reusable UVM architecture.

The final environment combines an active AXI verification path, an independent reference model and scoreboard, a passive memory verification path, functional coverage, assertions, and factory-based driver customization.

The final regression achieved complete AXI functional coverage, memory functional coverage, and assertion coverage with zero scoreboard failures and zero UVM errors.
