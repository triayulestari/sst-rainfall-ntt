STEP 05 - GRID-LEVEL SPATIAL SST-RAINFALL CORRELATION AND FDR
============================================================

1. PURPOSE AND SCOPE
--------------------
This step quantifies contemporaneous (zero-lag) monthly relationships between
regional-mean marine sea surface temperature (SST) anomalies and gridded land
rainfall anomalies for the Flores, Sumba, and Timor study rectangles. It also
records data-availability masks, checks consistency with the regional rainfall
series, estimates autocorrelation-adjusted significance, and applies two
explicitly defined Benjamini-Hochberg false-discovery-rate (BH-FDR) corrections.

The analysis uses January 2016-December 2025 monthly observations. It is NOT
restricted to the JJA season, and it does NOT calculate correlations between
SST grids and rainfall grids. For each region, one regional-mean SST series is
correlated separately with every eligible CHIRPS rainfall grid in that region.

2. SOFTWARE AND INPUT DATA
--------------------------
Software: MATLAB R2021a and Statistics and Machine Learning Toolbox.

Inputs:
  ../01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
      Locally generated CHIRPS v3.0 annual NetCDF files, 2016-2025;
      each contains 12 monthly rainfall totals (mm per calendar month).
  ../02_Regional_Timeseries/regional_anomalies.mat
      Supplies time [120 months], RAIN [120 x 3], and SST_deseason [120 x 3].

The original and cropped CHIRPS NetCDF files are not redistributed through
this repository. The supplied intermediate MAT files permit downstream
reproduction without re-downloading CHIRPS, but the original gridded rainfall
preparation can only be rerun with the corresponding NetCDF inputs.

3. DIRECTORY CONTENTS AND EXECUTION ORDER
-----------------------------------------
Data/
  05_Spatial_Analysis/
    README_05_Spatial_Analysis.txt
    a_prepare_spatial_rainfall_anomalies.m
    b_spatial_correlation_fdr.m
    spatial_rainfall_anomaly.mat
    spatial_rainfall_grid_QC.csv
    spatial_rainfall_monthly_QC.csv
    spatial_valid_grid_mask.csv
    spatial_correlation_results.mat
    spatial_correlation_summary.csv
    spatial_correlation_grid_results.csv

Run in the following order:

  1) a_prepare_spatial_rainfall_anomalies.m
     Reads cropped CHIRPS NetCDFs and Step 02 regional data; constructs the
     fixed valid-grid mask and calendar-month rainfall anomalies; generates
     the spatial rainfall MAT file and three QC CSVs.

  2) b_spatial_correlation_fdr.m
     Reads spatial_rainfall_anomaly.mat and the Step 02 MAT file; calculates
     per-grid zero-lag correlations, approximate effective sample sizes,
     adjusted p-values, and within-region and pooled BH-FDR q-values; writes
     the spatial correlation MAT file and two results CSVs.

Both scripts resolve their input and output paths relative to their saved
.m-file locations, not the current MATLAB working directory. Preserve the
folder names and the expected input filenames.

4. GEOGRAPHIC SELECTION AND FIXED GRID MASK
-------------------------------------------
The CHIRPS regional rectangles (longitude E; latitude degrees S) are:

  Region     Longitude E       Latitude S       Rectangle cells
  Flores     118.975-123.525   9.225-7.875       2,576
  Sumba      118.775-121.225   10.525-9.175      1,400
  Timor      123.275-126.025   10.625-8.575      2,352

Grid positions are selected by their coordinates. The final fixed eligibility
mask is defined, within each rectangle, as:

  valid_grid(i,j) = all(isfinite(CHIRPS(i,j,1:120)))

Thus a grid is retained only if rainfall is finite for ALL 120 months.
There is no additional administrative-boundary mask, coastline polygon,
interpolation, regridding, or area weighting in this step. Retained CHIRPS
data cells are treated as rainfall-data grid cells, not as independently
validated land polygons. The Timor rectangle also includes some Timor-Leste
land. The three rectangles do not collectively represent an administrative
mask of all of East Nusa Tenggara Province.

Verified retained region-grid counts:

  Flores: 1,158 / 2,576 rectangle cells
  Sumba :   565 / 1,400 rectangle cells
  Timor : 1,088 / 2,352 rectangle cells
  Total : 2,811 retained region-grid entries

The regional rectangles overlap slightly: 20 coordinates occur in two
rectangles (17 Flores-Timor; 3 Flores-Sumba). Consequently, there are
2,791 UNIQUE geographical coordinates among the 2,811 region-grid entries.
Each duplicated location is nevertheless associated with a different
regional SST predictor, so the pooled test family is defined over the
2,811 region-grid comparisons, not 2,811 unique geographical coordinates.
These entries must not be described as statistically independent grids.

5. DESEASONALIZED RAINFALL GRID ANOMALIES
----------------------------------------
For each retained CHIRPS grid, a separate 2016-2025 mean is calculated for
each calendar month (e.g., January observations averaged across ten years).
Its rainfall anomaly is:

  Rain_deseason(i,j,t) = Rain(i,j,t) -
                          mean(Rain(i,j,s) for month(s) = month(t))

All twelve calendar-month means use ten observations at retained grids.
These are study-period calendar-month means, NOT 30-year climate normals.
The original CHIRPS values are monthly totals in mm, so the anomalies are
also expressed in mm for the corresponding calendar month. No factor of
1,000 is applied. No missing month is filled or interpolated.

The SST predictor is the regional-mean SST_deseason time series from Step 02,
with its own study-period calendar-month mean removed. October and November
2025 SST are missing (NaN); other monthly SST values are retained. As a
result, each eligible grid correlation uses 118 correctly aligned SST-rainfall
month pairs. The missing months are NOT treated as consecutive observations.

6. GRIDWISE CORRELATION AND APPROXIMATE SIGNIFICANCE
---------------------------------------------------
At each eligible CHIRPS grid (i,j), for the corresponding region:

  r(i,j) = PearsonCorr(SST_deseason_region(t),
                       Rain_deseason(i,j,t))

Only coincident finite monthly pairs are used (N = 118). Correlation is at
zero lag, with no seasonal subdivision. Ordinary two-sided Pearson p-values
are saved as p_raw, but the spatial multiple-testing calculations use the
autocorrelation-adjusted p-values described below.

Lag-1 autocorrelations are estimated on truly adjacent original calendar
positions, before removing any missing observations. In the present data:

  SST:     116 valid adjacent-month pairs per region
  CHIRPS:  119 valid adjacent-month pairs per retained grid

An approximate effective sample size is calculated separately for each grid:

  rho_product = rho1_SST_region * rho1_Rain_grid
  N_eff = N * (1 - rho_product) / (1 + rho_product)
  N_eff is bounded to the interval [3, N].

The two-sided adjusted p-value is computed using:

  t = r * sqrt((N_eff - 2) / (1 - r^2))
  df = N_eff - 2
  p_autocorr_adjusted = 2 * P(T_df >= abs(t))

This is an approximation based on lag-1 persistence, not a formal spatial
field-significance test and not a correction for all forms of temporal or
spatial dependence.

7. TWO BH-FDR MULTIPLE-TESTING FAMILIES
--------------------------------------
BH-FDR is applied to p_autocorr_adjusted, never directly to p_raw.
Two q-values are reported for every retained region-grid comparison:

  q_FDR_region:
    Corrects within each study rectangle separately:
      Flores: m = 1,158 tests
      Sumba : m =   565 tests
      Timor : m = 1,088 tests

  q_FDR_all_grids:
    Corrects the pooled family of all 2,811 region-grid comparisons
    across the three predefined study rectangles.

These are distinct inferential families. The pooled family is NOT all of
NTT, nor is it a collection of 2,811 independent spatial replicates.
The intended reporting threshold for FDR-retained tests is q < 0.05.
Values of 0.05 <= q < 0.10 may be identified as exploratory only and must
NOT be labeled significant at the 5% FDR threshold.

Because neighboring grids are spatially dependent and the study boxes can
overlap, BH-FDR must not be described as fully accounting for spatial
correlation. Interpret mapped clusters descriptively and distinguish the
within-region findings from the pooled correction.

8. VERIFIED RESULTS FROM THE PROVIDED OUTPUT FILES
---------------------------------------------------
The following values were checked against spatial_correlation_grid_results.csv,
spatial_correlation_summary.csv, and spatial_correlation_results.mat:

  Region  Valid  p_adj<0.05  q_region<0.05  q_all_grids<0.05
  Flores  1,158      196            78                  0
  Sumba     565        2             0                  0
  Timor   1,088      183             0                  0
  TOTAL   2,811      381            78                  0

The minimum pooled q_FDR_all_grids is approximately 0.09185. Therefore,
no grid is retained at pooled q < 0.05. The 78 Flores results meet the
WITHIN-REGION criterion only. They do not survive the pooled 2,811-test
correction. The fraction of positive gridwise r values is descriptive,
not evidence that an entire region passes a field-level significance test.

IMPORTANT VERSION NOTE:
  An older README and the last QC warning in the current
  b_spatial_correlation_fdr.m script reference 110 within-region Flores
  grid detections. That figure does not match the files supplied in this
  version, which consistently show 78. The hard-coded historical warning
  should be revised separately; it is not an additional statistical test.
  Do not report 110 unless a different, explicitly identified version of
  the inputs and outputs is being discussed.

9. QUALITY-CONTROL FILES AND CONTENT
-----------------------------------
  spatial_rainfall_grid_QC.csv
    Per-region rectangle size, retained grid count, minimum/maximum monthly
    valid rainfall counts, agreement with Step 02 regional rainfall means,
    and maximum residual calendar-month anomaly mean.

  spatial_rainfall_monthly_QC.csv
    Number of finite CHIRPS values in each rectangle for each of the
    120 individual calendar months (before fixed-mask exclusion).

  spatial_valid_grid_mask.csv
    Coordinates of all rectangle grid cells and a Boolean indicating
    membership in the all-120-month fixed-validity mask.

  spatial_rainfall_anomaly.mat
    Monthly gridded anomalies, 12 calendar-month grid means, masks, grid
    coordinates, and relevant QC tables required for subsequent analyses.

  spatial_correlation_grid_results.csv
    One row for each retained region-grid comparison. Includes Region,
    Longitude, Latitude, N, Pearson_r, Rain_lag1, N_effective, p_raw,
    p_autocorr_adjusted, q_FDR_region, and q_FDR_all_grids.

  spatial_correlation_summary.csv
    Per-region correlation distributions, positive-grid percentages,
    effective-sample-size ranges, and multiple-testing detection counts.

  spatial_correlation_results.mat
    Two-dimensional maps of r, p, q, N, N_eff, rainfall lag-1 correlation,
    masks, coordinates, and result tables for plotting and downstream reuse.

For the supplied QC outputs, the maximum absolute difference between spatial
CHIRPS rectangle means and the corresponding Step 02 regional rainfall
means is recorded as 0 mm, and the maximum absolute residual calendar-month
anomaly mean is approximately 4.55e-14 mm. These checks establish internal
numerical consistency; they do NOT independently validate CHIRPS rainfall
against ground observations.

10. DOWNSTREAM USE AND LIMITATIONS
----------------------------------
Figure 4 uses the spatial_correlation_results.mat maps and the corresponding
summary CSV. Step 07 coarse-resolution sensitivity uses the intermediate
spatial_rainfall_anomaly.mat and spatial_correlation_results.mat files.
Publish both MAT intermediates and CSV summaries to make the numeric results
and map construction traceable without distributing provider NetCDF files.

Interpretation limitations:
  - Ten study years and 118 coincident monthly SST-rainfall observations.
  - Regions are geographic rectangles rather than administrative masks.
  - The SST series is regional while rainfall is gridwise, not pixel-paired.
  - Neighboring rainfall grids and overlapping region entries are dependent.
  - N_eff uses a lag-1 approximation; BH-FDR does not explicitly model
    spatial dependence or establish independent field significance.
  - Statistical correlations do not demonstrate causality, physical
    mechanisms, or validated predictive skill.

Before citing any mapped grid count or q-value in the manuscript or
supplementary material, verify it against the version-controlled CSV/MAT
outputs in this directory and state WHICH FDR family is being reported.
