# CROCO | Non-hydrostatic coastal wave and sediment modelling

![MATLAB](https://img.shields.io/badge/MATLAB-R2019b-orange) ![CROCO](https://img.shields.io/badge/CROCO-2.1.3-blue) ![CROCO_TOOLS](https://img.shields.io/badge/CROCO_TOOLS-2.1.1-blue) ![NetCDF](https://img.shields.io/badge/NetCDF-model%20I%2FO-4c78a8) ![MPI](https://img.shields.io/badge/MPI-parallel%20simulations-6a5acd) ![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash&logoColor=white)

## Overview

This directory documents work undertaken during a short-term industrial collaboration with **Weather Water Sand (WWS)**, focused on developing a non-hydrostatic, wave-resolving coastal configuration using [CROCO (Coastal and Regional Ocean COmmunity model)](https://gitlab.inria.fr/croco-ocean).

Starting from a laboratory-scale CROCO/[SWASH](https://croco-ocean.gitlabpages.inria.fr/croco_doc/model/model.test_cases.swash.html) reference test case, the configuration was progressively adapted toward field-scale coastal conditions.

I had several hydrodynamic simulations and few additional sediment-enabled simulations involving storm conditions with 1-year and 5-year return periods. Relevant wave-forcing parameters were informed by output from the [SWAN](https://swanmodel.sourceforge.io/) wave model. The repository focuses on reproducible workflows and selected project scripts, rather than distributing the full **CROCO** model or large simulation datasets.


## Repository contents

| Directory | Description |
| --- | --- |
| [`pre_process/`](pre_process/) | Bathymetry exploration and CROCO grid generation. |
| [`post_process/`](post_process/) | NetCDF extraction, time-averaged diagnostics, wetting/drying statistics and comparison plots. |
| [`test_case/Swash/`](test_case/Swash/) | Reference benchmark figures and notes on CROCO/SWASH test-case interpretation. |
|[`model_configuration/`](model_configuration/) | Selected CROCO configuration files for hydrodynamic and sediment-enabled experiments, subject to sharing permissions. |

## Workflow

1. Inspect available field bathymetry and construct a representative cross-shore grid.
2. Prepare the CROCO configuration and wave-forcing parameters for the selected conditions.
3. Run hydrodynamic and sediment-enabled experiments in the appropriate configurations.
4. Extract selected NetCDF variables and precompute statistics in MATLAB.
5. Asses model behaviour and provide diagnostic plots.

## Software and data requirements

- **CROCO**, with the non-hydrostatic and sediment capabilities enabled for the experiment.
- **MATLAB** and, for several scripts, the legacy **CROCOTOOLS** `start.m`/NetCDF interface.
- **NetCDF** CROCO history and grid files, plus the applicable bathymetry and reference data.
- **MPI** execution environment for parallel model runs.

Scripts currently contain null paths and experiment-specific parameters. **Edit these before running.** Large input/output datasets and third-party model source code are not included.

### Disclaimer

This repository contains selected scripts and documentation of my contributions, not a standalone, fully reproducible distribution of the complete industrial modelling setup. Some scripts were adapted from existing collaborator workflows, as indicated in their source comments. Where applicable, scripts also note AI-assisted coding contributions that were reviewed by the author. The project was conducted in collaboration with WWS; inclusion of any proprietary configuration or input data is subject to permission.

