# 09 — Himawari-8/Himawari-9 SST Source-Transition Sensitivity

## 1. Purpose and scope

This folder documents a controlled sensitivity experiment for the article **“Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor.”** It assesses whether replacing the regional monthly sea surface temperature (SST) inputs for **October and November 2022** changes the statistical results reported for Flores, Sumba, and Timor.

Two scenarios are compared:

- **`H08_Final` (reference):** the original study's processed regional SST series and associated outputs.
- **`H09_Alternative` (sensitivity scenario):** the same series and procedures, except that **six regional SST observations** (three regions × two months) are replaced with values derived from the Himawari-9 product.

The difference convention is **`H09_Alternative − H08_Final`** throughout the comparison files. All other monthly SST inputs, CHIRPS rainfall observations, and Niño 3.4/DMI input values are unchanged between scenarios. The October–November **2025 SST data gaps remain missing** in both scenarios; they are not filled or interpolated. Each scenario contains 120 calendar positions (January 2016–December 2025), with 118 available regional SST months and 120 rainfall months.

**This is a source/product-transition sensitivity test, not an independent validation of SST accuracy.** The satellite platform and processing-product version change together (Himawari-8 SST v2.00 versus Himawari-9 SST v2.01), so their separate effects cannot be isolated using this experiment.

## 2. Folder layout and required components

The following is the layout expected by the supplied pipeline scripts. The `00_Original_Methods/` directory is **required for a clean rerun** and must be present locally, even if a public deposit omits large source NetCDF files.

```text
09_Transition_Sensitivity/
├── README_09_Transition_Sensitivity.md
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
│   └── 05_Methods_and_Interpretation.txt
├── 05_Run_Logs/
│   └── run_YYYYMMDD_HHMMSS.txt
├── a_compare_h08_h09_overlap.m
├── b_prepare_h09_scenario.m
├── run_H08_H09_clean.m
└── z_compare_scenarios.m
```

The screenshot supplied during documentation review did not show `00_Original_Methods/`; verify that this directory exists before attempting to rerun `run_H08_H09_clean.m`. The SHA256 manifest **does not contain executable source code** and cannot replace the 20 scripts. The old `README_MULAI_DARI_NOL.md` uses an obsolete output-folder name and contains reset/deletion instructions; it should be archived rather than used as the public-facing README.

## 3. Input provenance and overlap comparison

**Original SST source comparison** (`a_compare_h08_h09_overlap.m`):

1. Reads one Himawari-8 and one Himawari-9 monthly SST NetCDF for each of October and November 2022 (four inputs total).
2. Checks the source file names, products, SST and geolocation variables, original units, raster size and file inventory.
3. Computes mean SST independently for each product in the baseline SST rectangles for Flores, Sumba and Timor, plus the broader NTT study domain.
4. Evaluates **paired-pixel differences** only when H08 and H09 coordinates are co-located within the specified tolerance and both SST values are valid.
5. Writes the four files under `02_Comparison_Outputs/` shown above.

**Do not confuse** the difference between independently calculated regional means with the average of paired H09–H08 pixel differences. Different valid-pixel coverage can make these quantities unequal. The regional mean differences are the values used to form the alternative scenario.

**Important provenance limitation:** The present audit included the overlap-comparison code and the names of its output files, but not the four underlying NetCDFs or the four content files from `02_Comparison_Outputs/`. Thus, the original product comparison, source-inventory fields and pixel-level results have **not** been independently rechecked in this audit. Retain these inputs locally and report their provider/source metadata and checksums where permitted.

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

The stage labels `07a`–`07d` refer to the frozen methods' file names. The runner will **skip apparently complete output sets** and **stop on partial output sets**, so do not mix a fresh execution with pre-existing scenario results. Preserve earlier outputs in an archive outside the active run before starting a genuinely fresh run. The script does not delete source files.

The file `00_Original_Methods_SHA256.csv` lists SHA256 digests for 20 frozen methods. These digests can be checked against the actual `.m` files before and after running. **The supplied pipeline does not itself enforce the SHA256 manifest**; a separate hash comparison is needed. During the current audit, all 20 digests matched the 20 corresponding previously uploaded stage scripts, but the actual `00_Original_Methods/` directory and full run logs were not supplied for direct inspection.

## 5. Comparison outputs and audit trail

`z_compare_scenarios.m` aligns paired CSV outputs by explicit scientific keys (time, region, season, year, lag or grid coordinates as appropriate) rather than assuming identical row ordering. Numeric changes greater than `1e-12` are enumerated. The six comparison files have the following roles:

| File | Content |
|---|---|
| `00_Run_Status.csv` | Completed stages and explicit Stage 07 exclusions |
| `01_Metric_Delta_Summary.csv` | Number and size of changes per numeric variable and source file |
| `02_Metric_Delta_Detail_Changed_Only.csv` | One row per changed numeric value, with original, alternative and signed delta |
| `03_FDR_Family_Comparison.csv` | Significance and exploratory-threshold counts for each FDR test family |
| `04_Seasonal_Conclusions.csv` | H08/H09 seasonal r, permutation p, FDR q and resulting category per region–season |
| `05_Methods_and_Interpretation.txt` | Comparison conventions, scope, warnings and limits |

In the supplied final comparison files, `maxStage = 7`, with **218 numeric metric summaries**, **24,450 changed numeric records** and **13 FDR-family rows**. These 24,450 records include changes in downstream, gridded metrics and **do not mean that 24,450 source SST observations were replaced**. Exactly six regional SST input observations were substituted.

## 6. Observed source-scenario differences

### 6.1 October–November 2022 regional SST substitutions

Values below are from the Stage 02 paired scenario-output comparison, not from an independent rereading of the original NetCDFs.

| Region | October 2022: H09 − H08 (°C) | November 2022: H09 − H08 (°C) |
|---|---:|---:|
| Flores | +0.337146 | +0.375094 |
| Sumba | +0.298176 | +0.315458 |
| Timor | +0.304175 | +0.279205 |

### 6.2 FDR comparison at the primary q < 0.05 threshold

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

### 6.3 Seasonal conclusions

The same **four** region–season associations remain FDR-retained (`q < 0.05`) in both scenarios:

- Flores JJA: `r = 0.856872` in both scenarios.
- Sumba JJA: `r = 0.838180` in both scenarios.
- Timor JJA: `r = 0.791689` in both scenarios.
- Timor SON: `r = 0.814925` (H08) versus `0.855056` (H09), still FDR-retained.

A secondary interpretation changes for **Flores SON**, with `r = 0.628390`, `q = 0.133387` (H08; not retained or suggestive), versus `r = 0.686810`, `q = 0.077792` (H09; **suggestive only**, not significant at the primary 5% threshold).

The primary count of four FDR-retained seasonal tests is unchanged. A q-value for an otherwise unchanged JJA correlation may still change because the **12-test BH-FDR calculation is a joint family correction**: changes in other season–region p-values affect the adjusted ranking and q-values.

For the 39-test monthly lag family, the counts below the exploratory `q < 0.10` threshold change from **0 (H08)** to **3 (H09)**, but neither scenario produces an FDR-retained lag result at `q < 0.05`. The restricted 21-test lag family has **6 (H08)** versus **5 (H09)** cases below `q < 0.10`; this restricted family does not replace the primary 39-test analysis.

## 7. Interpretation and methodological limits

1. The H08/H09 comparison preserves input rainfall and climate indices; only the six specified regional SST observations are switched. Recomputed anomalies and downstream results may consequently differ at many other calendar positions or spatial grids.
2. The experiment changes both satellite source and SST product-processing version. It cannot establish that one satellite is more accurate or attribute all differences uniquely to the platform.
3. Small seasonal samples (`n = 9` or `10`) give uncertain inference; unrestricted yearwise permutation procedures do not necessarily preserve serial dependence associated with climate modes.
4. The 95% Fisher-z confidence intervals used upstream are approximate and not automatically FDR-corrected or serial-dependence-corrected.
5. Within-region and pooled spatial BH-FDR corrections correspond to different test families. They must not be combined or represented as interchangeable evidence.
6. The Stage 07a SST-domain test and Stage 07b Flores north–south test have **not** been source-switched and rerun; their source-transition robustness is not established here.
7. The test evaluates observed associations and their sensitivity to a specific input choice. It does **not** establish causal ocean–atmosphere mechanisms or independent rainfall-prediction skill.

## 8. Repository publication checklist

- [ ] Confirm the exact four H08/H09 monthly NetCDF source files and retain their source metadata and file checksums.
- [ ] Keep all four contents of `02_Comparison_Outputs/` together with the overlapping-source analysis script.
- [ ] Add `00_Original_Methods/` with the 20 frozen scripts at the exact relative paths expected by the runner, or state explicitly that a clean rerun requires separately obtaining them.
- [ ] Verify the SHA256 manifest against the **actual frozen scripts** in this folder (not only similarly named scripts elsewhere).
- [ ] Keep both `03_Scenarios/` branches, or deposit enough intermediate input/outputs and explicit source links to reproduce each reported comparison.
- [ ] Deposit all six `04_Comparison/` files; retain the run logs documenting a successful complete execution locally or in the archive.
- [ ] Verify that the main manuscript and Figures 1–5 continue to cite **H08_Final** as the primary analysis; the H09 results are explicitly labeled a sensitivity scenario.
- [ ] Do not present `07a` or `07b` as completed H08/H09 sensitivity comparisons.
- [ ] Do not describe the 2,811 pooled spatial tests as independent geographic replicates.
- [ ] Archive `README_MULAI_DARI_NOL.md` as historical setup instructions rather than retaining its obsolete folder names or deletion steps in the public README.

## 9. Relationship to the manuscript and supplementary material

The article's primary results are based on **`H08_Final`**. The **`H09_Alternative`** is reported as a controlled source-transition sensitivity analysis. Cite `04_Seasonal_Conclusions.csv` for the 12 seasonal decisions, `03_FDR_Family_Comparison.csv` for the family-level spatial/lag/partial results, and `01_Metric_Delta_Summary.csv` for the extent of numeric changes. Use `02_Metric_Delta_Detail_Changed_Only.csv` for exact audit-level comparisons rather than copying thousands of entries into the manuscript.

**Verification status of this README:** The documented comparison tables, available scripts, 20-method SHA256 manifest, and uploaded H08 reference outputs were inspected for internal consistency. Direct rerunning of MATLAB and direct comparison to the four October–November 2022 source NetCDF files, the `02_Comparison_Outputs/` contents, the actual `03_Scenarios/` directories and run logs remain outside the completed verification.
