STEP 07 — ROBUSTNESS AND SENSITIVITY TESTS
==========================================

PURPOSE
-------
Assess how reported SST–rainfall associations change with (1) small
adjustments to the SST study-region boundaries, (2) linear detrending and
exclusion of 2025, and (3) spatial aggregation of CHIRPS rainfall grids.
All results are observational sensitivity checks within January 2016–
December 2025; they do not establish causality, predictive skill, or
long-term climatic stability.

REQUIRED ENVIRONMENT AND FOLDER STRUCTURE
-----------------------------------------
MATLAB R2021a; Statistics and Machine Learning Toolbox for correlations
and inferential calculations as used by the scripts. Keep the numbered
folders together under the same parent directory:

  01_SST_Rainfall_NTT_2016_2025/
    01_Crop_SST_NTT/sst_YYYYMM.nc       (local cropped source; not on GitHub)
  02_Regional_Timeseries/
    regional_anomalies.mat
  04_Seasonal_Analysis/
    seasonal_mean_anomalies.mat
    seasonal_robustness_results.csv
  05_Spatial_Analysis/
    spatial_rainfall_anomaly.mat
    spatial_correlation_results.mat
  07_Robustness_Tests/
    a_sst_domain_sensitivity.m
    b_seasonal_detrend_missing2025.m
    c_spatial_coarsegrid_sensitivity.m
    README.txt                         (this document)

No original or cropped SST/CHIRPS NetCDF datasets are redistributed.
Step 07a requires the locally generated monthly SST NetCDF files.
Steps 07b and 07c can be rerun from the specified MAT/CSV intermediates
when these files are included in the repository.

EXECUTION AND OUTPUTS
---------------------
1. a_sst_domain_sensitivity.m
   Inputs:
     ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_YYYYMM.nc
     ../02_Regional_Timeseries/regional_anomalies.mat
     ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
   Outputs (saved within this folder):
     sst_domain_sensitivity_JJA.csv
     sst_domain_sensitivity_JJA.mat
   Method: adjust all four geographical boundaries of each SST region by
   -0.2, -0.1, 0, +0.1, and +0.2 degrees (positive expands the box).
   Recalculate the regional SST mean and same-calendar-month
   deseasonalized anomalies; hold rainfall study regions unchanged.
   These sensitivity correlations do not have newly adjusted qFDR.

2. b_seasonal_detrend_missing2025.m
   Inputs:
     ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
     ../04_Seasonal_Analysis/seasonal_robustness_results.csv
   Outputs:
     seasonal_detrend_sensitivity.csv
     seasonal_exclude2025_sensitivity.csv
     JJA_rainfall_magnitude.csv
   Method: remove separate linear trends from the seasonal SST and
   rainfall interannual series, recompute their Pearson correlation,
   and separately recompute correlations after excluding 2025.
   The JJA rainfall summary reports magnitudes in mm per month.
   These are descriptive sensitivity coefficients: permutation p-values
   and qFDR are NOT recalculated for the detrended or shortened series.

3. c_spatial_coarsegrid_sensitivity.m
   Inputs:
     ../05_Spatial_Analysis/spatial_rainfall_anomaly.mat
     ../05_Spatial_Analysis/spatial_correlation_results.mat
     ../02_Regional_Timeseries/regional_anomalies.mat
   Outputs:
     spatial_coarse010_summary.csv
     spatial_coarse010_grid_results.csv
     spatial_coarse010_results.mat
   Method: combine 2 x 2 neighboring native CHIRPS land grid cells
   (approximately 0.05 to 0.10 degrees). Retain a coarse cell only
   when at least two source land cells are valid; apply no spatial or
   temporal interpolation. Correlate against the original regional SST
   deseasonalized anomalies; recalculate autocorrelation-adjusted
   effective sample size (N_eff), two-sided p-values, and BH-FDR both
   within individual study regions and pooled across all three regions.
   Coarsened grid cells remain spatially dependent. BH-FDR families
   differ in size between the native and aggregated analyses.

Run these scripts in MATLAB from the retained folder arrangement.
They are independent sensitivity calculations after their Stage 01/02/04/05
inputs exist; the letter prefixes indicate the documented review order.
The output CSV/MAT filenames remain unchanged by renumbering the scripts.

REFERENCE RESULTS FOR QUALITY CONTROL
-------------------------------------
- JJA SST domain sensitivity r ranges:
    Flores 0.844–0.860; Sumba 0.836–0.843; Timor 0.791–0.795.
- Detrended JJA Pearson r:
    Flores 0.918; Sumba 0.887; Timor 0.790.
- Excluding 2025, JJA Pearson r:
    Flores 0.871; Sumba 0.875; Timor 0.836.
- Coarse CHIRPS valid grid counts:
    Flores 305; Sumba 144; Timor 278.
- Coarse within-region BH-FDR: Flores 31, Sumba 0, Timor 0.
  Pooled BH-FDR across the three study regions: 0 retained cells.

These are reference values to cross-check the actual produced CSV outputs,
not hard-coded numbers that replace the statistical calculations.

REPRODUCIBILITY AND INTERPRETATION
----------------------------------
The scripts retain the original computation logic and write their results
in the same folder. Their filenames have been renumbered because an
exploratory Flores north–south SST subdomain comparison, not included in
the final manuscript, was excluded from this final reproducibility stage.
No other sensitivity method or output value has been changed solely due
to the removal. An exploratory correlation comparison without a formal
coefficient-difference test does not establish that two regional
relationships are statistically identical or significantly different.

SST October–November 2025 remains missing. No raw-data interpolation,
area weighting, or administrative polygon masking is introduced here.
The coarse-grid analysis is a sensitivity check, not a proof of
independent spatial samples. Climate mechanisms and forecasting skill
are not evaluated by the Step 07 scripts.
