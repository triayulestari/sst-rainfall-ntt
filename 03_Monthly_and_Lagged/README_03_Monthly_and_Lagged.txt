STEP 03 - MONTHLY ZERO-LAG AND LAGGED CORRELATIONS
=================================================

PURPOSE
-------
Evaluate monthly Pearson correlations between regional SST and land rainfall
for raw time series, overall-mean anomalies, deseasonalized anomalies,
and deseasonalized and detrended anomalies; assess lagged relationships.

SOFTWARE AND INPUT
------------------
MATLAB R2021a (Statistics and Machine Learning Toolbox for relevant tests).
Input: ../02_Regional_Timeseries/regional_anomalies.mat
Keep this file in Step 02; the scripts use relative paths.

RUN THESE SCRIPTS IN ORDER
--------------------------
1. a_monthly_zero_lag.m
   Outputs: monthly_zero_lag_correlation.csv and .mat
   Compares four time-series definitions at lag zero.
2. b_autocorrelation_effective_n.m
   Outputs: autocorrelation_effectiveN.csv and .mat
   Estimates adjacent-month lag-1 autocorrelation and effective sample
   size (N_eff), accounting for the missing 2025 SST gap.
3. c_lagged_correlation.m
   Outputs: lagged_correlation_results.csv and .mat
   Evaluates lags -6 to +6 months (3 regions x 13 lags = 39 primary tests).

STATISTICAL CONVENTIONS
-----------------------
- Pearson correlation (r) describes a linear statistical association.
- Zero-lag correlation compares SST and rainfall in the same month.
- Positive lag +k: SST precedes rainfall by k months.
- Negative lag -k: rainfall precedes SST by k months.
- Only valid, correctly aligned monthly pairs are used.
- Autocorrelation-adjusted p-values are based on an effective sample size.
- Primary BH-FDR family: all 39 region-lag tests (lags -6 through +6).
  Restricted positive-lag checks are secondary; do not replace the primary
  39-test correction used in the manuscript.
- qFDR < 0.05: statistically significant; 0.05 <= qFDR < 0.10:
  exploratory only, not significant at the primary threshold.

EXPECTED MAIN RESULTS (FOR QUALITY CONTROL)
-------------------------------------------
- Zero-lag deseasonalized r: Flores 0.091; Sumba 0.052; Timor 0.135.
- Notable lag coefficients: Flores +4 r about 0.300; Timor +4 r about
  0.264; Sumba +2 r about 0.174.
- No lagged association is significant after the primary 39-test BH-FDR.
- Figure 3 reads lagged_correlation_results.csv directly from this folder.

REPRODUCIBILITY
---------------
Publish original .m scripts, final .csv outputs and relevant .mat inputs/
outputs. Missing October-November 2025 SST values must not be interpolated.
These lagged associations do not demonstrate causal delay or predictive skill.
