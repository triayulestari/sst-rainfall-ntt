# Seasonal and Spatial SST–Rainfall Relationships across Flores, Sumba, and Timor (2016–2025)

**Reproducibility package for the manuscript:**  
*Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor*

**Repository:** https://github.com/triayulestari/sst-rainfall-ntt  
**Study period:** January 2016–December 2025  
**Study regions:** Flores, Sumba, and Timor, East Nusa Tenggara (NTT), Indonesia  
**Software:** GrADS 2.2.1 and MATLAB R2021a

## 1. Purpose and scope

This repository documents the workflow used to prepare satellite-derived marine sea surface temperature (SST) and land rainfall data, calculate temporal and spatial SST–rainfall associations, assess statistical uncertainty and sensitivity, and produce Figures 1–5 of the accompanying manuscript.

It contains research scripts (`.gs` and `.m`), selected intermediate MATLAB arrays (`.mat`), readable numerical and quality-control outputs (`.csv`), final manuscript figures (`.png`), and stage-specific documentation. **Original and cropped SST/rainfall NetCDF files are not redistributed.** Consequently, reproducing analyses from the original satellite observations requires downloading the source data, whereas many later analyses can be reproduced from the supplied intermediate MAT/CSV files.

The reported findings concern statistical associations during the **2016–2025 observational period**. They do not establish causality, climate-mode independence, rainfall-forecasting skill, or long-term climatic relationships.

## 2. Repository structure and execution order

Keep the eight numbered directories **together under one common parent directory**, preserving their names and subdirectories. The MATLAB scripts locate data using paths relative to their own saved locations. The parent can be the repository root or a local directory called `Data`.

```text
sst-rainfall-ntt/
├── README.md                         <- this overview
├── 01_SST_Rainfall_NTT_2016_2025/
│   ├── README.txt
│   ├── 01_Crop_SST_NTT/
│   │   └── 01_crop_himawari_sst_ntt.gs
│   └── 02_Crop_CHIRPS_NTT/
│       └── 02_crop_chirps_v3_ntt.gs
├── 02_Regional_Timeseries/           <- regional mean / anomaly inputs for later stages
├── 03_Monthly_and_Lagged/            <- concurrent and lagged statistics
├── 04_Seasonal_Analysis/             <- seasonal statistics and uncertainty
├── 05_Spatial_Analysis/              <- grid-level correlations and FDR
├── 06_Climate_Mode_Sensitivity/      <- Niño 3.4 / DMI partial correlations
├── 07_Robustness_Tests/              <- domain, trend, period, resolution tests
└── 08_Figures/                      <- Figure 1–5 scripts, PNG, QC outputs
```

Each numbered directory has its own `README.txt` with detailed stage-specific instructions. The figure-generating scripts are collected in `08_Figures` rather than interleaved with the statistical calculations.

**Analysis dependencies** (run in this order):

```text
Raw Himawari SST + CHIRPS v3.0 monthly rainfall (obtained from providers)
               |
               v
01  GrADS cropping: monthly SST / yearly CHIRPS NetCDF
               |
               v
02  Regional mean -> study-period monthly means -> deseasonalized anomalies
               |
       +-------+--------------+------------------+
       |                      |                  |
       v                      v                  v
03  Monthly / lagged     04  Seasonal         05  Spatial
    correlations             associations          grid associations
                               |                       |
                               v                       |
                        06  Climate-mode              |
                            partial correlations      |
                               |                       |
                               +-----------+-----------+
                                           v
                                  07  Sensitivity checks

08  Figures 1–5: reads NetCDF or output MAT/CSV from stages 01–06
```

Stage 05 also reads the Stage 02 regional SST anomaly series; Stage 06 reads Stage 04 seasonal data. Stage 07 reads inputs from Stages 01, 02, 04, and 05. Thus, this diagram is a **dependency map**, not an instruction to move files or recalculate analyses unnecessarily.

## 3. Original data products and provenance

| Variable | Product and version used | Resolution | Study availability | Provider |
|---|---|---|---|---|
| Marine SST | **Himawari-8 Level-3 SST, product v2.0** (January 2016–September 2022); **Himawari-9 Level-3 SST, product v2.1** (October 2022 onward in the study archive) | Monthly, nominal **0.02° × 0.02°** | **118/120** months; October–November 2025 missing | [JAXA Himawari Monitor/P-Tree](https://www.eorc.jaxa.jp/ptree/registration_top.html) |
| Land rainfall | **CHIRPS version 3.0**, monthly | **0.05° × 0.05°** | **120/120** months | [Climate Hazards Center, UCSB](https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/global/netcdf/by_year/) |
| ENSO indicator | Monthly **Niño 3.4 SST anomaly** index; documented input snapshot | Monthly | Analysis period 2016–2025 | [NOAA PSL Niño 3.4](https://psl.noaa.gov/data/timeseries/month/Nino34/) |
| IOD indicator | Monthly **Dipole Mode Index (DMI)**; documented input snapshot | Monthly | Analysis period 2016–2025 | [NOAA PSL DMI](https://psl.noaa.gov/data/timeseries/month/DMI/) |

The SST time series uses the **product availability in this research archive**; the October 2022 product boundary should not be interpreted as the official operational satellite handover date. The transition combines different satellite sensors and processing-product versions. Their cross-product continuity was **not independently validated** in this study.

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

**Important GrADS execution detail:** The `.gs` scripts use relative `../00_Raw_Data/...` paths and write NetCDF output to the **current GrADS working directory**. Run each `.gs` with its respective crop subfolder as the working directory (or configure the working directory accordingly). The original script-header text referring to earlier directory names does not override the relative paths actually used in the code. No analysis-script modifications are necessary when this local directory arrangement is preserved.

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
- The fixed spatial selection comprises **1,158 Flores**, **565 Sumba**, and **1,088 Timor** grid cells (**2,811 total**). Neighboring cells are spatially dependent and must **not** be treated as independent replicated evidence.

For the spatial results, `within-region BH-FDR` is applied separately within each island's valid cells. `Pooled BH-FDR across the three study regions` jointly adjusts all 2,811 grid tests. These are distinct multiple-testing families, **not** alternative spatial masks.

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

- **Within-region BH-FDR:** Flores **110/1,158** cells significant at qFDR < 0.05; Sumba **0/565**; Timor **0/1,088**.
- **Pooled BH-FDR across the three study regions:** **0/2,811** cells significant at qFDR < 0.05.

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
| `a_sst_domain_sensitivity.m` | Stage 01 SST NetCDF, Stages 02/04 MAT | `sst_domain_sensitivity_JJA.csv` and `.mat` |
| `b_seasonal_detrend_missing2025.m` | Stage 04 seasonal MAT and robustness CSV | `seasonal_detrend_sensitivity.csv`, `seasonal_exclude2025_sensitivity.csv`, `JJA_rainfall_magnitude.csv` |
| `c_spatial_coarsegrid_sensitivity.m` | Stages 05/02 MAT | `spatial_coarse010_summary.csv`, `spatial_coarse010_grid_results.csv`, `spatial_coarse010_results.mat` |

The domain test changes SST-box boundaries symmetrically by **−0.2°, −0.1°, 0°, +0.1°, and +0.2°**, leaving the rainfall study regions unchanged. Detrending and exclusion of 2025 check sensitivity to processing and study-period choice, **without recalculating qFDR**. The CHIRPS coarse-grid test combines **2 × 2 native 0.05° cells** into approximately **0.10° cells**, retaining coarse blocks with at least **two valid land cells** and recomputing the spatial correlations/FDR. Coarsening **does not eliminate** spatial dependence. The exploratory Flores north–south subdomain comparison is not part of the final manuscript's reported analyses and is therefore excluded from this final Stage 07 workflow.

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

## 7. Random-number settings, statistical thresholds, and interpretation

| Item | Setting in the study scripts |
|---|---|
| Seasonal and partial-correlation random seed | MATLAB **`rng(2026,'twister')`** |
| Permutations | **10,000**, two-sided |
| Empirical permutation p | `p = (1 + number of permutations with |r*| >= |r_observed|) / (10000 + 1)` |
| Lagged BH-FDR family | **39** region–lag tests (primary) |
| Seasonal BH-FDR family | **12** region–season tests |
| Partial BH-FDR families | **12 Niño 3.4-controlled** and **12 DMI-controlled** tests, separately |
| Spatial BH-FDR families | Each study region separately (**within-region**), plus all **2,811 cells together** (**pooled**) |
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
8. Run the Stage 07 sensitivity checks (their order is as listed in the folder README). Then run the five Stage 08 figure scripts.
9. Compare the regenerated CSV and PNG outputs with the retained repository outputs, checking the validation targets in Section 9.

### Option B — Reproduce downstream analyses from archived MAT/CSV files

If the exact required intermediate MAT/CSV inputs are included in the selected release, run the corresponding later-stage scripts without repeating the raw-data cropping. For example:

- Stage 03 and Stage 04 can start from Stage 02 `regional_anomalies.mat`.
- Stage 06 can start from Stage 04 `seasonal_mean_anomalies.mat` plus the fixed climate-index input snapshot.
- Figure 2 can start from Stage 02 `regional_anomalies.mat`.
- Figure 3 can start from Stage 03/04 result CSVs.
- Figure 4 needs Stage 05 `spatial_correlation_results.mat` **and** `spatial_correlation_summary.csv`.
- Figure 5 can start from Stage 06 `seasonal_partial_robustness_results.csv`.

**Exceptions:** Figure 1, Stage 02 regional extraction, and some Stage 07 SST-domain analyses still require the original/cropped **NetCDF** files. Stage 05 preparation also requires the cropped CHIRPS NetCDF data. Publishing MAT and CSV outputs enables partial reproducibility and result verification, **not** a claim that all raw-data processing is executable without source files.

### MATLAB and plotting dependencies

- **GrADS 2.2.1** for cropping.
- **MATLAB R2021a** and **Statistics and Machine Learning Toolbox** for the relevant statistical functions.
- **M_Map** for spatial mapping and high-resolution GSHHS coastlines: https://www.eoas.ubc.ca/~rich/map.html
- **cmocean for MATLAB** for optional figure colormaps: https://github.com/chadagreene/cmocean

Third-party MATLAB functions (including the large M_Map function collection) are **not redistributed** here. In the original local environment, the functions were made available in the working directory or MATLAB search path. Users may retain the original working-directory approach without editing the research scripts, or install the dependencies separately and add their directories using `addpath`. Figure scripts will check whether required mapping functions such as `m_proj`, `m_pcolor`, and `m_gshhs_h` are available. Exact M_Map/GSHHS installation versions should be documented in the release if known.

## 9. Verification targets and manuscript-to-output traceability

The following values provide **consistency checks** against the final analytical workflow; they are not substitute input data, manually imposed calculations, or proof of full reproducibility.

| Manuscript item | Verification output | Expected check |
|---|---|---|
| Monthly sample availability | Stage 02 `regional_data_availability.csv`, Figure 1/2 QC CSVs | SST **118/120**, rainfall **120/120**; SST October–November 2025 missing |
| Weak deseasonalized zero-lag correlations | Stage 03 `monthly_zero_lag_correlation.csv` | Flores **r ≈ 0.091**, Sumba **≈ 0.052**, Timor **≈ 0.135** |
| Primary lagged analysis | Stage 03 `lagged_correlation_results.csv`, Figure 3 QC CSV | **39** tests; **no qFDR < 0.05** |
| Seasonal JJA | Stage 04 `seasonal_robustness_results.csv` and `seasonal_uncertainty_summary.csv` | Flores **r ≈ 0.857**, Sumba **≈ 0.838**, Timor **≈ 0.792**; **qFDR ≈ 0.0141** |
| Seasonal SON | Stage 04 seasonal CSV | Timor **r ≈ 0.855**, **qFDR ≈ 0.0141** |
| Spatial correlation | Stage 05 `spatial_correlation_summary.csv` and `spatial_correlation_grid_results.csv` | **110/1,158** within-region significant cells in Flores; **0/2,811** pooled |
| Climate-mode sensitivity | Stage 06 `seasonal_partial_robustness_results.csv` and `partial_uncertainty_dependence_summary.csv` | **0/12** partial correlations significant for Niño 3.4; **0/12** for DMI after BH-FDR |
| Dry-season rainfall magnitude | Stage 07 `JJA_rainfall_magnitude.csv` | Descriptive rainfall magnitudes in **mm month⁻¹**; not inferred from `r` alone |
| Spatial-resolution sensitivity | Stage 07 `spatial_coarse010_summary.csv` | Broadly similar descriptive pattern; **no pooled-significant cells** |
| Main graphics | Stage 08 PNG files and figure QC CSVs | Figures 1–5 agree with source outputs and displayed FDR annotations |

**Figures and statistical calculations should agree with the CSV/MAT outputs, not with values retyped into README tables.** If checks fail, inspect source versions, MATLAB environment, input paths, missing-value handling, and whether all files belong to the same tagged repository snapshot.

## 10. Availability, archived release, and citation

- **Repository:** https://github.com/triayulestari/sst-rainfall-ntt
- **Releases:** https://github.com/triayulestari/sst-rainfall-ntt/releases
- **Maintainer-reported fixed release:** `v1.0`. **Before citing it as the exact reproducibility package**, confirm that its tag contains the final eight-folder structure, final scripts, necessary MAT/CSV outputs, and this README. If these were added *after* `v1.0` was created, publish a **new fixed release** and cite that version instead of implying that `v1.0` contains later modifications.
- **Paper status:** Accompanying journal manuscript under revision. Add the final article DOI and archived repository citation upon publication.

The published repository should clearly distinguish data supplied in the archive from files generated locally after downloading provider data. Reuse of source products is subject to provider access and redistribution terms. Script/code reuse conditions should be specified by an explicit repository license if the authors choose to provide one; third-party packages retain their own licenses.

For questions about source-data access, the original MATLAB/GrADS environment, execution paths, or reproducing numerical results, contact the **corresponding author through the manuscript's contact details**.
