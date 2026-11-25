STEP 03 - MONTHLY ZERO-LAG AND LAGGED SST-RAINFALL CORRELATIONS
================================================================

1. PURPOSE
----------
This step evaluates the statistical association between monthly regional-mean
sea surface temperature (SST) and land precipitation in Flores, Sumba, and
Timor over January 2016-December 2025. It performs (i) four zero-lag Pearson
correlation analyses, (ii) a lag-1-autocorrelation-based effective-sample-size
assessment for deseasonalized zero-lag correlations, and (iii) deseasonalized
lagged correlations for shifts from -6 to +6 months with Benjamini-Hochberg
false-discovery-rate (BH-FDR) correction.

The scripts use the regional products generated in Step 02. This step does not
extract data from the original NetCDF files or apply additional spatial masks.

2. SOFTWARE, INPUT, AND FOLDER STRUCTURE
---------------------------------------
Software: MATLAB R2021a with Statistics and Machine Learning Toolbox
          (including corr and tcdf).

Required input:
  ../02_Regional_Timeseries/regional_anomalies.mat

That file contains 120 calendar-month positions and three regional columns in
the order Flores, Sumba, Timor, including the following MATLAB arrays:
  SST, RAIN
  SST_overall_anom, RAIN_overall_anom
  SST_deseason, RAIN_deseason
  SST_deseason_detrended, RAIN_deseason_detrended
  time

Expected project layout (Data is the local parent directory):

Data/
  02_Regional_Timeseries/
    regional_anomalies.mat
  03_Monthly_and_Lagged/
    README_03_Monthly_and_Lagged.txt
    a_monthly_zero_lag.m
    b_autocorrelation_effective_n.m
    c_lagged_correlation.m
    monthly_zero_lag_correlation.csv
    monthly_zero_lag_correlation.mat
    autocorrelation_effectiveN.csv
    autocorrelation_effectiveN.mat
    lagged_correlation_results.csv
    lagged_correlation_results.mat

All scripts resolve the input path from their own saved file location; MATLAB's
current working directory is not used to locate the data. Keep the Step 02 and
Step 03 folders as siblings and retain their required file names.

3. EXECUTION AND OUTPUTS
------------------------
Recommended execution and review order:

A. Run a_monthly_zero_lag.m
   Output: monthly_zero_lag_correlation.csv / .mat
   Compares four monthly series definitions at lag zero for each region:
     Raw
     Overall_mean_anomaly
     Deseasonalized
     Deseasonalized_detrended
   CSV fields: Region, Series, N_valid_pairs, Pearson_r, p_raw.
   The 12 output rows correspond to 3 regions x 4 series definitions.

B. Run b_autocorrelation_effective_n.m
   Output: autocorrelation_effectiveN.csv / .mat
   Computes the autocorrelation-adjusted significance of DESEASONALIZED
   zero-lag correlations only, using an approximate effective sample size.
   CSV fields: Region, Pearson_r, N_original, SST_lag1, Rain_lag1,
   SST_adjacent_pairs, Rain_adjacent_pairs, N_effective,
   N_reduction_percent, p_raw, p_autocorr_adjusted.

C. Run c_lagged_correlation.m
   Output: lagged_correlation_results.csv / .mat
   Computes 13 lags (-6 through +6) for each of 3 regions (39 rows).
   CSV fields: Region, Lag_month, Direction, N, Pearson_r, SST_lag1,
   Rain_lag1, N_effective, p_raw, p_autocorr_adjusted,
   q_FDR_all39, q_FDR_lag0_to_plus6, FDR_status_all39,
   SST_adjacent_pairs, Rain_adjacent_pairs.

Each of the three scripts independently reads Step 02's regional_anomalies.mat;
script B does not load script A's output, and script C does not load outputs
from scripts A or B. The listed order is recommended for transparent review,
not a computational dependency between these three scripts.

4. TIME AXIS, DATA PAIRING, AND DEFINITIONS
-------------------------------------------
The common calendar contains 120 consecutive months, January 2016 through
December 2025. SST is missing for October and November 2025 in the study
input; those two monthly entries remain NaN. CHIRPS regional rainfall has
120 available monthly entries. No interpolation or gap compression is used.

A valid Pearson correlation pair requires both SST and rainfall values to be
finite at the correctly aligned time positions. All four zero-lag series
have 118 valid pairs per region. The lagged-pair count depends on the shift
and on the positions of the two missing SST months.

Definitions inherited from Step 02:
  Raw: regional monthly SST (degrees Celsius) and rainfall (mm/month).
  Overall-mean anomaly: value minus the overall available study-period mean.
  Deseasonalized anomaly: value minus the 2016-2025 mean for the corresponding
      calendar month (January minus the January mean, and so forth).
  Deseasonalized/detrended: deseasonalized anomaly minus its fitted linear
      trend evaluated at the original calendar-month positions.

The study-period calendar-month means are based on the available observations;
these are not 30-year climatological normals. Subtracting a fixed overall mean
from each variable does not change the Pearson correlation coefficient.

IMPORTANT: The effective-N and lagged-correlation scripts use SST_deseason and
RAIN_deseason, NOT the overall-mean anomalies or detrended series. In the
CSV output from script A, p_raw means an ordinary (unadjusted) Pearson
p-value; it does NOT identify the 'Raw' series category.

5. LAG CONVENTION
-----------------
For a lag L expressed in whole calendar months:

  L =  0: corr[SST(t),   Rain(t)]       concurrent relationship
  L = +k: corr[SST(t),   Rain(t+k)]     SST leads rainfall by k months
  L = -k: corr[SST(t+k), Rain(t)]       rainfall leads SST by k months

where k is a positive integer. The scripts evaluate L = -6, ..., +6.
Shifting is applied to the original 120-position monthly arrays BEFORE
selecting valid SST-rainfall pairs. Therefore, the two missing SST months are
never replaced or treated as if adjacent calendar months had become consecutive.

A positive lag reports the direction of temporal alignment only. It does not
establish an SST-driven mechanism, causality, or out-of-sample predictability.

6. AUTOCORRELATION AND EFFECTIVE SAMPLE SIZE
--------------------------------------------
Script B adjusts the significance assessment of the zero-lag deseasonalized
Pearson r. Script C applies the same procedure separately for every lag.

For each aligned SST and rainfall series, lag-1 autocorrelation is computed
from adjacent, individually finite observations in the original aligned time
vectors. The SST and rainfall adjacent-pair sets are evaluated separately;
they are not limited to a shared complete-case subset. A calendar gap is never
bridged by removing missing entries before calculating lag-1 autocorrelation.

Let N be the number of correctly aligned, valid SST-rainfall pairs, and let
rho_SST(1) and rho_Rain(1) be the respective lag-1 autocorrelations. The
implemented effective-sample-size approximation is

  N_eff = N * [1 - rho_SST(1)*rho_Rain(1)]
              / [1 + rho_SST(1)*rho_Rain(1)].

The scripts constrain N_eff to the interval [3, N]. The two-sided adjusted
t test uses

  df = N_eff - 2
  t  = r * sqrt[ (N_eff - 2) / (1 - r^2) ]
  p_autocorr_adjusted = 2 * P(T_df >= abs(t)).

N_eff may be non-integer. This procedure is an approximation for serial
persistence, not an exact correction for every form of time dependence.
Ordinary Pearson p-values (p_raw) are also retained for comparison.

For the zero-lag deseasonalized series, there are 116 valid adjacent SST pairs
and 119 adjacent rainfall pairs in each region. The source correlations have
118 complete SST-rainfall pairs per region.

7. MULTIPLE TESTING: PREDEFINED FAMILIES
----------------------------------------
Primary family, as implemented in script C:
  All 3 regions x 13 lags (-6 through +6) = 39 tests.
  BH-FDR is applied jointly to the 39 autocorrelation-adjusted p-values.
  The result is q_FDR_all39, used for the primary inferential interpretation.

Secondary, restricted family:
  All 3 regions x 7 nonnegative lags (0 through +6) = 21 tests.
  A separate BH-FDR correction gives q_FDR_lag0_to_plus6.
  This column is NaN for negative-lag rows and is an exploratory sensitivity
  comparison; it does not replace the primary 39-test family.

Interpretation conventions:
  q_FDR_all39 < 0.05: retained at the primary 5% FDR threshold.
  0.05 <= q_FDR_all39 < 0.10: exploratory/suggestive only.
  q_FDR_all39 >= 0.10: does not meet either threshold above.

The software's output labels and threshold classifications use the PRIMARY
39-test q-values. Values from the secondary 21-test family must be clearly
identified when reported. Scripts A and B do not themselves perform BH-FDR.

8. VERIFIED OUTPUT VALUES FROM THE SUPPLIED CSV/MAT FILES
----------------------------------------------------------
The values below describe the supplied Step 03 output files; they are not
parameter settings or expected values hard-coded in the MATLAB scripts.

A. Zero-lag Pearson r (all N = 118; 2016-2025)

Region   Raw = Overall-mean   Deseasonalized   Deseasonalized + detrended
Flores        +0.5680             +0.0756                 +0.0871
Sumba         +0.7179             +0.0392                 +0.0593
Timor         +0.7163             +0.1224                 +0.1394

B. Zero-lag deseasonalized correlations with effective-N adjustment

Region      N       N_eff       r          p_autocorr_adjusted
Flores     118      97.166     +0.0756             0.4611
Sumba      118     102.168     +0.0392             0.6951
Timor      118     105.544     +0.1224             0.2124

C. Strongest POSITIVE-lag Pearson r by region

Region   Lag    N        r      p_autocorr_adjusted  q_FDR_all39  q_FDR_lag0_to_plus6
Flores    +4   116     +0.2882        0.0043            0.1026             0.0552
Sumba     +2   117     +0.1840        0.0626            0.2713             0.1461
Timor     +4   116     +0.2557        0.0095            0.1026             0.0552

Across ALL 39 primary tests, no q_FDR_all39 is below 0.05 or below 0.10;
the minimum primary q-value is approximately 0.1026. Thus no regional
lagged association meets the primary BH-FDR significance criterion.
The secondary 21-test analysis also has no q-value below 0.05. Six tests
have secondary q-values between 0.05 and 0.10 (Flores +2, +3, +4; Timor +2,
+3, +4); these are exploratory only and are not primary FDR-retained results.

9. INTEGRITY AND REPRODUCTION CHECKS
------------------------------------
When reviewing or regenerating the outputs, verify that:
  [ ] Step 02 regional_anomalies.mat is the intended, unchanged input version.
  [ ] The time axis spans 120 uncompressed calendar-month positions.
  [ ] SST has exactly the two intended missing months (2025-10 and 2025-11).
  [ ] monthly_zero_lag_correlation.csv contains 12 rows, all with N = 118.
  [ ] Raw and overall-mean-centered Pearson r agree within numerical precision.
  [ ] autocorrelation_effectiveN.csv contains 3 rows and its r matches the
      corresponding zero-lag deseasonalized r from script A.
  [ ] The lag-0 rows of lagged_correlation_results.csv agree with script B
      for r, N, lag-1 autocorrelation, N_eff, and adjusted p-value.
  [ ] lagged_correlation_results.csv contains 39 rows (13 per region), with
      q_FDR_all39 computed over all 39 tests and restricted q-values only for
      lag 0 through +6.
  [ ] Each CSV has matching numeric values in its companion MAT file.
  [ ] Any number transcribed to figures, Supplementary Materials, or the
      manuscript comes from the same final analysis/output version.

Independent numerical checks of the supplied Step 02 MAT against the Step 03
CSVs reproduced all zero-lag r/p-values, all lag coefficients, the effective-N
calculations, and both BH-FDR families within numerical precision. The Step 03
CSV columns checked against their corresponding MAT arrays were consistent.
This is a computational consistency check; it is not independent validation of
SST/CHIRPS observations, regional domain choices, or the scientific mechanism.

10. REPOSITORY SCOPE AND LIMITATIONS
------------------------------------
Commit the original .m scripts plus the final .csv and .mat outputs. Retain
regional_anomalies.mat in Step 02, because each Step 03 script reads it at
runtime. The original cropped/source NetCDF files are managed locally and are
not redistributed in this GitHub repository.

The apparent strength of raw monthly correlations can reflect shared seasonality;
regional deseasonalized correlations address a different question. The
approximate effective-N procedure depends on a lag-1 persistence model, and
correlations across overlapping lags and neighboring regions are statistically
dependent. BH-FDR handles the specified multiplicity but does not remove these
scientific limitations. Results should not be characterized as evidence of
causality, physical lag mechanisms, or demonstrated forecasting skill.

The Figure 3 workflow uses lagged_correlation_results.csv from this folder;
Figure generation and figure-specific quality checks are documented in Step 08.
