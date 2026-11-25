# Seasonal and Spatial SST–Rainfall Relationships across Flores, Sumba, and Timor (2016–2025)

**Reproducibility package for the manuscript:**  
*Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor*

**Repository:** https://github.com/triayulestari/sst-rainfall-ntt  
**Study period:** January 2016–December 2025  
**Study regions:** Flores, Sumba, and Timor, East Nusa Tenggara (NTT), Indonesia  
**Software:** GrADS 2.2.1 and MATLAB R2021a (plus the dependencies noted below)

## 1. Purpose and scope

This repository documents the workflow used to prepare satellite-derived marine sea surface temperature (SST) and land rainfall data, calculate temporal and spatial SST–rainfall associations, assess statistical uncertainty and sensitivity, produce Figures 1–5, and compare Himawari-8 and Himawari-9 SST source scenarios for October–November 2022.

It contains research scripts (`.gs` and `.m`), selected intermediate MATLAB arrays (`.mat`), readable numerical and quality-control outputs (`.csv`), final manuscript figures (`.png`), and stage-specific documentation. **Original and cropped SST/rainfall NetCDF files are not redistributed in the intended public code/data package.** Consequently, reproducing analyses from the original satellite observations requires downloading the source data, whereas many later analyses can be reproduced from the supplied intermediate MAT/CSV files.

The reported findings concern statistical associations during the **2016–2025 observational period**. They do not establish causality, climate-mode independence, rainfall-forecasting skill, or long-term climatic relationships.

## 2. Repository structure and execution order

Preserve **all nine numbered directories** under a common parent directory. MATLAB inputs are resolved relative to the saved scripts. The following lists the major components; the stage folders also contain scripts, CSV/MAT outputs, QC files and documentation described in Sections 6–9.

```text
sst-rainfall-ntt/
├── README.md
├── 01_SST_Rainfall_NTT_2016_2025/
│   ├── README_01_SST_Rainfall_NTT_2016_2025.txt
│   ├── 01_Crop_SST_NTT/                 # GrADS monthly Himawari SST cropping
│   └── 02_Crop_CHIRPS_NTT/              # GrADS yearly CHIRPS cropping
├── 02_Regional_Timeseries/              # Regional monthly means and anomalies
├── 03_Monthly_and_Lagged/               # Monthly and lagged correlation statistics
├── 04_Seasonal_Analysis/                # Seasonal r, permutation, FDR, LOYO, CI
├── 05_Spatial_Analysis/                 # Gridwise rainfall correlations and FDR
├── 06_Climate_Mode_Sensitivity/         # Separate Niño 3.4 / DMI adjustments
├── 07_Robustness_Tests/                 # Domain, subdomain, trend, year, resolution
├── 08_Figures/                          # Manuscript Figures 1–5 and figure QC
└── 09_Transition_Sensitivity/           # H08/H09 Oct–Nov 2022 source scenarios
    ├── 00_Original_Methods/            # Frozen copies of 20 MATLAB methods
    ├── 00_Original_Methods_SHA256.csv
    ├── 01_SST_H08_H09_Overlap_202210_202211/ # Local-only source NetCDF inputs
    ├── 02_Comparison_Outputs/
    ├── 03_Scenarios/H08_Final/
    ├── 03_Scenarios/H09_Alternative/
    ├── 04_Comparison/
    ├── 05_Run_Logs/
    ├── a_compare_h08_h09_overlap.m
    ├── b_prepare_h09_scenario.m
    ├── run_H08_H09_clean.m
    ├── z_compare_scenarios.m
    └── README_09_Transition_Sensitivity.txt
```

Read the stage-specific documentation before executing its scripts:

| Stage | Documentation | Function |
|---|---|---|
| 01 | [Crop SST/CHIRPS](01_SST_Rainfall_NTT_2016_2025/README_01_SST_Rainfall_NTT_2016_2025.txt) | Source files, units, crop and availability |
| 02 | [Regional time series](02_Regional_Timeseries/README_02_Regional_Timeseries.txt) | Regional means and anomaly definitions |
| 03 | [Monthly and lagged](03_Monthly_and_Lagged/README_03_Monthly_and_Lagged.txt) | Monthly correlations and effective N |
| 04 | [Seasonal analysis](04_Seasonal_Analysis/README_04_Seasonal_Analysis.txt) | Seasonal permutations, FDR, CI, LOYO |
| 05 | [Spatial analysis](05_Spatial_Analysis/README_05_Spatial_Analysis.txt) | Grid masks, two FDR families |
| 06 | [Climate-mode sensitivity](06_Climate_Mode_Sensitivity/README_06_Climate_Mode_Sensitivity.txt) | Niño 3.4/DMI index snapshots and partial r |
| 07 | [Robustness tests](07_Robustness_Tests/README_07_Robustness_Tests.txt) | Four sensitivity analyses |
| 08 | [Figures](08_Figures/README_08_Figures.txt) | Figure scripts and visual QC |
| 09 | [H08/H09 transition sensitivity](09_Transition_Sensitivity/README_09_Transition_Sensitivity.txt) | Controlled source comparison and scenario audit |

**Main analysis dependency map:**

```text
Provider SST / CHIRPS NetCDF
  └── 01 Cropping
        └── 02 Regional time series and anomalies
              ├── 03 Monthly / lagged
              ├── 04 Seasonal ──────┐
              │       └── 06 Climate-mode adjustment
              └── 05 Spatial ───────┤
                      07 Robustness (also needs Stage 01 for SST domains)

08 Figures: reads source NetCDF and/or results from 02–06
09 Source-transition experiment: reads overlap SST source data,
   the main Stage 02 baseline and selected inputs, then reruns
   isolated H08_Final / H09_Alternative branches through eligible Stage 07 methods
```

Stage 09 is **a controlled companion sensitivity experiment**, not a replacement of Stages 01–08. It retains its own frozen method scripts and scenario outputs and must not overwrite the main study results. Changes in the working directory or script names will break relative-path assumptions.

## 3. Original data products and provenance

**CHIRPS nomenclature:** This study uses **Climate Hazards Center Infrared Precipitation with Stations (CHIRPS) version 3.0**, consistent with the [official CHIRPS v3 product page](https://www.chc.ucsb.edu/data/chirps3) and [Funk et al. (2026)](https://doi.org/10.1038/s41597-026-07096-4). The [CHC datasets index](https://www.chc.ucsb.edu/data) also uses the wording “InfraRed Precipitation with Station data” (singular). These are naming variants, **not separate rainfall products**; this repository consistently uses *Stations* when expanding the v3 acronym.

| Variable | Product and version used | Resolution | Study availability | Provider |
|---|---|---|---|---|
| Marine SST | **Himawari-8 Level-3 SST (v2.0)** and **Himawari-9 Level-3 SST (v2.1)**; exact October–November 2022 source choice requires the lineage check below | Monthly, nominal **0.02° × 0.02°** | **118/120** months; October–November 2025 missing | [JAXA Himawari Monitor/P-Tree](https://www.eorc.jaxa.jp/ptree/registration_top.html) |
| Land rainfall | **CHIRPS version 3.0**, monthly | **0.05° × 0.05°** | **120/120** months | [Climate Hazards Center, UCSB](https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/global/netcdf/by_year/) |
| ENSO indicator | Monthly **Niño 3.4 SST anomaly**; fixed study CSV snapshot consistent with the NOAA PSL **ERSST-based Niño 3.4 anomaly** series (not the HadISST landing-page series) | Monthly | 120 months in the snapshot | [NOAA PSL Niño 3.4 annual data](https://psl.noaa.gov/data/correlation/nina34.anom.data) |
| IOD indicator | Monthly **Dipole Mode Index (DMI)**; fixed study CSV snapshot | Monthly | 120 months in the snapshot | [NOAA PSL DMI](https://psl.noaa.gov/data/timeseries/month/DMI/) |

**Original download dates (researcher records):** Himawari SST and CHIRPS v3.0 were first downloaded on **29 July 2026**; the NOAA PSL Niño 3.4 and DMI series were first downloaded on **12 September 2026**. These dates identify the original data retrieval, not independent verification that currently available provider files are numerically unchanged. See [Stage 06 NOAA PSL index provenance](06_Climate_Mode_Sensitivity/NOAA_PSL_Index_Provenance.txt) for remaining source-snapshot checks.

### Critical source-lineage reconciliation before a full raw-data rerun

**The saved main Stage 02 SST observations for October–November 2022 match the `H08_Final` reference used in Stage 09.** By contrast, the currently supplied `01_Crop_SST_NTT/01_crop_himawari_sst_ntt.gs` selects **Himawari-9 starting in October 2022** (`if (year = 2022 & month <= 9)` is the final H08 branch). Therefore, **running that GrADS script as supplied would not reconstruct the Stage 02 H08-reference series for those two months**. This is a code-to-data provenance discrepancy, not merely a README wording issue.

Before declaring the repository fully reproducible *from raw observations*, reconcile the actual final input inventory, Stage 01 SST source-selection logic and Stage 02 saved reference values; rerun the Stage 02 baseline QC. One candidate correction, **only if the original H08-reference lineage is confirmed**, is to retain H08 through **November 2022** and switch to H09 for **December 2022 onward**. Do not silently change the source mapping or overwrite validated outputs. The main results reproduced from the **deposited Stage 02 MAT/CSV intermediates** and the downstream numerical checks remain separately documented.

The sensitivity analysis in [Stage 09](09_Transition_Sensitivity/README_09_Transition_Sensitivity.txt) compares the H08 reference and H09 alternative **for October–November 2022 only**. A source-product contrast (different satellite platform and processing-product version) is not an independent accuracy validation or the operational satellite handover date.

SST values in the cropped NetCDF files are in **degrees Celsius** (the GrADS SST cropping script subtracts 273.15 from the Kelvin input). Cropped CHIRPS data represent monthly accumulated precipitation, retained in **mm per calendar month**; they are not multiplied or divided by 1,000 in subsequent scripts.

**Source-data limitation:** The exact original SST/rainfall NetCDF collections must be obtained from the providers. The release should retain the source filenames, product-version details, and download/access dates in the stage-specific documentation. A downloaded, reprocessed, or updated index series may differ from the fixed CSV snapshot used for the published analyses; see Stage 06 before replacing that input.

### 3.1 Local files needed for a full run from NetCDF

Stage 01 cropping scripts are kept inside their respective crop subfolders. Their original GrADS input paths assume a **local, untracked** `00_Raw_Data` directory alongside the crop subfolders:

```text
01_SST_Rainfall_NTT_2016_2025/
├── 00_Raw_Data/                     <- LOCAL ONLY; not uploaded to GitHub
│   ├── Himawari_SST_L3_FullDisk/    <- original monthly JAXA SST NetCDFs
│   └── CHIRPS_v3_Monthly_Global/    <- original yearly CHIRPS NetCDFs
├── 01_Crop_SST_NTT/
│   ├── 01_crop_himawari_sst_ntt.gs
│   └── sst_YYYYMM.nc               <- generated locally; not uploaded
└── 02_Crop_CHIRPS_NTT/
    ├── 02_crop_chirps_v3_ntt.gs
    └── prec_YYYY.NTT.nc            <- generated locally; not uploaded
```

**Important GrADS execution detail:** The `.gs` scripts use relative `../00_Raw_Data/...` paths and write NetCDF output to the **current GrADS working directory**. Run each script with its respective crop subfolder as the working directory, or configure the current directory accordingly. The executable path statements take precedence over legacy header comments. **Correct paths alone do not resolve the October–November 2022 H08/H09 source-selection discrepancy noted above.**

The cropped filenames required by downstream MATLAB scripts are:

- SST: `01_Crop_SST_NTT/sst_YYYYMM.nc` — 118 monthly files (2016–2025 excluding October–November 2025).
- Rainfall: `02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc` — 10 yearly files, each containing 12 monthly rainfall fields.

The common NTT cropping frame is **118°–127.5°E, 11.5°–7°S**. GrADS performs spatial subsetting; **no spatial interpolation** is applied.

## 4. Study regions, valid grids, and spatial handling

Three **study regions** are defined by geographical coordinate rectangles rather than administrative boundaries or polygon masks:

| Region | SST marine rectangle (°E, °N) | CHIRPS rainfall rectangle (°E, °N) |
|---|---|---|
| Flores | 119.0–123.5, −9.2 to −7.9 | 118.975–123.525, −9.225 to −7.875 |
| Sumba | 118.8–121.2, −10.5 to −9.2 | 118.775–121.225, −10.525 to −9.175 |
| Timor | 123.3–126.0, −10.6 to −8.6 | 123.275–126.025, −10.625 to −8.575 |

The small differences in box boundaries reflect the native grid coordinates of the respective products. The Timor CHIRPS rectangle also includes land in **Timor-Leste**; it does not represent only the administrative territory of NTT Province.

**Valid-grid selection is data-driven, not a newly constructed coastline or administrative mask:**

- Regional mean SST and rainfall are unweighted arithmetic means of the **available finite grid values** in their respective geographical rectangles. MATLAB uses finite-value checks and exclusion of missing values (`isnan`/`isfinite`, equivalent to omitting NaNs for the available numeric data); **no area weighting, interpolation, or additional island-polygon masking** is applied.
- For the Stage 05 spatial correlation map, a **fixed valid CHIRPS grid** is defined as a grid cell with finite rainfall data in **all 120 calendar months**, using a condition equivalent to `all(isfinite(rainfall),3)`. This is a data-availability mask, **not** an external geographic mask. It is recorded in `spatial_valid_grid_mask.csv` and the stage's MAT output.
- The fixed spatial selection comprises **1,158 Flores**, **565 Sumba**, and **1,088 Timor** **region-grid tests** (**2,811 total**). The rectangular domains overlap at some coordinates: these include **2,791 distinct longitude–latitude positions**. Neither spatial neighbors nor repeated coordinates should be treated as independent replications.

For the spatial results, `within-region BH-FDR` is applied separately within each region's valid cells. `Pooled BH-FDR across the three study regions` jointly adjusts all **2,811 region-grid tests**. These are distinct multiple-testing families, **not** alternative spatial masks. This is **not** a province-wide test of all NTT land grids.

## 5. Temporal preprocessing and anomaly definitions

1. Extract **monthly regional means** from each product on its original grid (Stage 02).
2. Retain all **120 monthly calendar positions**, January 2016–December 2025; SST October–November 2025 remain **NaN**, without temporal interpolation or bridging across the gap.
3. Compute the **study-period monthly means**: the mean for each of the 12 calendar months over the available years in 2016–2025. SST October and November use **nine available years**; other SST calendar months and all rainfall calendar months use **ten years**.
4. Define the **deseasonalized anomaly** as the observation minus the **study-period monthly mean for the same calendar month**. This removes the **mean annual cycle**, not all monsoonal or climate-mode influences.
5. Retain separate comparisons based on the **raw time series**, **overall-mean anomalies** (observation minus the full-period mean), and **deseasonalized and detrended anomalies** (linear trend removed from deseasonalized anomalies).
6. Use only contemporaneously available pairs for each correlation, with **118 monthly paired observations at zero lag**. The number of available pairs can differ with lag.

Seasonal analysis first averages the three **monthly deseasonalized anomalies** within each *complete* season-year; incomplete seasons are excluded.

| Season | Calendar rule | Season-years | n |
|---|---|---|---:|
| DJF | December of year *Y−1*, January–February of *Y* | 2017–2025 | 9 |
| MAM | March–May of *Y* | 2016–2025 | 10 |
| JJA | June–August of *Y* | 2016–2025 | 10 |
| SON | September–November of *Y* | 2016–2024 | 9 |

SON 2025 is excluded because SST observations for October and November 2025 are unavailable.

## 6. Executable analysis inventory: scripts, inputs, and outputs

**Important:** File names below are the exact *script-internal* names. If downloaded files have suffixes such as `(1)` or `(2)`, restore the original `.m`/`.gs` filenames before running them. Keep all generated files in their original numbered directories; do not move MAT/CSV dependencies into `08_Figures`.

### Stage 01 — `01_SST_Rainfall_NTT_2016_2025`

| Script | Input | Output |
|---|---|---|
| `01_Crop_SST_NTT/01_crop_himawari_sst_ntt.gs` | Original JAXA Level-3 monthly NetCDFs | `01_Crop_SST_NTT/sst_YYYYMM.nc` |
| `02_Crop_CHIRPS_NTT/02_crop_chirps_v3_ntt.gs` | Original CHIRPS v3.0 yearly NetCDFs | `02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc` |

**Note:** Original and cropped NetCDFs remain local and are **not** included in GitHub.

### Stage 02 — `02_Regional_Timeseries`

| Run order / script | Required input | Principal output |
|---|---|---|
| `a_extract_regional_timeseries.m` | Stage 01 cropped SST and CHIRPS NetCDF | `regional_timeseries_raw.mat`, `regional_timeseries_raw.csv`, `regional_grid_check.csv`, `regional_domain_grid_metadata.csv`, `regional_data_availability.csv` |
| `b_compute_regional_anomalies.m` | `regional_timeseries_raw.mat` | `regional_anomalies.mat`, `regional_anomalies.csv`, `regional_calendar_month_means.csv`, `regional_detrending_summary.csv` |

`regional_anomalies.mat` contains the 120-position time axis and monthly regional SST/rainfall arrays used by Stages 03, 04, 05, and plotting. Its MAT structure, including MATLAB `datetime` values, **cannot automatically be replaced by a same-named CSV** without changing the scripts.

### Stage 03 — `03_Monthly_and_Lagged`

| Run order / script | Required input | Principal output |
|---|---|---|
| `a_monthly_zero_lag.m` | Stage 02 `regional_anomalies.mat` | `monthly_zero_lag_correlation.csv` and `.mat` |
| `b_autocorrelation_effective_n.m` | Stage 02 `regional_anomalies.mat` | `autocorrelation_effectiveN.csv` and `.mat` |
| `c_lagged_correlation.m` | Stage 02 `regional_anomalies.mat` | `lagged_correlation_results.csv` and `.mat` |

Zero-lag estimates compare raw, overall-mean, deseasonalized, and deseasonalized–detrended series. For lagged correlation, **lag +k = corr[SST(t), rainfall(t+k)]**; lag −k indicates rainfall leading SST. The primary test family has **39 tests** (3 regions × 13 lags from −6 to +6). Lag-1 autocorrelation is used to estimate an **effective sample size (`N_eff`)** and adjusted two-sided p-values. BH-FDR is applied across **all 39 tests**. A separate 21-test positive-lag analysis, if present in the CSV, is **secondary** and should not replace the primary 39-test result.

### Stage 04 — `04_Seasonal_Analysis`

| Run order / script | Required input | Principal output |
|---|---|---|
| `a_seasonal_mean_anomalies.m` | Stage 02 `regional_anomalies.mat` | `seasonal_mean_anomalies.csv` and `.mat` |
| `b_seasonal_correlation.m` | Stage 04 `seasonal_mean_anomalies.mat` | `seasonal_correlation_basic.csv` and `.mat` |
| `c_seasonal_robustness.m` | Stage 04 seasonal MAT/basic results | `seasonal_robustness_results.csv` and `.mat`; `seasonal_LOYO_results.csv` |
| `d_check_seasonal_annual_dependence.m` | Stage 04 `seasonal_mean_anomalies.mat` | `seasonal_annual_dependence_QC.csv` and `.mat`; `seasonal_adjacent_year_pairs.csv` |
| `e_compile_seasonal_uncertainty.m` | Stage 04 robustness and dependence QC CSVs | `seasonal_uncertainty_summary.csv` |

The primary uncertainty analysis uses **10,000 two-sided permutations**, approximate **95% Fisher-z confidence intervals**, and **leave-one-year-out (LOYO)** sensitivity. BH-FDR is applied to the **12 region–season** permutation p-values together. The annual-dependence check describes adjacent-season-year lag-1 correlations but **does not** itself correct the permutation test for interannual persistence.

### Stage 05 — `05_Spatial_Analysis`

| Run order / script | Required input | Principal output |
|---|---|---|
| `a_prepare_spatial_rainfall_anomalies.m` | Stage 01 CHIRPS cropped NetCDF, Stage 02 regional MAT | `spatial_rainfall_anomaly.mat`, `spatial_valid_grid_mask.csv`, `spatial_rainfall_grid_QC.csv`, `spatial_rainfall_monthly_QC.csv` |
| `b_spatial_correlation_fdr.m` | `spatial_rainfall_anomaly.mat`, Stage 02 `regional_anomalies.mat` | `spatial_correlation_results.mat`, `spatial_correlation_summary.csv`, `spatial_correlation_grid_results.csv` |

Calculate zero-lag correlations between **regional-mean SST deseasonalized anomalies** and **individual valid CHIRPS grid deseasonalized rainfall anomalies**. Significance uses lag-1-autocorrelation-adjusted `N_eff` and two BH-FDR frameworks:

- **Within-region BH-FDR (main H08 reference):** Flores **78/1,158** region-grid tests retained at qFDR < 0.05; Sumba **0/565**; Timor **0/1,088**.
- **Pooled BH-FDR (main H08 reference):** **0/2,811** region-grid tests retained at qFDR < 0.05.
- **Stage 09 H09 alternative:** the Flores within-region count increases to **110/1,158**, while pooled significance remains **0/2,811**. These H09 numbers must not be substituted for the H08 main-result numbers.

These cell counts describe multiple grid-level tests, **not independent spatial replicates** or a verified geographically extensive physical influence.

### Stage 06 — `06_Climate_Mode_Sensitivity`

| Run order / script | Required input | Principal output |
|---|---|---|
| `a_prepare_climate_indices.m` | `climate_indices_input_2016_2025.csv` (default snapshot) **or** the specified NOAA PSL annual text inputs | `climate_indices_2016_2025.mat`, `climate_indices_monthly.csv`, `climate_indices_seasonal.csv`, `climate_indices_QC.csv` |
| `b_seasonal_partial_correlation.m` | Stage 04 `seasonal_mean_anomalies.mat`, seasonal indices MAT/CSV | `seasonal_partial_correlation_results.csv` and `.mat`, `seasonal_partial_correlation_QC.csv` |
| `c_seasonal_partial_robustness.m` | Stage 06 partial-correlation MAT | `seasonal_partial_robustness_results.csv` and `.mat`; `seasonal_partial_LOYO_results.csv`, `seasonal_partial_permutation_QC.csv` |
| `d_check_partial_uncertainty_dependence.m` | Stage 06 partial MAT and robustness CSV | `partial_uncertainty_dependence_summary.csv`, `partial_residual_adjacent_year_pairs.csv` |

**Niño 3.4 and DMI are adjusted for separately**, never simultaneously in the reported partial correlations. Partial correlation is calculated by correlating residuals after separately regressing SST and rainfall on an intercept and one climate index. The climate-index series is already an index/anomaly product and is **not deseasonalized again**.

Conditional residual permutations use a **Freedman–Lane-style procedure** with **10,000 two-sided permutations**. BH-FDR is applied separately to **12 region–season tests for Niño 3.4** and **12 tests for DMI**. Post-adjustment correlations may remain numerically positive even when **no partial correlation meets qFDR < 0.05**. These analyses measure sensitivity to **shared linear covariability** and are **not** a causal attribution or a demonstration of independence from ENSO/IOD.

**Input provenance check:** The default `climate_indices_input_2016_2025.csv` is a fixed study snapshot. The exact underlying NOAA series/version, reference baseline, and source access date must be recorded or checked before claiming that a fresh NOAA download is numerically identical to the published snapshot.

### Stage 07 — `07_Robustness_Tests`

| Script | Required input | Principal output |
|---|---|---|
| `a_sst_domain_sensitivity.m` | Stage 01 cropped SST NetCDF; Stage 02/04 MAT | `sst_domain_sensitivity_JJA.csv` and `.mat` |
| `b_flores_north_south_sst.m` | Stage 01 cropped SST NetCDF; Stage 02/04 MAT | `flores_north_south_monthly.csv` and `.mat`; `flores_north_south_seasonal_correlations.csv` |
| `c_seasonal_detrend_missing2025.m` | Stage 04 seasonal MAT and robustness CSV | `seasonal_detrend_sensitivity.csv`, `seasonal_exclude2025_sensitivity.csv`, `JJA_rainfall_magnitude.csv` |
| `d_spatial_coarsegrid_sensitivity.m` | Stage 05/02 MAT | `spatial_coarse010_summary.csv`, `spatial_coarse010_grid_results.csv`, `spatial_coarse010_results.mat` |

The SST-domain test adjusts all four boundaries symmetrically by **−0.2°, −0.1°, 0°, +0.1°, and +0.2°**, leaving the rainfall study region unchanged. The Flores north–south partition is an **exploratory descriptive comparison** and does not test the statistical difference between correlations. Both analyses require the source-specific SST monthly NetCDFs (and their lineage should be reconciled as described in Section 3). Detrending is applied to **interannual seasonal series**, not directly to monthly observations. Excluding season-year 2025 is an independent sample-sensitivity check; **no new seasonal qFDR** is calculated for these modified series.

The spatial-resolution check aggregates **2 × 2 native 0.05° CHIRPS grid cells** within each region to approximately **0.10° blocks** (at least two valid source cells), and recomputes correlations, effective N and within-region/pooled BH-FDR. The main H08 reference produces **305/144/278** valid coarse cells (Flores/Sumba/Timor), **19** within-region FDR-retained cells in Flores, and **0/727** under pooled BH-FDR. This is a change in analysis resolution and family size, not proof that adjacent coarse cells are independent.

### Stage 08 — `08_Figures`

| Figure | Plotting script | Required source files | Output to retain in GitHub |
|---|---|---|---|
| **1. Study-period mean rainfall and SST** | `a_figure1_spatial_climatology.m` | Stage 01 cropped SST + rainfall NetCDF | `Figure_1_Spatial_Climatology.png`, `Figure_1_Spatial_Climatology_Data.mat`, `Figure_1_Monthly_Data_QC.csv` |
| **2. Study-period monthly means and deseasonalized anomalies** | `b_figure2_seasonal_patterns.m` | Stage 02 `regional_anomalies.mat` | `Figure_2_Seasonal_Patterns_Anomalies.png`, `Figure_2_Plot_Data.mat`, `Figure_2_Data_QC.csv` |
| **3. Lagged and seasonal correlation** | `c_figure3_lagged_seasonal_correlations.m` | Stage 03 `lagged_correlation_results.csv` and Stage 04 `seasonal_robustness_results.csv` | `Figure_3_Lagged_Seasonal_Correlations.png`, `Figure_3_Annotation_QC.csv` |
| **4. Spatial correlations** | `d_figure4_spatial_correlations.m` | Stage 05 `spatial_correlation_results.mat` and `spatial_correlation_summary.csv` | `Figure_4_Spatial_Correlations.png`, `Figure_4_Visual_QC.csv` |
| **5. Niño 3.4 / DMI partial-correlation heatmaps** | `e_figure5_partial_correlation_heatmaps.m` | Stage 06 `seasonal_partial_robustness_results.csv` | `Figure_5_Partial_Correlation_Heatmaps.png`, `Figure_5_Annotation_QC.csv` |

Figure 1 calculates the spatial **mean of 12 equally weighted study-period calendar-month means**; this avoids disproportionately weighting the months with ten SST observations relative to October–November, which have nine. Figure 3 and Figure 5 read statistical results calculated in earlier stages; the figure scripts **do not** rerun their statistical tests.

The MATLAB scripts may also export PDF figures and additional visualization QC/metadata files locally. The public repository may retain **PNG + CSV + required MAT** outputs without uploading redundant PDF copies. MAT files such as `Figure_1_Spatial_Climatology_Data.mat` and `Figure_2_Plot_Data.mat` are **outputs** of the plotting scripts; they do **not** replace the Stage 02 and Stage 05 MAT **inputs** required to rerun Figures 2 and 4.

### Stage 09 — `09_Transition_Sensitivity`

This stage **does not replace** the main 2016–2025 workflow. It compares the saved **`H08_Final` reference** with an **`H09_Alternative`** in which **only the six regional SST input values** (Flores, Sumba and Timor × October and November 2022) are replaced. All other SST months, CHIRPS rainfall and Niño 3.4/DMI indices are held constant. Changes are computed as `H09_Alternative − H08_Final`.

| Component | Role |
|---|---|
| `00_Original_Methods/` + `00_Original_Methods_SHA256.csv` | Frozen 20 method-script copies and a separate manifest of their SHA256 hashes; confirm both on the published release |
| `01_SST_H08_H09_Overlap_202210_202211/` | Four original full-disk SST NetCDFs, stored locally when redistribution is not permitted |
| `a_compare_h08_h09_overlap.m` → `02_Comparison_Outputs/` | Compares source means and, if grids are aligned, matched-pixel differences |
| `b_prepare_h09_scenario.m` → `03_Scenarios/` | Creates separate H08 and H09 regional inputs without overwriting main data |
| `run_H08_H09_clean.m` | Orchestrates the source comparison and eligible Stage 02–07 reruns for both scenarios |
| `z_compare_scenarios.m` → `04_Comparison/` | Compares corresponding outputs by scientific keys and summarizes changes, FDR families and seasonal conclusions |
| `05_Run_Logs/` | Logs available from the scenario executions; may contain local machine paths |

The provided comparison files report **218 metric summaries**, **24,450 changed downstream numeric records**, and **13 FDR-family comparison rows**. These are output differences, **not 24,450 replaced source observations**. The four main FDR-retained seasonal relationships (Flores/ Sumba/ Timor JJA; Timor SON) remain retained in both scenarios. The Flores within-region spatial result changes from **78** (H08) to **110** (H09) grid tests, and the coarse-grid counterpart from **19** to **31**; neither scenario has pooled-spatial FDR-retained results. These differences demonstrate sensitivity to product choice, **not** that one SST product is more accurate.

**Scope limitation:** Stage 09 does **not** rerun the source-specific cropped-NetCDF tests `07a` (SST domain changes) or `07b` (Flores north–south). The runner's `maxStage = 7` covers **eligible** Stage 07 methods `07c` and `07d`; do not report 07a/07b as cross-product validated. See [Stage 09's README](09_Transition_Sensitivity/README_09_Transition_Sensitivity.txt) and `04_Comparison/` for full numeric and decision-level details.

## 7. Random-number settings, statistical thresholds, and interpretation

| Item | Setting in the study scripts |
|---|---|
| Seasonal and partial-correlation random seed | MATLAB **`rng(2026,'twister')`** |
| Permutations | **10,000**, two-sided |
| Empirical permutation p | `p = (1 + number of permutations with |r*| >= |r_observed|) / (10000 + 1)` |
| Lagged BH-FDR family | **39** region–lag tests (primary) |
| Seasonal BH-FDR family | **12** region–season tests |
| Partial BH-FDR families | **12 Niño 3.4-controlled** and **12 DMI-controlled** tests, separately |
| Spatial BH-FDR families | Each region separately (**within-region**), plus all **2,811 region-grid tests** (**pooled**); 2,791 unique geographic positions |
| Primary significance criterion | **qFDR < 0.05** |
| Exploratory/suggestive category | **0.05 ≤ qFDR < 0.10**; *not statistically significant* at the primary threshold |
| Seasonal sample sizes | DJF/SON **n = 9**; MAM/JJA **n = 10** |
| Seasonal uncertainty | Approximate Fisher-z **95% confidence intervals**; LOYO |

The approximate Fisher-z intervals are not simultaneous, FDR-adjusted intervals and do not account fully for possible interannual dependence. Unrestricted permutations of seasonal observations/residuals also do not preserve potential interannual ENSO/IOD persistence. The adjacent-year lag-1 analyses are **diagnostic only** and cannot establish independence or exchangeability from such small samples. Spatial BH-FDR does not transform neighboring grid cells into independent observations.

## 8. How to reproduce the work

### Option A — Full workflow from downloaded original data

1. Download the products described in **Section 3**, respecting each provider's access terms. Preserve the source filenames/versions used in the scripts.
2. Create the **local-only** `00_Raw_Data` arrangement in Section 3.1. Run `01_crop_himawari_sst_ntt.gs` with `01_Crop_SST_NTT` as the GrADS working directory, and `02_crop_chirps_v3_ntt.gs` with `02_Crop_CHIRPS_NTT` as its working directory. Verify that the local cropped NetCDFs have the expected names and dimensions.
3. Run Stage 02 scripts `a_...` followed by `b_...` to create the regional MAT/CSV intermediates. Confirm that SST has 118 available months, rainfall 120, and missing SST months remain NaN.
4. Run Stage 03 scripts `a_...`, `b_...`, `c_...` in order.
5. Run Stage 04 scripts `a_...` through `e_...` in order.
6. Run Stage 05 scripts `a_...`, `b_...` in order.
7. Supply the **documented climate-index snapshot** and run Stage 06 scripts `a_...` through `d_...` in order.
8. Run all four Stage 07 sensitivity checks (subject to cropped NetCDF availability and source lineage), then the five Stage 08 figure scripts.
9. For the **separate Stage 09 experiment**, verify `00_Original_Methods/` against its SHA256 manifest, provide the four original overlap SST files locally, and run `run_H08_H09_clean.m`. Keep its scenario outputs separate from the main pipeline. Do not infer that 07a/07b were checked by this runner.
10. Compare the regenerated CSV/PNG outputs with the retained repository outputs, using the validation targets in Section 9. **First resolve the October–November 2022 source-selection discrepancy if reproducing from raw SST files.**

### Option B — Reproduce downstream analyses from archived MAT/CSV files

If the exact required intermediate MAT/CSV inputs are included in the selected release, run the corresponding later-stage scripts without repeating the raw-data cropping. For example:

- Stage 03 and Stage 04 can start from Stage 02 `regional_anomalies.mat`.
- Stage 06 can start from Stage 04 `seasonal_mean_anomalies.mat` plus the fixed climate-index input snapshot.
- Figure 2 can start from Stage 02 `regional_anomalies.mat`.
- Figure 3 can start from Stage 03/04 result CSVs.
- Figure 4 needs Stage 05 `spatial_correlation_results.mat` **and** `spatial_correlation_summary.csv`.
- Figure 5 can start from Stage 06 `seasonal_partial_robustness_results.csv`.

**Exceptions:** Figure 1, Stage 02 regional extraction, and Stage 07 scripts a/b require original/cropped **SST NetCDF** files; Stage 05 preparation requires cropped CHIRPS NetCDFs. Stage 09's source comparison additionally requires **four** H08/H09 full-disk monthly SST NetCDF inputs. The fixed Stage 02 MAT/CSV files enable downstream reproducibility, but **the currently supplied Stage 01 crop source-selection rule must be reconciled before claiming end-to-end reproduction of the saved H08 reference**.

### MATLAB and plotting dependencies

- **GrADS 2.2.1** for cropping.
- **MATLAB R2021a** and **Statistics and Machine Learning Toolbox** for the relevant statistical functions.
- **M_Map** for spatial mapping and high-resolution GSHHS coastlines: https://www.eoas.ubc.ca/~rich/map.html
- **cmocean for MATLAB** for optional figure colormaps: https://github.com/chadagreene/cmocean

Third-party MATLAB functions (including the large M_Map function collection) are **not redistributed** here. In the original local environment, the functions were made available in the working directory or MATLAB search path. Users may retain the original working-directory approach without editing the research scripts, or install the dependencies separately and add their directories using `addpath`. Figure scripts will check whether required mapping functions such as `m_proj`, `m_pcolor`, and `m_gshhs_h` are available. Exact M_Map/GSHHS installation versions should be documented in the release if known.

## 9. Verification targets and manuscript-to-output traceability

The main-study verification targets below refer to the **deposited H08-reference outputs**, not the H09 transition alternative. Use the actual CSV/MAT files as the source of numerical values. Counts and FDR decisions are sensitive to the **chosen family of tests**.

| Manuscript result | Authoritative output | Main H08-reference check |
|---|---|---|
| Availability | Stage 02 `regional_data_availability.csv`, Figures 1/2 QC | SST **118/120**; CHIRPS **120/120**; SST Oct–Nov 2025 missing |
| Zero-lag raw (n=118) | Stage 03 `monthly_zero_lag_correlation.csv` | Flores **0.5680**; Sumba **0.7179**; Timor **0.7163** |
| Zero-lag deseasonalized (n=118) | Same Stage 03 CSV, `Series=Deseasonalized` | Flores **0.0756**; Sumba **0.0392**; Timor **0.1224** |
| Lagged analysis (primary family) | Stage 03 `lagged_correlation_results.csv`, Figure 3 QC | **39** region–lag tests; **0** at qFDR < 0.05 and **0** at qFDR < 0.10 (H08) |
| Seasonal JJA | Stage 04 `seasonal_robustness_results.csv` | Flores **r=0.8569, q=0.0156**; Sumba **r=0.8382, q=0.0188**; Timor **r=0.7917, q=0.0188** |
| Seasonal Timor SON | Same Stage 04 CSV | **r=0.8149, q=0.0219** |
| Seasonal other | Same Stage 04 CSV | **Flores DJF:** r=−0.7115, q=0.0631, *suggestive only*; **Flores SON:** r=0.6284, q=0.1334, *not retained* |
| Spatial valid grids and FDR | Stage 05 `spatial_correlation_summary.csv`, grid results | **1,158/565/1,088** region-grid tests; Flores **78** retained within region; **0/2,811** pooled |
| Climate-mode adjustment | Stage 06 `seasonal_partial_robustness_results.csv` | **0/12** retained for Niño 3.4 and **0/12** for DMI; Flores and Timor JJA Niño-adjusted q≈0.084 are *suggestive only* |
| Domain/period sensitivity | Stage 07 `sst_domain_sensitivity_JJA.csv`, detrend and exclusion CSVs | JJA coefficients remain positive for all three regions; these are descriptive checks, not newly FDR-adjusted tests |
| Coarse spatial grid | Stage 07 `spatial_coarse010_summary.csv` | **305/144/278** coarse region-grid tests; Flores **19** retained within region; **0/727** pooled |
| Figures 1–5 | Stage 08 final PNGs and corresponding figure QC CSVs | Numerical annotations and significance labels agree with Stages 02–06 |
| H08/H09 source-transition alternative | Stage 09 `04_Comparison/03_FDR_Family_Comparison.csv` and `04_Seasonal_Conclusions.csv` | Four main significant season–region results retained in both; Flores spatial **78 → 110** and coarse **19 → 31** for H08 → H09; pooled significance remains 0 |

**Important:** The previously documented values **0.091/0.052/0.135** (deseasonalized r), **0.0141** (JJA q), **0.855** (Timor SON r), **110** (Flores native cells), and **31** (Flores coarse cells) must **not** be listed as the current H08-reference results. Some of those values correspond to the H09 sensitivity branch. If a regenerated result differs, check the source-selection date, input MAT/CSV version, calendar-month missingness, MATLAB RNG and statistical test family before editing the manuscript or figure annotations.

## 10. Availability, archived release, and citation

- **Repository:** https://github.com/triayulestari/sst-rainfall-ntt
- **Releases:** https://github.com/triayulestari/sst-rainfall-ntt/releases
- **Earlier tagged release (if still available):** [`v1.1.0`](https://github.com/triayulestari/sst-rainfall-ntt/releases/tag/v1.1.0). This tag was cited in the older eight-stage README and should **not** automatically be treated as the complete nine-stage revision.
- **Final reproducibility citation:** After correcting the Stage 01 source-lineage discrepancy and synchronizing the intended files, create and verify **a new immutable release/tag**, and use that exact version in both the manuscript and Supplementary Materials. A push to `main` **does not update** a previously created release; do not claim that an old tag contains the new Stage 09 material without checking it.
- **Paper status:** Accompanying journal manuscript under revision. Add the final article DOI and archived repository citation upon publication.

The public repository should clearly distinguish data supplied in the archive from files generated locally after downloading provider data. Inspect large MAT files, source-data redistribution terms, logs containing local file paths and GitHub's file-size limits before pushing. Reuse of source products is subject to provider access and redistribution terms. Script/code reuse conditions should be specified by an explicit repository license if the authors choose to provide one; third-party packages retain their own licenses.

For questions about source-data access, the original MATLAB/GrADS environment, execution paths, or reproducing numerical results, contact the **corresponding author through the manuscript's contact details**.
