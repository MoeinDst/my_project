# Pre-processing

MATLAB scripts for exploring field bathymetry and generating a CROCO-compatible computational grid.

| Script | Purpose |
| --- | --- |
| `field_bathy_explore.m` | Inspect bathymetry from various transects in the Bonassola/LaFrancesca area. |
| `BonassolaExtended_makeCROCOgrid.m` | Construct a representative cross-shore bathymetry and CROCO grid, with an optional offshore flat-bottom extension to support boundary transition and grid decomposition. |

**Requirements:** MATLAB, bathymetry input `.mat` files, and CROCOTOOLS initialization (`start.m`). Update hard-coded paths and verify grid and coordinate conventions.
