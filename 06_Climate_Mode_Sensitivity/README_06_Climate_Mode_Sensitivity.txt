STEP 06 - LARGE-SCALE CLIMATE-MODE SENSITIVITY
==============================================

1. PURPOSE
----------
This stage examines how seasonal correlations between regional-mean marine
sea surface temperature (SST) and land rainfall anomalies change when
statistically adjusting for a large-scale climate index: either the Nino 3.4
index (ENSO) OR the Dipole Mode Index (DMI; Indian Ocean Dipole). The two
indices are controlled separately, not jointly. These are sensitivity
analyses of association, not estimates of independent physical effects,
causal attribution, or forecast skill.

Three geographic study regions are analyzed: Flores, Sumba, and Timor.
The observational period is January 2016-December 2025, with seasonal
coverage determined by the complete seasons available in Step 04.

2. SOFTWARE AND DIRECTORY STRUCTURE
-----------------------------------
Software: MATLAB R2021a, including the Statistics and Machine Learning
Toolbox for the corr calls used in the diagnostic script. The scripts
otherwise use MATLAB table I/O, least-squares fitting, and betainc.
Paths are resolved relative to the saved location of each .m script.

Data/
  04_Seasonal_Analysis/
    seasonal_mean_anomalies.mat           [REQUIRED from Step 04]
    seasonal_correlation_basic.csv        [OPTIONAL Step 04 consistency check]
  06_Climate_Mode_Sensitivity/
    README_06_Climate_Mode_Sensitivity.txt
    NOAA_PSL_Index_Provenance.txt         [SUPPORTING provenance note]
    climate_indices_input_2016_2025.csv  [REQUIRED fixed input snapshot]
    a_prepare_climate_indices.m
    b_seasonal_partial_correlation.m
    c_seasonal_partial_robustness.m
    d_check_partial_uncertainty_dependence.m
    climate_indices_2016_2025.mat
    climate_indices_monthly.csv
    climate_indices_seasonal.csv
    climate_indices_QC.csv
    seasonal_partial_correlation_results.csv
    seasonal_partial_correlation_results.mat
    seasonal_partial_correlation_QC.csv
    seasonal_partial_robustness_results.csv
    seasonal_partial_robustness_results.mat
    seasonal_partial_LOYO_results.csv
    seasonal_partial_permutation_QC.csv
    partial_uncertainty_dependence_summary.csv
    partial_residual_adjacent_year_pairs.csv

Do not rename required files or move the Step 04 MAT file without updating
the explicit paths in the scripts.

3. CLIMATE-INDEX SOURCES AND FROZEN INPUT
-----------------------------------------
The analysis uses the included 120-row monthly input snapshot:

  climate_indices_input_2016_2025.csv
  Fields: Year, Month, Nino34, DMI
  Coverage: January 2016-December 2025, 120 finite observations per index.

Researcher-recorded initial download date: 12 September 2026. This date is
a provenance record, not an independently verified source-file timestamp.

Relevant NOAA Physical Sciences Laboratory (PSL) data sources are:

  Nino 3.4 anomaly series (nina34.anom.data):
  https://psl.noaa.gov/data/correlation/nina34.anom.data

  Dipole Mode Index (dmi.had.long.data):
  https://psl.noaa.gov/data/timeseries/month/data/dmi.had.long.data
  https://psl.noaa.gov/data/timeseries/month/DMI/

IMPORTANT PRODUCT DISTINCTION: NOAA PSL distributes more than one Nino 3.4
series. The Nino 3.4 series at
https://psl.noaa.gov/data/timeseries/month/Nino34/ is identified as a
HadISST1.1-derived series and is NOT interchangeable with the
nina34.anom.data series. The online nina34.anom.data metadata inspected for
this documentation identify ERSST V6 and a 1981-2010 anomaly baseline;
the DMI source identifies HadISST1.1. The input snapshot is consistent
with selected values inspected in those respective source series (e.g.,
January 2016: Nino34 = 2.13; DMI = 0.265), but the exact historical NOAA
source-file versions at the recorded September 2026 download date have
not been independently archived or fully authenticated here.

For exact computational reproduction of the submitted analysis, use the
FIXED INPUT CSV, not a newly downloaded or substituted index product.
Later online source revisions may change results. The original NOAA PSL
files, if retained, should be archived with their download date, URLs,
source metadata, and checksums and compared month by month with the CSV.

The CSV values are precomputed monthly climate indices/anomalies; they are
not re-deseasonalized, re-centered, or multiplied by scaling factors.

Script a provides an OPTIONAL input_mode = 'annual_txt' for local NOAA
annual-row text files named nina34.anom.data.txt and
dmi.had.long.data.txt. These are LOCAL filenames expected by the script;
NOAA online resources may have filenames without the .txt suffix. Save
copies under the script's specified local filenames, or explicitly edit
the paths. Results from this optional mode are not guaranteed to match the
frozen snapshot unless every input value is identical.

4. EXECUTION ORDER AND EXACT OUTPUTS
------------------------------------
Execute these scripts in the order below:

A. a_prepare_climate_indices.m
   Default input: climate_indices_input_2016_2025.csv
   Outputs:
     climate_indices_2016_2025.mat
     climate_indices_monthly.csv
     climate_indices_seasonal.csv
     climate_indices_QC.csv
   Checks chronological month alignment and completeness; creates complete
   three-month seasonal means of both climate indices.

B. b_seasonal_partial_correlation.m
   Inputs:
     ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat
     climate_indices_2016_2025.mat
   Outputs:
     seasonal_partial_correlation_results.csv
     seasonal_partial_correlation_results.mat
     seasonal_partial_correlation_QC.csv
   Computes unadjusted seasonal r, SST-index and rainfall-index r, and
   partial r controlling for one index at a time. The ordinary parametric
   partial-correlation p-values are descriptive, NOT the primary inference.
   If available, the Step 04 basic correlation CSV is cross-checked.

C. c_seasonal_partial_robustness.m
   Input: seasonal_partial_correlation_results.mat
   Outputs:
     seasonal_partial_robustness_results.csv
     seasonal_partial_robustness_results.mat
     seasonal_partial_LOYO_results.csv
     seasonal_partial_permutation_QC.csv
   Performs 10,000 conditional residual permutations per test, approximate
   95% Fisher-z confidence intervals, leave-one-year-out (LOYO) checks,
   and separate BH-FDR adjustments for each control index.

D. d_check_partial_uncertainty_dependence.m
   Inputs:
     seasonal_partial_correlation_results.mat
     seasonal_partial_robustness_results.csv
   Outputs:
     partial_uncertainty_dependence_summary.csv
     partial_residual_adjacent_year_pairs.csv
   Combines 24 test-control results and computes descriptive adjacent-year
   lag-1 dependence for the index and the partial-correlation residuals.
   It does NOT rerun the permutation tests or modify p- or q-values.

5. SEASON CONVENTIONS AND SAMPLE SIZE
------------------------------------
Seasonal SST and rainfall inputs are the arithmetic means of three monthly
DESEASONALIZED anomalies from Step 04; those monthly anomalies are defined
relative to the corresponding 2016-2025 calendar-month means. Each climate
index is likewise averaged over the same three months for the control
covariate, but the climate-index values are not deseasonalized again.

DJF year Y = December (Y-1), January Y, and February Y:
  DJF 2017-2025; N = 9 complete seasons.
MAM = March-May 2016-2025; N = 10.
JJA = June-August 2016-2025; N = 10.
SON = September-November 2016-2024; N = 9.

SON 2025 is excluded because SST is unavailable for October-November 2025.
DJF 2016 is not formed because December 2015 is outside the time series.
All three months and both control-index series must be present, and the
season-year sequences for SST/rainfall and climate indices must match.
No months are interpolated or partial seasons accepted.

6. PARTIAL CORRELATION DEFINITION
--------------------------------
For each of 3 regions x 4 seasons, let:
  X = seasonal-mean regional SST deseasonalized anomaly;
  Y = seasonal-mean regional rainfall deseasonalized anomaly;
  Z = seasonal Nino 3.4 OR seasonal DMI (one at a time).

With an intercept, fit X = a_x + b_x*Z + e_x and
Y = a_y + b_y*Z + e_y by ordinary least squares. The reported partial
correlation is r_partial = corr(e_x, e_y), the Pearson correlation between
residualized X and residualized Y.

The ordinary parametric partial-correlation reference uses degrees of
freedom df = N - 3 (one covariate). It is not substituted for the primary
permutation-based inference.

7. UNCERTAINTY, MULTIPLE TESTING, AND DEPENDENCE
-----------------------------------------------
Conditional residual permutation (Freedman-Lane-style implementation):
  1. Fit Y on [intercept, Z]; retain fitted values and residuals e_y.
  2. Compute residuals e_x of X on [intercept, Z].
  3. Permute e_y across season-years and construct
       Y* = fitted(Y | Z) + permuted(e_y).
  4. Refit Y* on [intercept, Z], and compute corr(e_x, residual(Y* | Z)).
  5. Repeat 10,000 times (rng(2026,'twister'), initialized once) and use
       p_perm = (1 + count(|r_perm| >= |r_observed|)) / 10001.

The resulting p-values are corrected using Benjamini-Hochberg FDR in TWO
separate analysis families:
  - 12 region-season comparisons controlling Nino 3.4;
  - 12 region-season comparisons controlling DMI.

These are NOT a single pooled 24-test correction. Primary threshold:
q_FDR < 0.05. Results with 0.05 <= q_FDR < 0.10 may be described only as
exploratory/suggestive, not statistically significant at 5% FDR.

The reported 95% confidence intervals are approximate marginal Fisher-z
intervals using standard error 1/sqrt(N - 4), corresponding to a single
control variable; they are not bootstrap intervals, not FDR-adjusted,
and not corrected for serial dependence. LOYO refits both residualizations
after omitting each individual season-year and records changes in r.

For the annual-dependence diagnostic, only consecutive years within the
same season are paired (8 pairs for N=9; 9 pairs for N=10). It records
lag-1 correlations of Z, e_x and e_y. Weak lag-1 correlation from these
small samples cannot demonstrate yearwise exchangeability.

Unrestricted permutations of seasonal residuals do NOT preserve possible
interannual ENSO/IOD persistence. The output p-values and intervals should
therefore be interpreted cautiously. No separate dependence-preserving
permutation or adjusted annual effective sample size is implemented here.

8. CHECKED OUTPUT SUMMARY (CURRENT DEPOSITED RESULTS)
------------------------------------------------------
The supplied CSV outputs contain 12 region-season rows in each primary
correlation table and 24 region-season-control rows in the combined
uncertainty table. The following values reflect the supplied results:

JJA (N = 10 complete season-years per region):
  Region   r_unadjusted  r_partial_Nino   q_Nino    r_partial_DMI   q_DMI
  Flores     +0.856872      +0.834805     0.083992     +0.698478      0.203580
  Sumba      +0.838180      +0.821275     0.135986     +0.664676      0.203580
  Timor      +0.791689      +0.741065     0.083992     +0.655287      0.203580

BH-FDR conclusions at q < 0.05:
  - Nino 3.4 control: 0/12 retained; 2 suggestive (Flores JJA,
    Timor JJA) at 0.05 <= q < 0.10.
  - DMI control: 0/12 retained; 0 suggestive at 0.05 <= q < 0.10.

These results must not be described as robust significance after climate
index adjustment or proof of independence from ENSO/IOD. Their positive
coefficients are descriptive conditional associations.

9. CROSS-FILE QUALITY CONTROL
----------------------------
Checks supported by the supplied intermediate MAT and CSV tables:
  - Fixed monthly input versus exported monthly indices: identical values.
  - 120/120 finite months for both Nino 3.4 and DMI.
  - Seasonal index means reproduce the snapshot to floating-point precision.
  - The 12 unadjusted seasonal r values match Step 04.
  - Partial coefficients, parametric p-values, approximate Fisher-z CIs,
    LOYO coefficients, BH-FDR q-values, and annual lag-1 diagnostics are
    internally consistent with the deposited data.
  - seasonal_partial_LOYO_results.csv: 228 control-specific deletions.
  - partial_residual_adjacent_year_pairs.csv: 204 adjacent-year rows.

These are reproducibility and internal numerical checks, not an external
validation of the physical index datasets. Exact reproduction of MATLAB's
10,000 randomized permutation draws has NOT been independently executed
in this documentation audit.

10. REPOSITORY CONTENT AND DOWNSTREAM USE
------------------------------------------
Publish the unchanged .m scripts, the frozen monthly index input CSV,
relevant MAT intermediates, and all listed CSV outputs. In particular:
  - climate_indices_input_2016_2025.csv fixes the climate-index inputs.
  - climate_indices_2016_2025.mat feeds the partial-correlation script.
  - seasonal_partial_correlation_results.mat feeds the robustness script.
  - seasonal_partial_robustness_results.csv supplies the plotted Figure 5
    values, according to the repository figure workflow.
  - partial_uncertainty_dependence_summary.csv is a compact source for
    Supplementary Materials, with the separate-control FDR framework noted.

Retain the original researcher-downloaded index files and/or an independent
archive if available. Do not silently swap an updated online index for the
fixed snapshot. Do not interpret positive partial correlation as physical
independence, attribution, or predictability.
