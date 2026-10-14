# Power Flow and Network Analysis

I developed a MATLAB application for power-flow and transient-stability studies, with network matrices, iterative solvers and plots of generator rotor-angle response.

## Main features

- Builds bus admittance and impedance matrices.
- Solves power flow using Gauss-Seidel, Newton-Raphson and Fast Decoupled Load Flow.
- Explores generator rotor-angle behavior after a network disturbance.
- Provides example networks from small teaching systems to larger bus configurations.

## Results

Figures from the [technical report](docs/power-flow-analysis-report.pdf) show the influence of fault-clearing time on generator dynamics in the six-bus study.

### Fault cleared at 0.4 seconds

![Generator rotor-angle response after fault clearing at 0.4 seconds](docs/results/stable-rotor-angle-response.png)

### Fault cleared at 0.5 seconds

![Generator rotor-angle response after fault clearing at 0.5 seconds](docs/results/rotor-angle-response.png)

## Tools

MATLAB, numerical linear algebra, iterative power-flow methods and time-domain simulation.

## Run

Open this folder in MATLAB and run:

```matlab
power_flow_app
```

Select a network, configure its data and choose an analysis method.

## Project files

| File | Purpose |
| --- | --- |
| `power_flow_app.m` | Application entry point |
| `Gauss_Seidel.m`, `Newton_Raphson.m`, `FDLF.m` | Power-flow solvers |
| `Y_bus.m`, `Z_bus.m` | Network matrices |
| `st.m` | Transient-stability study |
| `system*.m` | Example bus systems |

Academic group project at the National Polytechnic School of Algiers.
