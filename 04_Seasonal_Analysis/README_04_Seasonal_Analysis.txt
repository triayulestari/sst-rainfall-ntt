STEP 04 - SEASONAL CORRELATIONS, UNCERTAINTY AND LOYO
====================================================

PURPOSE
-------
Calculate seasonal Pearson correlations between regional SST and rainfall
deseasonalized anomalies and report uncertainty, multiple-testing
correction, leave-one-year-out (LOYO), and interannual dependence checks.

SOFTWARE AND INPUT
------------------
MATLAB R2021a. Input from Step 02:
../02_Regional_Timeseries/regional_anomalies.mat
Keep all Step 04 scripts and outputs together in this folder.

RUN IN EXACT ORDER
------------------
1. a_seasonal_mean_anomalies.m
   Outputs: seasonal_mean_anomalies.csv, seasonal_mean_anomalies.mat
   Forms complete three-month seasonal mean deseasonalized anomalies.
2. b_seasonal_correlation.m
   Outputs: seasonal_correlation_basic.csv, seasonal_correlation_basic.mat
   Computes Pearson r and conventional reference statistics.
3. c_seasonal_robustness.m
   Outputs: seasonal_robustness_results.csv,
            seasonal_robustness_results.mat, seasonal_LOYO_results.csv
   Runs 10,000 two-sided yearwise rainfall permutations, 95% Fisher-z CI,
   LOYO, and BH-FDR correction across 12 region-season tests.
4. d_check_seasonal_annual_dependence.m
   Outputs: seasonal_annual_dependence_QC.csv,
            seasonal_annual_dependence_QC.mat,
            seasonal_adjacent_year_pairs.csv
   Describes lag-1 interannual dependence and the available adjacent-year
   pairs. This is a diagnostic, not proof of independence.
5. e_compile_seasonal_uncertainty.m
   Output: seasonal_uncertainty_summary.csv
   Compiles r, N, CI, permutation p, BH-FDR qFDR, LOYO ranges, and
   interannual dependence diagnostics without changing the original tests.

SEASON DEFINITIONS
------------------
DJF: December of preceding year plus January-February of labeled year;
     2017-2025, n = 9.
MAM: March-May 2016-2025, n = 10.
JJA: June-August 2016-2025, n = 10.
SON: September-November 2016-2024, n = 9.
SON 2025 is excluded because SST October-November 2025 is unavailable.
Only seasons with all three component months are included.

STATISTICAL DEFINITIONS AND LIMITATIONS
---------------------------------------
- The input anomaly is monthly value minus the corresponding 2016-2025
  study-period calendar-month mean (deseasonalized anomaly).
- Seasonal correlation is calculated across seasonal-year pairs, not
  across all individual months pooled together.
- The permutation test uses 10,000 two-sided yearwise permutations;
  MATLAB rng(2026,'twister'); plus-one p-value correction.
- Primary BH-FDR family: 12 region-season combinations (3 x 4).
- qFDR < 0.05: statistically significant; 0.05 <= qFDR < 0.10:
  exploratory, NOT statistically significant at the 5% criterion.
- Reported 95% Fisher-z CIs are marginal approximations; they are not
  adjusted for FDR or serial dependence.
- LOYO re-estimates correlation after removing one season-year at a time.
  This checks sensitivity, not the significance of a new hypothesis.
- Only 9-10 seasons are available; unrestricted yearwise permutations do
  not preserve possible ENSO/IOD-related dependence between years.

EXPECTED RESULTS FOR CHECKING
-----------------------------
Four significant tests: Flores JJA, Sumba JJA, Timor JJA, Timor SON.
Two exploratory tests: Flores DJF and Flores SON.
JJA r: Flores 0.857, Sumba 0.838, Timor 0.792; qFDR = 0.0141.

INTEROPERABILITY
----------------
Step 06 reads seasonal_mean_anomalies.mat.
Figure 3 reads seasonal_robustness_results.csv.
seasonal_uncertainty_summary.csv is suitable for supplementary reporting.
Include the MAT/CSV inputs needed by downstream scripts when publishing
reproducibility material. These results do not establish causality.
