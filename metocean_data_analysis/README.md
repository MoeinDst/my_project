## Metocean Data Analysis | Observational data processing and storm-event identification

![Python](https://img.shields.io/badge/Python-3.9.15-3776AB?logo=python&logoColor=white) ![Xarray](https://img.shields.io/badge/Xarray-2022.11.0-blue) ![NumPy](https://img.shields.io/badge/NumPy-1.22.3-013243?logo=numpy&logoColor=white) ![Pandas](https://img.shields.io/badge/Pandas-1.5.2-150458?logo=pandas&logoColor=white) ![Matplotlib](https://img.shields.io/badge/Matplotlib-3.5.2-11557c) ![Dask](https://img.shields.io/badge/Dask-2022.2.1-orange)

## Overview

This directory documents selected work that I undertook during an industrial collaboration with [Weather Water Sand srl (WWS)](https://www.weatherwatersand.com/), focused on processing and analyzing metocean observational datasets, identifying storm events, and providing observational information to support subsequent modelling activities conducted by other project contributors.

As the initial step I decided to convert the original text-based datasets into **NetCDF** format to facilitate data handling and analysis using Python, particularly [Xarray](https://xarray.dev/) and [Dask](https://www.dask.org/). Subsequent work was to explore data availability across monitoring stations, examine the corresponding observational coverage, and identify storm events.

This repository focuses on sharing selected scripts, notebooks, and analysis workflows rather than distributing the underlying observational datasets or confidential project information.

### Repository contents
---

| File | Description |
| --- | --- |
| `eni_data_read_funcs.py` | Instrument-specific parsers for reading text files, extracting metadata, and creating Xarray datasets. |
| `data_csv2netcdf.ipynb` | Conversion of original text-based datasets into NetCDF, including parallel processing with Dask. |
| `selective_stations_data_coverage.ipynb` | Examination and visualization of data availability across selected monitoring stations during storm events. |
| `list_and_shutdown_all_clusters.ipynb` | Utility notebook for managing Dask Gateway clusters, adopted from [rsignell](https://github.com/rsignell). |

### Workflow Summary
---

1. Inspect the original text-based datasets and their instrument-specific formats.
2. Parse observational records and extract available metadata into Xarray datasets.
3. Convert and organize the datasets into NetCDF files for more efficient data access and analysis.
4. Identify storm events and examine the corresponding temporal data coverage across monitoring stations.
5. Provide observational analyses and supporting information to inform subsequent modelling activities carried out by other project contributors.

### Software and data requirements

- **Python**, with libraries including `xarray`, `pandas`, `numpy`, and `matplotlib`.
- **Dask** and **Dask Gateway** for workflows involving parallel and distributed computing.
- **NetCDF** support for reading and writing converted observational datasets.
- Original text-based metocean datasets in the expected instrument-specific formats.

#### Note on data conventions
---

The conversion to NetCDF was primarily intended to improve data accessibility and facilitate subsequent analysis, rather than to produce fully standardized datasets.

In oceanographic data management, particularly for observations from instruments such as gliders and Acoustic Doppler Current Profilers (ADCPs), controlled vocabularies provided by the [NERC Vocabulary Server (NVS)](https://vocab.nerc.ac.uk/) are commonly used to standardize parameter descriptions and improve data interoperability.

However, due to source-data limitations, project-specific requirements, and the available delivery timeline, the resulting NetCDF files are **not fully compliant with the Climate and Forecast (CF) metadata conventions**, nor do they systematically follow NERC controlled vocabularies.

Instead, descriptive and consistent variable names were adopted, retaining their relationship to the original text files. Available metadata and original variable identifiers were preserved as attributes where applicable. This approach was chosen to maintain consistency with the source datasets while meeting the practical requirements of the collaboration.

Scripts and notebooks contain project-specific paths and parameters. These must be adjusted before running. The original observational datasets are not included.

### Disclaimer
---

This directory contains selected scripts and notebooks documenting my contributions, not a standalone, fully reproducible distribution of the complete metocean analysis project. The work was conducted in collaboration with **WWS**, with my contributions focused on observational data processing, analysis, and storm-event identification rather than numerical modelling.

Only selected code and methodological approaches are intended for public sharing. The underlying observational datasets, bathymetric information, and other confidential or proprietary project materials are not distributed. **Any project-related content beyond the original code and methods presented here may be subject to third-party copyright, ownership, or sharing restrictions and should not be reproduced or redistributed without appropriate permission.**

The inclusion of any material in this repository does not imply permission to reuse proprietary datasets, project information, or other third-party intellectual property. **Public availability of the scripts and notebooks does not, by itself, grant permission to reproduce, modify, or redistribute their contents**.
