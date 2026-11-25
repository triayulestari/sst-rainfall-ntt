STEP 07 — ROBUSTNESS AND SENSITIVITY TESTS
==========================================

1. PURPOSE AND SCOPE
--------------------
This stage evaluates the sensitivity of observed sea surface temperature
(SST)–rainfall relationships across Flores, Sumba and Timor to four analysis
choices: (a) regional SST-box boundaries, (b) a north–south SST partition
within Flores, (c) interannual linear detrending and exclusion of the 2025
season-year, and (d) spatial aggregation of the CHIRPS rainfall grid.

All analyses use observations from January 2016 to December 2025 and retain
the primary definitions from Steps 02, 04 and 05. The north–south Flores test
is an exploratory supplementary comparison and is NOT a formal test of the
difference between two dependent correlations. Sensitivity analyses do not
establish causality, predictive skill or long-term climatic stability.


2. SOFTWARE AND REQUIRED INPUTS
--------------------------------
- MATLAB R2021a. Statistics and Machine Learning Toolbox is used for corr
  and tcdf in the relevant scripts.
- Keep all stage folders under the same parent directory. Each script
  locates the parent folder relative to its own saved .m-file location.
- Locally generated cropped SST NetCDF files from Step 01:
    ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_YYYYMM.nc
- Regional monthly arrays from Step 02:
    ../02_Regional_Timeseries/regional_anomalies.mat
- Seasonal arrays and robustness results from Step 04:
    ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
    ../04_Seasonal_Analysis/seasonal_robustness_results.csv
- Gridded rainfall anomalies and reference correlation maps from Step 05:
    ../05_Spatial_Analysis/spatial_rainfall_anomaly.mat
    ../05_Spatial_Analysis/spatial_correlation_results.mat

The SST NetCDF files are not redistributed in this repository; therefore,
reproduction of scripts a and b requires the original locally cropped files.
Scripts c and d can be rerun from the named MATLAB/CSV intermediates if those
intermediates are supplied. Original CHIRPS NetCDF files are not directly
read by Step 07.


3. ACTUAL SCRIPT NAMES AND EXECUTION
-----------------------------------
Run scripts as required inputs become available. The scripts are distinct
sensitivity analyses rather than a chain in which each script consumes the
previous script's output. The names below match the supplied .m files.

A. a_sst_domain_sensitivity.m
   Inputs: Step 01 SST NetCDFs; Step 02 regional_anomalies.mat;
           Step 04 seasonal_mean_anomalies.mat.
   Outputs:
     sst_domain_sensitivity_JJA.csv
     sst_domain_sensitivity_JJA.mat
   Tests five SST geographic domains per island, retaining the original
   regional rainfall anomalies as the response.

B. b_flores_north_south_sst.m  [EXPLORATORY; NOT A PRIMARY MANUSCRIPT TEST]
   Inputs: Step 01 SST NetCDFs; Step 02 regional_anomalies.mat;
           Step 04 seasonal_mean_anomalies.mat.
   Outputs:
     flores_north_south_monthly.csv
     flores_north_south_monthly.mat
     flores_north_south_seasonal_correlations.csv
   Describes the north-versus-south marine SST association with the same
   Flores land-rainfall time series. No new FDR correction is provided.

C. c_seasonal_detrend_missing2025.m
   Inputs: Step 04 seasonal_mean_anomalies.mat;
           Step 04 seasonal_robustness_results.csv.
   Outputs:
     seasonal_detrend_sensitivity.csv
     seasonal_exclude2025_sensitivity.csv
     JJA_rainfall_magnitude.csv
   Computes interannual detrended and 2025-excluded seasonal correlations;
   also tabulates JJA rainfall magnitudes.

D. d_spatial_coarsegrid_sensitivity.m
   Inputs: Step 05 spatial_rainfall_anomaly.mat;
           Step 05 spatial_correlation_results.mat;
           Step 02 regional_anomalies.mat.
   Outputs:
     spatial_coarse010_summary.csv
     spatial_coarse010_grid_results.csv
     spatial_coarse010_results.mat
   Aggregates CHIRPS rainfall anomalies in 2 x 2 native-grid blocks,
   recomputes correlations, effective sample sizes, adjusted p-values and
   BH-FDR at the coarse resolution.

NOTE: An earlier README referred to scripts b_seasonal_detrend_missing2025.m
and c_spatial_coarsegrid_sensitivity.m, and stated that the Flores north–south
analysis had been removed. Those statements do NOT describe the four scripts
and corresponding output files deposited here. Do not rename these scripts
without also reconciling their filenames and documentation.


4. METHODS
----------
4.1 SST domain-boundary sensitivity (script a)
The baseline SST rectangles from Step 02 are expanded or contracted
symmetrically on all four sides by delta = -0.2, -0.1, 0, +0.1 and +0.2
degrees. Positive delta expands the rectangle; negative delta contracts it.
For each adjusted rectangle, monthly SST is the unweighted arithmetic mean
of finite ocean-grid values. An independent 2016–2025 calendar-month mean
is subtracted for each SST domain, and complete three-month JJA means are
formed for 2016–2025 (n = 10 seasons). The unchanged corresponding regional
CHIRPS rainfall deseasonalized anomaly is paired with each SST series.
Output coefficients are descriptive; new permutation p-values or FDR q-values
are not calculated for the alternative domains.

4.2 Flores north–south SST comparison (script b)
The reference Flores marine SST box is 119.0–123.5 degrees E and
-9.2 to -7.9 degrees latitude. The north and south portions are separated
at -8.55 degrees latitude (north > -8.55; south < -8.55); the script verifies
that the two parts jointly reproduce the full selection without overlap.
For each part, the code computes unweighted monthly SST means, removes the
corresponding 2016–2025 calendar-month means, and forms complete seasonal
means using the Step 04 season-year definitions. It correlates northern SST,
southern SST and their anomaly difference (north minus south) separately
with the SAME Flores regional land-rainfall anomaly series.
These are exploratory correlation coefficients only. They do not test
whether north-versus-south correlation differences are statistically
significant, nor do they justify a formal geographic-mechanism claim.

4.3 Seasonal detrending and year-2025 exclusion (script c)
For each region–season series from Step 04, a linear trend is fitted
SEPARATELY to SST and rainfall seasonal means as a function of season-year.
Pearson r is recalculated between the two regression residual series.
This is detrending of INTERANNUAL SEASONAL VALUES, not detrending of the
original monthly observations. The second sensitivity removes records with
season-year > 2024 and recalculates Pearson r; DJF is labeled by its
January–February year (e.g., DJF 2025 includes December 2024). SON 2025 was
already excluded in Step 04, so the SON exclusion result is unchanged.
No new permutation p-values or FDR q-values are assigned to these altered
seasonal series.

The JJA rainfall magnitude table reports mean, minimum and maximum
three-month-mean rainfall as mm per calendar month, alongside the range and
mean absolute magnitude of corresponding seasonal rainfall anomalies.
These are NOT three-month accumulated rainfall totals (mm/season).

4.4 Coarse-grid spatial sensitivity (script d)
The original approximately 0.05-degree CHIRPS rainfall anomalies from
Step 05 are grouped into 2 x 2 neighboring native-grid blocks WITHIN each
regional rectangle (nominal spacing approximately 0.10 degrees). Blocks are
aligned to the first native grid point of each rectangle; they are not a
separately registered or interpolated global 0.10-degree CHIRPS product.
A coarse block is retained if it has at least two stable valid land cells.
The monthly coarse rainfall anomaly is the arithmetic mean of its valid
source cells, with no area weighting or interpolation. Original Step 02
regional SST deseasonalized anomalies are unchanged; SST October–November
2025 remain missing and are never bridged across the gap.

For every retained coarse block, the code calculates monthly zero-lag
Pearson r, lag-1 autocorrelations from adjacent calendar months, effective
sample size, and a two-sided t-based p-value using N_eff - 2 degrees of
freedom. The effective-sample approximation is

    N_eff = N * (1 - rho_SST(1)*rho_Rain(1)) /
                (1 + rho_SST(1)*rho_Rain(1))

bounded to 3 <= N_eff <= N. Benjamini–Hochberg FDR is then calculated
(a) separately within each region and (b) across all retained coarse
region-grid tests. The pooled coarse family contains 727 tests. Native
and coarse families contain different numbers of tests and therefore
should NOT be interpreted as directly equivalent significance tests.
Neighboring cells are also spatially dependent.


5. QUALITY-CHECK RESULTS FROM THE DEPOSITED CSV FILES
-----------------------------------------------------
5.1 JJA SST-domain sensitivity
                 Baseline r     Range across five box adjustments
  Flores            0.8569            0.8444 to 0.8597
  Sumba             0.8382            0.8358 to 0.8426
  Timor             0.7917            0.7910 to 0.7946
All five domain choices yielded positive JJA correlations in each region.

5.2 Flores north–south JJA exploratory comparisons (n = 10)
  North SST versus Flores rainfall:                 r = +0.8175
  South SST versus Flores rainfall:                 r = +0.8693
  (North minus south) SST anomaly versus rainfall: r = -0.8532
These coefficients are descriptive and are NOT formal between-correlation
tests. Other seasons are recorded in
flores_north_south_seasonal_correlations.csv.

5.3 JJA interannual trend and 2025-exclusion sensitivity
                   Baseline r   Detrended r   Excluding 2025 r
  Flores              0.8569       0.9184           0.8711
  Sumba               0.8382       0.8872           0.8748
  Timor               0.7917       0.7904           0.8360
These are descriptive coefficients with n = 10 baseline JJA seasons and
n = 9 after excluding the 2025 season-year.

5.4 Spatial resolution sensitivity: BH-FDR at q < 0.05
             Native   Coarse    Native FDR    Coarse FDR    Pooled FDR
             grids    grids     per region    per region    (both scales)
  Flores      1,158      305          78            19             0
  Sumba         565      144           0             0             0
  Timor       1,088      278           0             0             0
  TOTAL       2,811      727          78            19             0
These are REGION-GRID counts, rather than independent geographic
replications. The pooled totals refer only to the three study rectangles,
not to every land grid in the province of East Nusa Tenggara.


6. OUTPUT INTERPRETATION AND REPRODUCIBILITY CHECKS
--------------------------------------------------
- The baseline JJA r values in sst_domain_sensitivity_JJA.csv and the
  baseline seasonal r values in seasonal_detrend_sensitivity.csv agree with
  Step 04 seasonal_robustness_results.csv.
- Step 07 coarse-grid per-cell CSV values reproduce the within-region
  BH-FDR results for 305/144/278 coarse cells and the pooled 727-test FDR;
  the supplied coarse summary gives 19 Flores within-region FDR-retained
  cells, not the older README reference value of 31.
- The native-grid FDR reference is 78 Flores cells from the deposited
  Step 05 results, not an older reference value of 110.
- No new significance test was performed for SST-domain, north–south SST,
  seasonal detrending or exclusion-of-2025 coefficients.
- The Step 07 coarse-grid analysis DOES calculate a separate set of
  autocorrelation-adjusted p-values and FDR q-values; these must not be
  substituted for the native Step 05 results.
- Results remain observational and sensitive to the limited 9–10-season
  sample and to spatial dependence of rainfall grids.
- MAT outputs preserve numerical arrays for MATLAB re-use. CSV files
  provide human-readable summaries and, where applicable, per-observation
  or per-grid audit values.

This README documents the existing supplied script/output versions. It does
not claim that MATLAB was rerun against original NetCDF sources during this
README review.
