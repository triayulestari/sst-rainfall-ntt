# 09 — Himawari-8/Himawari-9 SST Source-Transition Sensitivity

## 1. Purpose and scope

This folder documents a controlled sensitivity experiment for the article **“Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor.”** It assesses whether replacing the regional monthly sea surface temperature (SST) inputs for **October and November 2022** changes the statistical results reported for Flores, Sumba, and Timor.

Two scenarios are compared:

- **`H08_Final` (reference):** the original study's processed regional SST series and associated outputs.
- **`H09_Alternative` (sensitivity scenario):** the same series and procedures, except that **six regional SST observations** (three regions × two months) are replaced with values derived from the Himawari-9 product.

The difference convention is **`H09_Alternative − H08_Final`** throughout the comparison files. All other monthly SST inputs, CHIRPS rainfall observations, and Niño 3.4/DMI input values are unchanged between scenarios. The October–November **2025 SST data gaps remain missing** in both scenarios; they are not filled or interpolated. Each scenario contains 120 calendar positions (January 2016–December 2025), with 118 available regional SST months and 120 rainfall months.

**Confirmed source selection for the primary analysis:** Himawari-8 L3 SST v2.0 is used from January 2016 through **November 2022**, followed by Himawari-9 L3 SST v2.1 from **December 2022** onward. The tested October–November 2022 H09 data are an alternative, not the primary inputs. The current Stage 01 GrADS cropping script implements this rule.

**This is a source/product-transition sensitivity test, not an independent validation of SST accuracy.** The satellite platform and processing-product version change together (Himawari-8 SST v2.00 versus Himawari-9 SST v2.01), so their separate effects cannot be isolated using this experiment.

The folder also contains an **independent Stage 01 source-lineage verification** (`check_H08_H09_source_lineage.m`) that compares the existing October–November 2022 cropped SST to the saved H08/H09 regional source-reference means and cell counts. Its successful result is deposited as `04_Comparison/06_Crop_Source_Lineage_QC.csv`.

## 2. Folder layout and required components

The following is the layout expected by the supplied pipeline scripts. The `00_Original_Methods/` directory is **required for a clean rerun** and must be present locally, even if a public deposit omits large source NetCDF files.

```text
09_Transition_Sensitivity/
├── README_09_Transition_Sensitivity.txt           # This document (Markdown-formatted TXT)
├── 00_Original_Methods_SHA256.csv
├── 00_Original_Methods/                       # REQUIRED FOR RERUN: 20 frozen .m scripts
│   ├── 02_Regional_Timeseries/
│   ├── 03_Monthly_and_Lagged/
│   ├── 04_Seasonal_Analysis/
│   ├── 05_Spatial_Analysis/
│   ├── 06_Climate_Mode_Sensitivity/
│   └── 07_Robustness_Tests/
├── 01_SST_H08_H09_Overlap_202210_202211/      # Four original monthly NetCDF inputs
├── 02_Comparison_Outputs/
│   ├── H08_H09_overlap_comparison.png
│   ├── H08_H09_overlap_methods.txt
│   ├── H08_H09_overlap_regional_comparison.csv
│   └── H08_H09_overlap_source_inventory.csv
├── 03_Scenarios/
│   ├── H08_Final/
│   │   ├── 02_Regional_Timeseries/
│   │   ├── 03_Monthly_and_Lagged/
│   │   ├── 04_Seasonal_Analysis/
│   │   ├── 05_Spatial_Analysis/
│   │   ├── 06_Climate_Mode_Sensitivity/
│   │   └── 07_Robustness_Tests/
│   └── H09_Alternative/                       # Same stage subdirectories
├── 04_Comparison/
│   ├── 00_Run_Status.csv
│   ├── 01_Metric_Delta_Summary.csv
│   ├── 02_Metric_Delta_Detail_Changed_Only.csv
│   ├── 03_FDR_Family_Comparison.csv
│   ├── 04_Seasonal_Conclusions.csv
│   ├── 05_Methods_and_Interpretation.txt
│   └── 06_Crop_Source_Lineage_QC.csv             # NEW: independent regional crop-lineage QC
├── 05_Run_Logs/
│   └── run_YYYYMMDD_HHMMSS.txt
├── a_compare_h08_h09_overlap.m
├── b_prepare_h09_scenario.m
├── check_H08_H09_source_lineage.m              # NEW: execute separately from runner
├── run_H08_H09_clean.m
└── z_compare_scenarios.m
```

The researcher has subsequently added `00_Original_Methods/` to the local Folder 09, as shown in the updated folder screenshot. For a clean rerun, its 20 expected `.m` files must also be present at their original relative locations and should be checked against `00_Original_Methods_SHA256.csv`; the directory listing alone is not a hash verification. The SHA256 manifest **does not contain executable source code** and cannot replace the scripts. The historical `README_MULAI_DARI_NOL.md` contains obsolete reset instructions and should not be used as the public-facing README.

## 3. Input provenance and overlap comparison

**Original SST source comparison** (`a_compare_h08_h09_overlap.m`):

1. Reads one Himawari-8 and one Himawari-9 monthly SST NetCDF for each of October and November 2022 (four inputs total).
2. Checks the source file names, products, SST and geolocation variables, original units, raster size and file inventory.
3. Computes mean SST independently for each product in the baseline SST rectangles for Flores, Sumba and Timor, plus the broader NTT study domain.
4. Evaluates **paired-pixel differences** only when H08 and H09 coordinates are co-located within the specified tolerance and both SST values are valid.
5. Writes the four files under `02_Comparison_Outputs/` shown above.

**Do not confuse** the difference between independently calculated regional means with the average of paired H09–H08 pixel differences. Different valid-pixel coverage can make these quantities unequal. The regional mean differences are the values used to form the alternative scenario.

**Provenance limitation:** The original four H08/H09 full-disk NetCDF inputs and their full pixelwise comparison were not independently reread during this documentation update. However, the newly supplied `06_Crop_Source_Lineage_QC.csv` records a successful read-only MATLAB check of the researcher's **current cropped NetCDF files** against the saved Stage 02 baseline and H08/H09 overlap regional summaries (see Section 4.1). Retain original source metadata and checksums where permitted. Agreement in regional means and valid-pixel counts is not proof of pixel-by-pixel file identity or absolute accuracy.

## 4. Scenario construction and reproducible execution

`b_prepare_h09_scenario.m` takes the study's existing Stage 02 regional SST/rainfall data as its baseline, reads `02_Comparison_Outputs/H08_H09_overlap_regional_comparison.csv`, verifies alignment against the H08 means and valid-pixel counts, and substitutes only the six October–November 2022 SST regional values. The original study files are read-only; scenario outputs are saved separately in `03_Scenarios/`.

`run_H08_H09_clean.m` orchestrates both scenarios. It uses frozen copies of the original computational methods from `00_Original_Methods/`, preserves the relevant input data and parameters, and calls `z_compare_scenarios.m` after calculations. To rerun on the original local project layout:

```matlab
cd('path/to/Data/09_Transition_Sensitivity')
run_H08_H09_clean
```

The default script setting is `maxStage = 7`. This means **all eligible components up to Stage 07**, not every original Stage 07 analysis. In particular:

| Stage | Scenario operation | Comparison status in provided `00_Run_Status.csv` |
|---|---|---|
| 02 | Recompute regional calendar means, anomalies and detrending | Complete and compared |
| 03 | Recompute zero-lag, lagged and effective-N statistics | Complete and compared |
| 04 | Recompute seasonal correlations, permutation tests, confidence intervals, LOYO and annual-dependence diagnostics | Complete and compared |
| 05 | Recompute spatial grid correlations/FDR, using the same CHIRPS grid-anomaly input | Complete and compared |
| 06 | Recompute partial correlations/FDR, using the same climate-index input snapshot | Complete and compared |
| 07c | Recompute seasonal detrending, 2025 exclusion and JJA rainfall magnitude summaries | Completed under eligible Stage 07 procedures |
| 07d | Recompute coarse-grid spatial sensitivity | Completed under eligible Stage 07 procedures |
| 07a, 07b | SST domain-boundary and Flores north–south tests | **Not tested** under the H08/H09 scenario switch; these require scenario-specific SST NetCDF crops |

### 4.1 Independent check of Stage 01 cropped SST lineage (new)

A separate **read-only verification** script, `check_H08_H09_source_lineage.m`, was added after the H08/H09 scenario comparison. It is **not** called automatically by `run_H08_H09_clean.m` or `z_compare_scenarios.m`, and it does **not** alter Stage 01–08 data, scenarios, or statistical results.

**Required inputs:**

- `../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_202210.nc`
- `../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_202211.nc`
- `../02_Regional_Timeseries/regional_timeseries_raw.csv`
- `../02_Regional_Timeseries/regional_grid_check.csv`
- `02_Comparison_Outputs/H08_H09_overlap_regional_comparison.csv`

Save the new script at the root of `09_Transition_Sensitivity/` (beside `run_H08_H09_clean.m`), then run it in MATLAB R2021a or later:

```matlab
cd('path/to/Data/09_Transition_Sensitivity')
check_H08_H09_source_lineage
```

This script reads the two cropped SST NetCDFs in °C, re-extracts finite SST values for the three **same geographic SST rectangles** used in Stage 02, and compares regional means and valid-cell counts against the saved Stage 02 and overlap-reference tables. It requires a common time axis of 120 months in the saved Stage 02 tables and applies a **mean-value tolerance of 1e-5 °C**; matching the H08 reference also requires matching the number of valid SST cells. The script labels each of six region–month checks with its match category and writes:

`04_Comparison/06_Crop_Source_Lineage_QC.csv`

The run is independent of `maxStage`; it does **not** replace the H08/H09 scenario comparison and does **not** regenerate the four original source-overlap NetCDF inputs. If the cropped NetCDF files are not available in the correct local directory, the resulting QC cannot establish cropping lineage. A fresh check should be rerun after any change to the Stage 01 crop files or Stage 02 reference data.

**Expected output from the documented successful run:** six `CROP_MATCHES_H08_BASELINE` findings, six true `Stage02_matches_H08`, six true `Stage02_count_matches_H08`, six true `Crop_matches_H08`, and no true `Crop_matches_H09` records. See Section 6.1 for the observed values and their interpretation.

The stage labels `07a`–`07d` refer to the frozen methods' file names. The runner will **skip apparently complete output sets** and **stop on partial output sets**, so do not mix a fresh execution with pre-existing scenario results. Preserve earlier outputs in an archive outside the active run before starting a genuinely fresh run. The script does not delete source files.

The file `00_Original_Methods_SHA256.csv` lists SHA256 digests for 20 frozen methods. These digests can be checked against the actual `.m` files before and after running. **The supplied pipeline does not itself enforce the SHA256 manifest**; a separate hash comparison is needed. During the current audit, all 20 digests matched the 20 corresponding previously uploaded stage scripts, but the contents of the newly added `00_Original_Methods/` directory and full run logs were not supplied for direct inspection.

## 5. Comparison outputs and audit trail

`z_compare_scenarios.m` aligns paired CSV outputs by explicit scientific keys (time, region, season, year, lag or grid coordinates as appropriate) rather than assuming identical row ordering. Numeric changes greater than `1e-12` are enumerated. The **six core comparison files** and the **additional Stage 01 source-lineage QC file** have the following roles:

| File | Content |
|---|---|
| `00_Run_Status.csv` | Completed stages and explicit Stage 07 exclusions |
| `01_Metric_Delta_Summary.csv` | Number and size of changes per numeric variable and source file |
| `02_Metric_Delta_Detail_Changed_Only.csv` | One row per changed numeric value, with original, alternative and signed delta |
| `03_FDR_Family_Comparison.csv` | Significance and exploratory-threshold counts for each FDR test family |
| `04_Seasonal_Conclusions.csv` | H08/H09 seasonal r, permutation p, FDR q and resulting category per region–season |
| `05_Methods_and_Interpretation.txt` | Comparison conventions, scope, warnings and limits |
| `06_Crop_Source_Lineage_QC.csv` | New read-only QC: current Stage 01 cropped NetCDF versus Stage 02 and H08/H09 regional means and valid-pixel counts |

In the supplied final comparison files, `maxStage = 7`, with **218 numeric metric summaries**, **24,450 changed numeric records** and **13 FDR-family rows**. These 24,450 records include changes in downstream, gridded metrics and **do not mean that 24,450 source SST observations were replaced**. Exactly six regional SST input observations were substituted.

## 6. Observed source-scenario differences

### 6.1 Stage 01 cropped-source lineage QC: PASS (new)

The researcher executed `check_H08_H09_source_lineage.m` on the existing local cropped NetCDF data and supplied the resulting `06_Crop_Source_Lineage_QC.csv`. Six records were checked (October and November 2022 × Flores, Sumba and Timor):

| QC criterion | Passed records |
|---|---:|
| Stage 02 SST mean matches H08 overlap reference | **6/6** |
| Stage 02 valid SST cell count matches H08 reference | **6/6** |
| Cropped NetCDF available and read for the region–month | **6/6** |
| Cropped SST regional mean **and** valid cell count match H08 | **6/6** |
| Cropped SST matches H09 reference | **0/6** |
| Final category `CROP_MATCHES_H08_BASELINE` | **6/6** |

| Month | Region | Cropped SST = Stage 02 baseline (°C) | H09 alternative mean (°C) | Cropped source finding |
|---|---|---:|---:|---|
| 2022-10 | Flores | 29.505104 | 29.842250 | H08 baseline |
| 2022-10 | Sumba | 29.077204 | 29.375380 | H08 baseline |
| 2022-10 | Timor | 29.546929 | 29.851104 | H08 baseline |
| 2022-11 | Flores | 29.916978 | 30.292072 | H08 baseline |
| 2022-11 | Sumba | 29.588264 | 29.903722 | H08 baseline |
| 2022-11 | Timor | 30.403152 | 30.682357 | H08 baseline |

The **maximum absolute difference** between the saved Stage 02 SST means and the H08 overlap reference was approximately **6.0 × 10^-13 °C**; the cropped means agreed exactly with the saved Stage 02 means to the CSV's stored precision. All six cropped valid-cell counts agreed with the H08 reference counts. The test tolerance was **1 × 10^-5 °C**.

**Conclusion:** The six checked regional SST values in the original analysis and the current October–November 2022 cropped NetCDFs are consistent with the **H08 reference**, not the alternative H09 means. This resolves the documented *regional data lineage* discrepancy for the transition months without requiring changes to the downstream statistical outputs. It does **not** establish complete pixelwise identity with the original full-disk SST files, independently validate SST accuracy, or rerun the entire 2016–2025 crop.

### 6.2 October–November 2022 regional SST substitutions

Values below are from the Stage 02 paired scenario-output comparison, not from an independent rereading of the original NetCDFs.

| Region | October 2022: H09 − H08 (°C) | November 2022: H09 − H08 (°C) |
|---|---:|---:|
| Flores | +0.337146 | +0.375094 |
| Sumba | +0.298176 | +0.315458 |
| Timor | +0.304175 | +0.279205 |

### 6.3 FDR comparison at the primary q < 0.05 threshold

| Test family | H08 reference | H09 alternative |
|---|---:|---:|
| Monthly lagged, all 39 region–lag tests | 0/39 | 0/39 |
| Seasonal permutation, 12 region–season tests | 4/12 | 4/12 |
| Spatial, Flores within-region | 78/1,158 | 110/1,158 |
| Spatial, Sumba within-region | 0/565 | 0/565 |
| Spatial, Timor within-region | 0/1,088 | 0/1,088 |
| Spatial, pooled three-region family | 0/2,811 | 0/2,811 |
| Partial correlation adjusted for Niño 3.4 | 0/12 | 0/12 |
| Partial correlation adjusted for DMI | 0/12 | 0/12 |
| Coarse grid, Flores within-region | 19/305 | 31/305 |
| Coarse grid, Sumba within-region | 0/144 | 0/144 |
| Coarse grid, Timor within-region | 0/278 | 0/278 |
| Coarse grid, pooled three-region family | 0/727 | 0/727 |

The secondary 21-test family for lags 0 through +6 also retains **0/21 at q < 0.05 in both scenarios**. The full details of all **13** families, including q < 0.10 counts and decision changes, are in `03_FDR_Family_Comparison.csv`.

**Interpretation:** The within-region spatial counts for Flores depend on which October–November 2022 SST product is used, but no spatial cell survives the pooled 2,811-test correction under either scenario. Significant neighboring cells should not be interpreted as independent observations or as evidence of causation.

### 6.4 Seasonal conclusions

The same **four** region–season associations remain FDR-retained (`q < 0.05`) in both scenarios:

- Flores JJA: `r = 0.856872` in both scenarios.
- Sumba JJA: `r = 0.838180` in both scenarios.
- Timor JJA: `r = 0.791689` in both scenarios.
- Timor SON: `r = 0.814925` (H08) versus `0.855056` (H09), still FDR-retained.

A secondary interpretation changes for **Flores SON**, with `r = 0.628390`, `q = 0.133387` (H08; not retained or suggestive), versus `r = 0.686810`, `q = 0.077792` (H09; **suggestive only**, not significant at the primary 5% threshold).

The primary count of four FDR-retained seasonal tests is unchanged. A q-value for an otherwise unchanged JJA correlation may still change because the **12-test BH-FDR calculation is a joint family correction**: changes in other season–region p-values affect the adjusted ranking and q-values.

For the 39-test monthly lag family, the counts below the exploratory `q < 0.10` threshold change from **0 (H08)** to **3 (H09)**, but neither scenario produces an FDR-retained lag result at `q < 0.05`. The restricted 21-test lag family has **6 (H08)** versus **5 (H09)** cases below `q < 0.10`; this restricted family does not replace the primary 39-test analysis.

## 7. Interpretation and methodological limits

1. The new crop-source QC confirms the **six checked H08 regional monthly inputs** in the main study; the H08/H09 sensitivity comparison preserves input rainfall and climate indices, and switches only the six specified regional SST observations. Recomputed anomalies and downstream results may consequently differ at many other calendar positions or spatial grids.
2. The experiment changes both satellite source and SST product-processing version. It cannot establish that one satellite is more accurate or attribute all differences uniquely to the platform.
3. Small seasonal samples (`n = 9` or `10`) give uncertain inference; unrestricted yearwise permutation procedures do not necessarily preserve serial dependence associated with climate modes.
4. The 95% Fisher-z confidence intervals used upstream are approximate and not automatically FDR-corrected or serial-dependence-corrected.
5. Within-region and pooled spatial BH-FDR corrections correspond to different test families. They must not be combined or represented as interchangeable evidence.
6. The Stage 07a SST-domain test and Stage 07b Flores north–south test have **not** been source-switched and rerun; their source-transition robustness is not established here.
7. The test evaluates observed associations and their sensitivity to a specific input choice. It does **not** establish causal ocean–atmosphere mechanisms or independent rainfall-prediction skill.

## 8. Repository publication checklist

- [ ] Confirm the exact four H08/H09 monthly NetCDF source files and retain their source metadata and file checksums.
- [ ] Keep all four contents of `02_Comparison_Outputs/` together with the overlapping-source analysis script.
- [x] Add the `00_Original_Methods/` directory to the local Folder 09 (confirmed in the latest folder screenshot).
- [ ] Verify that it contains all **20 frozen scripts** at the required relative paths and that each matches the SHA256 manifest.
- [ ] Verify the SHA256 manifest against the **actual frozen scripts** in this folder (not only similarly named scripts elsewhere).
- [ ] Keep both `03_Scenarios/` branches, or deposit enough intermediate input/outputs and explicit source links to reproduce each reported comparison.
- [ ] Deposit all **seven** documented `04_Comparison/` files (the six core comparison files plus `06_Crop_Source_Lineage_QC.csv`); retain the run logs documenting a successful complete execution locally or in the archive.
- [x] Execute `check_H08_H09_source_lineage.m` locally and retain the resulting CSV (**6/6 H08 matches** documented in the supplied output).
- [ ] Include `check_H08_H09_source_lineage.m` at the root of Folder 09 so this independent verification can be rerun.
- [ ] Verify that the main manuscript and Figures 1–5 continue to cite **H08_Final** as the primary analysis; the H09 results are explicitly labeled a sensitivity scenario.
- [ ] Do not present `07a` or `07b` as completed H08/H09 sensitivity comparisons.
- [ ] Do not describe the 2,811 pooled spatial tests as independent geographic replicates.
- [ ] Archive `README_MULAI_DARI_NOL.md` as historical setup instructions rather than retaining its obsolete folder names or deletion steps in the public README.

## 9. Relationship to the manuscript and supplementary material

The article's primary results are based on **`H08_Final`**, including the verified H08 regional SST values for October–November 2022. The **`H09_Alternative`** is reported as a controlled source-transition sensitivity analysis. The new `06_Crop_Source_Lineage_QC.csv` documents a separate check of the original Stage 01 cropped SST regional means and valid-cell counts against the Stage 02 and H08/H09 overlap references. Cite `04_Seasonal_Conclusions.csv` for the 12 seasonal decisions, `03_FDR_Family_Comparison.csv` for the family-level spatial/lag/partial results, and `01_Metric_Delta_Summary.csv` for the extent of numeric changes. Use `02_Metric_Delta_Detail_Changed_Only.csv` for exact audit-level comparisons rather than copying thousands of entries into the manuscript.

**Verification status of this README (25 November 2026):** The previously documented scenario comparison tables, script inventory, and provided H08 outputs were reviewed for internal consistency. The researcher also **ran the new Stage 01 cropped-source QC in MATLAB** and supplied its six-record CSV; all six region–month findings show `CROP_MATCHES_H08_BASELINE`. This is verified against the **submitted QC CSV** and the documented script, not a separate rerun of the two cropped NetCDF files in this review environment. Direct independent reprocessing of the four original October–November 2022 full-disk NetCDF files, verification of the complete `00_Original_Methods/` directory against its checksum manifest, a fresh full scenario-pipeline execution, and inspection of the actual scenario directories and run logs remain outside the completed checks.
