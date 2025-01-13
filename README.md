# CHEER/Power V1.0 Power System Optimization Model

This repository contains the source code for **CHEER/Power V1.0**, a power system optimization model for China at the provincial level, along with a case scenario input file. Users can refer to and run the model using these files. The CHEER/Power source code is built using the JuMP modeling package in Julia. Most variable names, constraints, and the format of input/output files are based on the open-source [**SWITCH**](https://github.com/switch-model) and [**SWITCH-China**](https://github.com/switch-model/switch-china-open-model) model, which is developed using the Python Pyomo package. We would like to express our deep respect for the SWITCH team’s hard work and open-source contributions.

To use this model, follow the instructions below after downloading the entire GitHub repository:

## Software and Package Configuration

### Solving the CHEER/Power model using Python to call Julia-based code

- **Python version**: 3.9.*
- The following packages are required:
  1. `julia >= 0.6.2`
  2. `pandas == 2.1.0`
  3. `numpy == 1.26.4`

### Running CHEER/Power code written in Julia

- **Julia version**: 1.8.0
- Install the following packages:
  1. `JuMP`
  2. `Gurobi`
  3. `CSV`
  4. `DataFrames`

### Installing the Gurobi Solver

Please visit the [Gurobi website](https://www.gurobi.com/) to install the Gurobi solver, which is necessary to use the Gurobi package in Julia for solving the CHEER/Power model.

## Model Input Files

The `case/inputs` folder contains the model’s input files, with the following key files to focus on:

1. **periods.csv**: Provides model period-related parameters
2. **timeseries.csv**: Provides typical day-related parameters
3. **timepoints.csv**: Provides typical hour-related parameters
4. **gen_build_predetermined.csv**: Provides historical generation capacity prior to the simulation period
5. **gen_build_costs.csv**: Provides investment and fixed operational costs for each power generation project
6. **ccs_install_costs.csv**: Provides investment and fixed operational costs for CCS retrofit for each power generation project across different periods
7. **load_zones.csv**: Provides information about study zones
8. **loads.csv**: Provides demand load information for each region
9. **gen_info.csv**: Provides information on each power generation project
10. **variable_capacity_factors.csv**: Provides output curves for renewable energy sources (VRE) in typical hours
11. **hydro_timeseries.csv**: Provides hydroelectric generation output for typical days
12. **fuel_cost.csv**: Provides fuel price information
13. **fuel_supply_curves.csv**: Provides biomass fuel prices and potential information
14. **transmission_lines.csv**: Provides capacity and cost information for inter-provincial transmission lines
15. **carbon_policies.csv**: Provides carbon constraints and carbon pricing constraints
16. **total_capacity_limits.csv**: Provides total generation capacity limits for each energy type
17. **capacity_plans.csv**: Provides lower limits for generation capacity by technology in each region
18. **build_tx_limits.csv**: Provides transmission network capacity constraints for each region
19. **gen_ccs_energy_load.csv**: Provides energy penalty rates for CCS technology

## Running the Model

Once the input files are confirmed, run the `run.py` file to solve the model.

## Simulation Results

After running the model, the `case/outputs` folder will contain the following output files:

1. **BuildGen.csv**: Provides the newly added generation capacity (including energy storage projects) for each period and each generation project
2. **BuildStorageEnergy.csv**: Provides the newly added storage capacity for each period and each energy storage project
3. **BuildTx.csv**: Provides the total installation capacity for each transmission project for each period
4. **Retrofit_Retirement.csv**: Provides the cumulative CCS retrofit and early retirement capacity for each thermal power project in each period
5. **New_Retrofit_Retirement.csv**: Provides the newly added CCS retrofit and early retirement capacity for each thermal power project in each period
6. **dispatch.csv**: Provides dispatch information for each power generation and storage project at typical time points
7. **load_balance.csv**: Provides power supply and demand balance information for each region’s grid
8. **electricity_cost.csv**: Provides the total system cost for each period
9. **gen_project_annual_summary.csv**: Provides capacity, generation, emissions, and cost information for each generation project across each period
