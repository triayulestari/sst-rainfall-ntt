STEP 04 - SEASONAL SST-RAINFALL ANALYSIS, UNCERTAINTY, AND ROBUSTNESS
===================================================================

1. PURPOSE AND SCOPE
--------------------
This folder analyzes interannual covariation between regional marine sea
surface temperature (SST) and land rainfall for Flores, Sumba, and Timor,
separately for DJF, MAM, JJA, and SON during the 2016-2025 study period.
It converts monthly deseasonalized anomalies from Step 02 into complete
three-month seasonal means and documents Pearson correlations, conventional
parametric p-values, permutation-based p-values, Benjamini-Hochberg false
discovery rate (BH-FDR) adjustment, approximate confidence intervals,
leave-one-year-out (LOYO) sensitivity, and interannual-dependence diagnostics.

The analyses describe seasonal associations. They do not establish physical
causality, a rainfall forecasting model, or demonstrated predictive skill.

2. SOFTWARE, INPUT, AND EXECUTION
--------------------------------
Software: MATLAB R2021a; Statistics and Machine Learning Toolbox is needed
for Pearson correlation calculations (corr).

Primary input (generated in Step 02):
  ../02_Regional_Timeseries/regional_anomalies.mat

Keep the five MATLAB scripts in 04_Seasonal_Analysis/. Each script resolves
its file paths relative to its own saved .m file, not the MATLAB working
directory. Keep the sibling directory structure and exact input filenames.

Execute the scripts in this order:

  1. a_seasonal_mean_anomalies.m
     -> seasonal_mean_anomalies.csv
     -> seasonal_mean_anomalies.mat
     Creates complete seasonal means from monthly series.

  2. b_seasonal_correlation.m
     -> seasonal_correlation_basic.csv
     -> seasonal_correlation_basic.mat
     Reports Pearson r and ordinary two-sided parametric p-values.

  3. c_seasonal_robustness.m
     -> seasonal_robustness_results.csv
     -> seasonal_robustness_results.mat
     -> seasonal_LOYO_results.csv
     Calculates permutation p-values, Fisher-z intervals, LOYO statistics,
     and BH-FDR corrections for the 12 region-season comparisons.

  4. d_check_seasonal_annual_dependence.m
     -> seasonal_annual_dependence_QC.csv
     -> seasonal_annual_dependence_QC.mat
     -> seasonal_adjacent_year_pairs.csv
     Describes lag-1 correlations between consecutive years of the same
     season and exports the individual adjacent-year pairs.

  5. e_compile_seasonal_uncertainty.m
     -> seasonal_uncertainty_summary.csv
     Combines results from scripts c and d into one reviewer-facing table.
     This final script does not recalculate p-values or change inference.

Run script b before script c so the optional MATLAB consistency comparison
against seasonal_correlation_basic.mat in script c can be performed.

3. MONTHLY INPUT AND SEASONAL AGGREGATION
----------------------------------------
The input anomaly in this folder is the deseasonalized monthly anomaly:

  A(y,m) = X(y,m) - mean[X(available years,m)]

where m is the calendar month and the reference mean is computed within the
2016-2025 study period (Step 02). This is NOT the overall-mean anomaly and
is NOT a 30-year climatological normal.

For each season and labeled year, the seasonal anomaly is the arithmetic
mean of its three component monthly deseasonalized anomalies:

  A_season(y) = [A(month 1) + A(month 2) + A(month 3)] / 3

All three SST and rainfall months must be present for inclusion. No
interpolation, partial-season substitution, spatial weighting, or additional
detrending is performed in this folder.

The CSV also includes seasonal means of the original monthly SST and rainfall
series. Rain_raw_mean_mm_month is the average of the three calendar-month
rainfall totals (mm/month), NOT their three-month accumulated total (mm/season).

The mean of monthly deseasonalized anomalies for a fixed complete season
differs from the mean of the raw monthly values by a season-specific constant.
Therefore, subtracting these fixed calendar-month reference means does not
change the Pearson correlation calculated across the same season-years.
This does not mean that interannual variability or climate-mode influences
have been removed.

4. SEASON DEFINITIONS, YEARS, AND SAMPLE SIZES
----------------------------------------------
Season    Calendar months and label                         Years      N
------    ------------------------------------------------   ---------  --
DJF       Dec(Y-1), Jan(Y), Feb(Y); label is Jan/Feb year     2017-2025   9
MAM       Mar(Y), Apr(Y), May(Y)                             2016-2025  10
JJA       Jun(Y), Jul(Y), Aug(Y)                             2016-2025  10
SON       Sep(Y), Oct(Y), Nov(Y)                             2016-2024   9

DJF 2016 is excluded because December 2015 is outside the monthly input.
SON 2025 is excluded because the October-November 2025 SST observations are
missing. DJF 2026 is excluded because January-February 2026 are outside the
study period. These exclusions apply to all three regions to maintain aligned
SST-rainfall pairs. Missing SST months are never filled or concatenated.

Number of region-season tests: 3 regions x 4 seasons = 12.
Number of complete regional season-year records: 3 x (9+10+10+9) = 114.

5. CORRELATION AND UNCERTAINTY METHODS
-------------------------------------
5.1 Pearson correlation
For each region and season, Pearson r is calculated across the N complete
season-years (N = 9 or 10). Conventional two-sided parametric p-values are
stored for reference in seasonal_correlation_basic.csv and
seasonal_robustness_results.csv; they are not the primary basis for FDR
inference.

5.2 Two-sided yearwise permutation test
Script c uses 10,000 random permutations of the rainfall season-year values
relative to the fixed SST season-year values, independently within each of
the 12 region-season analyses. It runs MATLAB rng(2026,'twister') once at
script start. For the observed correlation r_obs:

  p_permutation = [1 + number(|r_permuted| >= |r_obs|)] / (10000 + 1)

The permutation test assumes exchangeability of season-year values under the
null. Unrestricted permutations do NOT preserve possible serial dependence
or persistent ENSO/IOD-related variability. This assumption must be kept in
mind when interpreting the resulting p-values.

5.3 Multiple testing: primary BH-FDR family
BH-FDR is applied jointly to the 12 permutation p-values (3 regions x
4 seasons), not separately by island or season. The primary adjusted values
are stored in q_FDR_permutation.

  q < 0.05         : FDR-retained at the 5% criterion
  0.05 <= q < 0.10: suggestive/exploratory only
  q >= 0.10        : not retained

A separate q_FDR_parametric column is saved only for comparison/QC. It does
not replace the primary permutation-based q-values.

5.4 Approximate 95% Fisher-z intervals
For each observed Pearson r, script c computes:

  z = atanh(r)
  CI95 = tanh[z +/- 1.96/sqrt(N-3)]

These are approximate marginal intervals for independent season-years.
They are NOT bootstrap confidence intervals, are NOT corrected for
multiple testing, and are NOT adjusted for interannual serial dependence.
The small sample sizes (9-10 years) warrant caution.

5.5 Leave-one-year-out (LOYO) analysis
For each region-season series, one complete labeled season-year is removed
at a time and Pearson r is recalculated from the remaining years. For DJF,
removing year Y removes Dec(Y-1), Jan(Y), and Feb(Y) together as one
seasonal observation. Outputs include individual removed-year correlations,
minimum, maximum, median, and percentage retaining the full-sample sign.
LOYO measures sensitivity to individual observations; it does not test
predictive skill or replace formal uncertainty estimation.

5.6 Interannual-dependence diagnostic
Script d calculates lag-1 Pearson correlations separately for SST and
rainfall between adjacent years of the SAME season, retaining only pairs
with consecutive season-year labels. DJF and SON contain eight adjacent-
year pairs; MAM and JJA contain nine pairs. The pair-level observations
are exported for review. These small-sample diagnostics neither prove
yearly independence/exchangeability nor alter the permutation p-values,
confidence intervals, or BH-FDR q-values.

6. VERIFIED RESULTS FROM THE INCLUDED OUTPUT FILES
--------------------------------------------------
The values below are transcribed from seasonal_robustness_results.csv and
seasonal_uncertainty_summary.csv provided with this folder. The latter
matches the corresponding columns of the former.

Region   Season   N     Pearson r     p_perm      q_FDR_perm
-------- ------  --    ----------    --------    ----------
Flores   DJF      9     -0.711491     0.026297     0.063114
Flores   MAM     10      0.062728     0.867313     0.867313
Flores   JJA     10      0.856872     0.001300     0.015598
Flores   SON      9      0.628390     0.066693     0.133387
Sumba    DJF      9     -0.544753     0.126087     0.216150
Sumba    MAM     10     -0.261484     0.472353     0.629804
Sumba    JJA     10      0.838180     0.004700     0.018798
Sumba    SON      9      0.417575     0.269073     0.403610
Timor    DJF      9     -0.102595     0.776522     0.847115
Timor    MAM     10     -0.165099     0.634737     0.761684
Timor    JJA     10      0.791689     0.004300     0.018798
Timor    SON      9      0.814925     0.007299     0.021898

At q < 0.05, four region-season tests are FDR-retained:
Flores JJA, Sumba JJA, Timor JJA, and Timor SON.
Flores DJF is suggestive only (q = 0.063114); Flores SON is NOT suggestive
under the stated q < 0.10 criterion (q = 0.133387).

95% Fisher-z confidence intervals for the four FDR-retained results:
  Flores JJA : [ 0.493475, 0.965567]
  Sumba JJA  : [ 0.441598, 0.960771]
  Timor JJA  : [ 0.323124, 0.948514]
  Timor SON  : [ 0.328683, 0.959667]

For these four results, the LOYO correlation remains positive in all
leave-one-year-out calculations. The full LOYO ranges and dependence
coefficients are available in seasonal_uncertainty_summary.csv.
These results are associations in small seasonal samples; causal and
predictive claims are not supported by these analyses alone.

7. OUTPUT INVENTORY AND INTEROPERABILITY
----------------------------------------
seasonal_mean_anomalies.csv:
  Long-format seasonal time series with region, season, labeled year, valid
  month counts, seasonal mean anomalies, and raw seasonal means (114 rows).

seasonal_mean_anomalies.mat:
  MATLAB Seasonal struct and named vectors needed by later MATLAB stages.
  Step 06 uses this file as an input.

seasonal_correlation_basic.csv/.mat:
  12 Pearson correlations and conventional parametric p-values.

seasonal_robustness_results.csv/.mat:
  12-test statistics, permutation p, BH-FDR q, Fisher-z CI, LOYO summaries,
  and saved permutation settings (Nperm and seed in the MAT file).

seasonal_LOYO_results.csv:
  Individual leave-one-season-year-out correlations (114 rows).

seasonal_annual_dependence_QC.csv/.mat:
  12 descriptive within-season annual-dependence summaries.

seasonal_adjacent_year_pairs.csv:
  Consecutive season-year SST/rainfall pairs used in lag-1 calculations
  (102 rows = 3 x [8+9+9+8]).

seasonal_uncertainty_summary.csv:
  Consolidated 12-test, reviewer-facing results including observed r,
  sample size, Fisher-z CI, permutation p, BH-FDR q, LOYO and annual lag-1.

Use the CSV files to inspect numerical results without MATLAB. Preserve
the MATLAB .mat inputs/outputs required by downstream scripts. The Step 04
README describes analysis results; it does not substitute for the scripts.

8. REPRODUCIBILITY AND QUALITY-CONTROL CHECKLIST
-----------------------------------------------
- Confirm that Step 02 regional_anomalies.mat has 120 consecutive monthly
  positions for three regions, with missing SST only in Oct-Nov 2025.
- Confirm that each seasonal SST/rainfall value uses exactly three valid
  monthly observations and follows the season-year definitions above.
- Confirm N = 9 for DJF and SON, and N = 10 for MAM and JJA, in each region.
- Confirm 12 correlation rows, 12 robustness rows, 114 LOYO rows, and
  102 consecutive-year-pair rows.
- Confirm that Pearson r in seasonal_correlation_basic.csv matches
  seasonal_robustness_results.csv and seasonal_annual_dependence_QC.csv.
- Confirm that the BH-FDR values are calculated from exactly 12 permutation
  p-values, and classify findings using q_FDR_permutation, not raw p-values.
- Confirm that compiled uncertainty values match the source CSVs.
- Verify downstream figures and manuscript tables against these FINAL
  output files; do not mix estimates from older analysis versions.

9. SCIENTIFIC LIMITATIONS
------------------------
The study uses only 9-10 observations per region-season correlation. Pearson
r, Fisher-z intervals, and yearwise permutations are sensitive to small
samples and underlying assumptions. The lag-1 diagnostic has only 8-9
adjacent-year pairs and does not establish temporal independence. The
analysis uses regional time series from geographical rectangles rather than
island-specific polygon masks; the spatial-definition limitations are
specified in Step 02. The results concern interannual covariation within
seasons, not a demonstrated physical mechanism or operational prediction.

10. REPOSITORY DATA POLICY
--------------------------
The scripts and derived reproducibility outputs are suitable for GitHub.
The original Himawari and CHIRPS NetCDF inputs are not redistributed here;
see Step 01 for the provider data sources and cropping instructions.
Maintain the exact MATLAB filenames in the repository (without upload-
generated suffixes such as '(3)' or '(4)').
