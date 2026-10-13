# Power Flow and Network Analysis

A MATLAB application for constructing bus admittance and impedance matrices, solving steady-state power flow, and exploring transient stability. Includes Gauss-Seidel, Newton-Raphson and fast-decoupled load-flow implementations and multiple example bus systems.

## Tools used

MATLAB, App Designer-style UI components, matrix calculations and iterative numerical methods.

## How to run

1. Make this folder the MATLAB current folder.
2. Run `power_flow_app`.
3. Select a network and calculation method.
4. Review bus quantities and plots. Start with a small network before comparing larger cases.

## Files

| File | Purpose |
| --- | --- |
| `power_flow_app.m` | Main graphical application |
| `Gauss_Seidel.m`, `Newton_Raphson.m`, `FDLF.m` | Power-flow methods |
| `Y_bus.m`, `Z_bus.m` | Network matrix construction |
| `st.m` | Transient-stability interface and calculation |
| `system*bus.m` | Example network data |
| Other `.m` files | Matrix helpers and system selection |

## Limitations

Convergence depends on the case data, initialization and solver assumptions. Example cases and numerical results have not been independently benchmarked against a reference power-system package.

## Project context

Prepared from academic project files. Collaborative work remains team work; personal names are omitted from this public copy. Original technical comments and interfaces may be in French. No new license has been assigned.

## Technical report

[Read the original French technical report](docs/power-flow-analysis-report.pdf). Personal names and document metadata were removed from this copy. Technical content is preserved and may describe earlier study settings.

## Verification status

Source structure and reference names were inspected. MATLAB startup did not complete in this environment, so MATLAB and Simulink execution could not be verified.
