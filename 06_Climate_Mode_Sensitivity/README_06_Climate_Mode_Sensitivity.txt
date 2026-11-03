STEP 06 - LARGE-SCALE CLIMATE-MODE SENSITIVITY
==============================================

PURPOSE
-------
Assess the sensitivity of seasonal SST-rainfall linear associations to
Niño 3.4 (ENSO) and Dipole Mode Index (DMI; Indian Ocean Dipole) using
partial correlations. Each index is adjusted for SEPARATELY, not jointly.
Partial correlation does not remove all climate-mode physics or establish
causal attribution.

SOFTWARE AND SOURCE
-------------------
MATLAB R2021a.
NOAA Physical Sciences Laboratory (PSL) monthly indices:
https://psl.noaa.gov/data/timeseries/month/Nino34/
https://psl.noaa.gov/data/timeseries/month/DMI/
The original NOAA PSL Niño 3.4 and DMI data were downloaded on
12 September 2026 (researcher record).
The deposited climate_indices_input_2016_2025.csv is the fixed monthly
snapshot used for reproducing the analysis. See
NOAA_PSL_Index_Provenance.txt in this folder for the source definitions,
download date, and remaining verification limitations. A complete snapshot
alone is not independent validation that all values match the source files.

RUN IN ORDER
------------
1. a_prepare_climate_indices.m
   Input: climate_indices_input_2016_2025.csv (default snapshot_csv mode)
   Outputs: climate_indices_2016_2025.mat,
            climate_indices_monthly.csv,
            climate_indices_seasonal.csv,
            climate_indices_QC.csv
   Optional annual_txt mode reads nina34.anom.data.txt and
   dmi.had.long.data.txt if these source files have been obtained.
2. b_seasonal_partial_correlation.m
   Inputs: ../04_Seasonal_Analysis/seasonal_mean_anomalies.mat,
           climate_indices_2016_2025.mat
   Outputs: seasonal_partial_correlation_results.csv,
            seasonal_partial_correlation_results.mat,
            seasonal_partial_correlation_QC.csv
3. c_seasonal_partial_robustness.m
   Input: seasonal_partial_correlation_results.mat
   Outputs: seasonal_partial_robustness_results.csv,
            seasonal_partial_robustness_results.mat,
            seasonal_partial_LOYO_results.csv,
            seasonal_partial_permutation_QC.csv
4. d_check_partial_uncertainty_dependence.m
   Inputs: seasonal_partial_correlation_results.mat,
           seasonal_partial_robustness_results.csv
   Outputs: partial_uncertainty_dependence_summary.csv,
            partial_residual_adjacent_year_pairs.csv

STATISTICAL FRAMEWORK
---------------------
- Seasonal indices are averaged over the same complete three-month
  seasons as the SST/rainfall data (DJF n=9; MAM/JJA n=10; SON n=9).
- Partial r is the correlation between residual SST and residual rainfall
  after regression on a constant and ONE corresponding climate index.
- 10,000 conditional residual permutations (Freedman-Lane-style);
  two-sided; MATLAB rng(2026,'twister') and plus-one p correction.
- Separate BH-FDR families: 12 region-season tests per index (24 results
  across both independently adjusted analyses).
- 95% Fisher-z intervals, LOYO and lag-1 interannual residual/index
  diagnostics are included as sensitivity and uncertainty information.
- Yearwise residual permutations may not preserve climate-mode persistence.
  The samples are small and the resulting inference has limited precision.

QUALITY-CHECK REFERENCE RESULTS
-------------------------------
- No partial correlations meet qFDR < 0.05 for either climate index.
- Niño 3.4-adjusted JJA partial r: Flores 0.835, Sumba 0.821,
  Timor 0.741. Flores/Timor JJA qFDR = 0.0840 (exploratory only).
- DMI-adjusted JJA partial r: Flores 0.698, Sumba 0.665, Timor 0.655;
  none significant after BH-FDR.
- Positive residual correlations do NOT establish independence from
  ENSO or IOD and do not demonstrate rainfall prediction skill.

REPRODUCIBILITY
---------------
Publish the fixed climate-index input CSV, original scripts, relevant
MAT inputs/outputs and CSV result tables. Figure 5 reads
seasonal_partial_robustness_results.csv from this folder.
