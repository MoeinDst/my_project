### ADCP raw-reading and velocity-processing notebooks

![Python](https://img.shields.io/badge/python-3.11+-blue?logo=python)
![NumPy](https://img.shields.io/badge/numpy-%23013243?logo=numpy&logoColor=white)
![Pandas](https://img.shields.io/badge/pandas-%23150458?logo=pandas&logoColor=white)
![SciPy](https://img.shields.io/badge/scipy-%230C55A5?logo=scipy&logoColor=white)
![Matplotlib](https://img.shields.io/badge/matplotlib-%2311557c)
========

This folder contains cleaned notebooks for processing ADCP field data from Faro tidal inlet and the Faro and Olhão channels.

#### 1. `BronzeSilver_matrices_towed.ipynb`

Purpose: read raw data from `.mat` files (`STA1.mat`, `STA2.mat`, `STA4.mat`), merge them into one bronze-level dataframe, and start the silver-level correction workflow.

Main workflow:

1. Load the raw MAT files.
2. Convert instrument date fields (`SerYear`, `SerMon`, `SerDay`, `SerHour`, `SerMin`, `SerSec`) into pandas datetimes.
3. Build position vectors from averaged leading/final longitude and latitude fields.
4. Apply quality control to eastward and northward water velocities:
   - use `SerPG4` as the percent-good quality field;
   - remove instrument missing values of `-32768`;
   - convert mm/s to m/s.
5. Pad `STA1` and `STA2` with four `NaN` bins so all deployments have the same number of vertical bins before concatenation.
6. Compute bottom-track depth from the four ADCP beams.
7. Build bin-depth arrays by dividing each instantaneous depth into 34 bins.
8. Merge time, position, bin depths, water velocities, bottom-track velocities, backscatter, and temperature into `df_bronze`.
9. Define transect index ranges for three repeated transects.
10. Compute per-transect correction parameters:
    - `alpha`: heading/angle correction between bottom-track and navigation velocity vectors;
    - `beta`: speed-scale correction from navigation speed relative to bottom-track speed.

Important note: the original notebook had experimental cells after the `alpha`/`beta` calculation for applying the silver-level correction. Those cells were incomplete and were not suited for publishing.

#### 2. `ADCP_velocity_manipulation.ipynb`

Purpose: process moored ADCP deployments from two channels:

- ADCP1: Olhão Channel
- ADCP2: Faro Channel

Main workflow:

1. Load `ADCP1.mat` and `ADCP2.mat`.
2. Extract sensor, vertical-beam, and water-track fields.
3. Separate eastward and northward velocity components.
4. Estimate principal flow direction using a PCA-like slope calculation for each depth bin.
5. Apply a simple quality filter based on intensity and correlation thresholds.
6. Rotate velocities into along-channel / cross-channel coordinates.


#### Dependencies

Minimum Python packages used by the notebooks:

* [numpy](https://numpy.org/doc/stable/index.html)
* [pandas](https://pandas.pydata.org/)
* [scipy](https://scipy.org/)
* [matplotlib](https://matplotlib.org/stable/)
