# Post-processing

MATLAB and Bash utilities for processing CROCO output, saving intermediate `.mat` datasets, and generating diagnostic comparisons.

| Script | Purpose |
| --- | --- |
| `read_save_data_u.m` | Extract cross-shore velocity from CROCO history file. |
| `read_save_data_zeta.m` | Extract free-surface elevation and coordinates. |
| `run_matlab_Read_n_Save.sh` | Run the extraction scripts in non-interactive MATLAB sessions. |
| `prep_zavg.m` | Precompute free-surface snapshots, mean surface elevation and variance-based wave-height diagnostics. |
| `prep_zavg_wetdry.m` | Calculate wet-only surface-elevation statistics in simulations with intermittent wetting/drying. |
| `prep_umean.m` | Precompute time-averaged velocity diagnostics for reference/upscaled comparisons. |
| `plot4panel_SingleRun_precomputed.m` | Plot diagnostics for a single selected simulation. |

**Important:** Wet-only wave statistics at intermittently inundated cells are conditional statistics and should not be interpreted as conventional shoreline wave statistics. Outputs from `prep_zavg.m` retain native model units, and any comparison-scale conversion occurs later in the workflow.

**Requirements:** MATLAB and relevant CROCOTOOLS legacy NetCDF interfaces. 