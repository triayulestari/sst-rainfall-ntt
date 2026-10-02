# Seasonal and Spatial SST–Rainfall Relationships over East Nusa Tenggara

## 1. Project overview

This repository contains the GrADS and MATLAB scripts used to reproduce the principal analyses and figures in the manuscript:

**“Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor”**

The study examines temporal, seasonal, and spatial relationships between sea surface temperature (SST) and rainfall across the tropical drylands of East Nusa Tenggara (NTT), Indonesia, with a regional focus on Flores, Sumba, and Timor.

**Study period:** January 2016–December 2025

The main analyses include:

- spatial SST and rainfall climatology;
- regional monthly climatology;
- deseasonalized SST and rainfall anomalies;
- monthly lagged SST–rainfall correlations;
- seasonal SST–rainfall correlations;
- permutation-based significance testing;
- Benjamini–Hochberg false discovery rate (BH-FDR) correction;
- leave-one-year-out (LOYO) robustness analysis;
- grid-based spatial SST–rainfall correlations;
- climate-mode sensitivity using Niño 3.4 and the Dipole Mode Index (DMI); and
- SST-domain sensitivity analysis.

This repository contains the analysis scripts used in the study. Raw satellite, rainfall, and climate-index datasets are not redistributed.

---

## 2. Data sources

### 2.1 Himawari-8/9 sea surface temperature

Monthly Level-3 sea surface temperature (SST) data were obtained from the **Japan Aerospace Exploration Agency (JAXA) Earth Observation Research Center (EORC)** through the **Himawari Monitor / P-Tree** system.

- Product: Himawari-8/9 Level-3 Sea Surface Temperature
- Temporal resolution: monthly
- Spatial resolution: approximately 2 km
- Unit used in the analysis: °C
- Study period: January 2016–December 2025
- Provider: JAXA Earth Observation Research Center (EORC)
- Data access: JAXA Himawari Monitor / P-Tree

Monthly Level-3 SST products for **October and November 2025** were unavailable and were retained as missing values. No temporal interpolation was applied.

### 2.2 CHIRPS rainfall

Monthly rainfall data were obtained from the **Climate Hazards Center InfraRed Precipitation with Stations (CHIRPS) Version 3.0** dataset.

- Product: CHIRPS v3.0
- Temporal resolution: monthly
- Spatial resolution: 0.05°
- Unit used in the analysis: mm month^-1
- Study period: January 2016–December 2025
- Provider: Climate Hazards Center, University of California, Santa Barbara
- Data access: Climate Hazards Center CHIRPS v3 data repository

Rainfall values are retained in **mm month^-1** throughout the final processing workflow.

### 2.3 Niño 3.4 index

Monthly Niño 3.4 SST anomaly values were obtained from the **NOAA Physical Sciences Laboratory (PSL)**.

- Index: Niño 3.4 SST anomaly
- Region: 5°N–5°S, 170°W–120°W
- Source dataset: HadISST1.1
- Temporal resolution: monthly
- Unit: °C
- Provider: NOAA Physical Sciences Laboratory
- Data access: NOAA PSL monthly Niño 3.4 time series

The Niño 3.4 index is used as an indicator of ENSO variability in the climate-mode sensitivity analysis.

### 2.4 Dipole Mode Index

Monthly Dipole Mode Index (DMI) values were obtained from the **NOAA Physical Sciences Laboratory (PSL)**.

- Index: Dipole Mode Index (DMI)
- Source dataset: HadISST1.1
- Temporal resolution: monthly
- Unit: °C
- Provider: NOAA Physical Sciences Laboratory
- Data access: NOAA PSL monthly DMI time series

The DMI represents the anomalous SST gradient between the western and southeastern equatorial Indian Ocean and is used as an indicator of Indian Ocean Dipole variability.

### Data availability

Raw Himawari, CHIRPS, Niño 3.4, and DMI datasets are **not redistributed in this repository**.

Users should obtain the original data directly from the official data providers listed above.

---

## 3. Repository structure

The repository is organized according to the main analysis workflow:

| Folder | Description |
|---|---|
| `01_Preprocessing` | GrADS scripts for spatial subsetting and preprocessing of Himawari SST and CHIRPS rainfall |
| `02_Climatology` | Spatial climatology of SST and rainfall and preparation of Figure 1 |
| `03_Timeseries` | Regional SST and rainfall time series, monthly climatology, deseasonalized anomalies, and Figure 2 |
| `04_Correlation` | Monthly lagged correlations, seasonal correlations, statistical robustness analyses, and Figure 3 |
| `05_Spatial_Correlation` | Grid-based spatial SST–rainfall correlation, autocorrelation-aware significance testing, FDR analysis, and Figure 4 |
| `06_Climate_Mode_Sensitivity` | Niño 3.4 and DMI preparation, seasonal partial correlations, robustness analysis, and Figure 5 |
| `07_Box_Sensitivity` | Sensitivity of seasonal SST–rainfall correlations to changes in the SST averaging domains |

The script filenames stored in each folder are the final filenames used for the analysis.

Some scripts generate intermediate `.mat` and `.csv` files that are subsequently used by scripts in the same or later analysis stages.

---

## 4. Software and dependencies

### 4.1 Main software

The analyses were developed using:

- **MATLAB R2021a**
- **GrADS**
- **M_Map mapping toolbox**
- **cmocean MATLAB colormap package**

GrADS is used primarily for spatial subsetting and preprocessing of the original SST and rainfall datasets.

MATLAB is used for regional time-series extraction, climatology, anomaly calculation, statistical analyses, sensitivity analyses, and figure generation.

### 4.2 MATLAB mapping dependencies

The spatial plotting scripts in:

- `02_Climatology`
- `05_Spatial_Correlation`

require the **M_Map mapping toolbox**.

Key M_Map functions used in the spatial plotting workflow include:

- `m_proj`
- `m_pcolor`
- `m_grid`
- `m_gshhs_h`
- `m_line`
- `m_text`

High-resolution coastline plotting with `m_gshhs_h` may require the associated GSHHS coastline data supplied with a complete M_Map installation.

Selected spatial figures also use the **cmocean** MATLAB colormap package.

These third-party functions and supporting files are **not redistributed in this repository**. Users should obtain and install compatible versions independently and make them available on the MATLAB path before running the spatial plotting scripts.

MATLAB can be used to check whether the required functions are available:

```matlab
which m_proj
which m_pcolor
which m_grid
which m_gshhs_h
which m_line
which m_text
which cmocean
```

If MATLAB returns the corresponding file locations, the required functions are available on the MATLAB path.

For questions regarding the plotting dependencies or reproduction of the MATLAB environment used in this study, users may contact the author.

---

## 5. Analysis workflow

The overall analysis workflow is:

```text
Himawari SST + CHIRPS rainfall
              │
              ▼
01_Preprocessing
Spatial subsetting to the NTT domain
              │
              ▼
02_Climatology
Spatial SST and rainfall climatology
              │
              ▼
03_Timeseries
Regional monthly SST and rainfall
              │
              ├── Monthly climatology
              │
              └── Deseasonalized anomalies
              │
              ▼
04_Correlation
Lagged monthly correlation
Seasonal correlation
Permutation testing
Effective sample size
BH-FDR correction
LOYO robustness
              │
        ┌─────┴─────┐
        ▼           ▼
05_Spatial       06_Climate_Mode
Correlation      Sensitivity
        │           │
        └─────┬─────┘
              ▼
07_Box_Sensitivity
SST-domain sensitivity analysis
```

### 5.1 Deseasonalized anomalies

Monthly SST and rainfall anomalies are calculated relative to the climatological mean of the same calendar month:

```text
anomaly(t) =
value(t) - climatological mean of the corresponding calendar month
```

For example, a January value is referenced to the mean of all available January values during the 2016–2025 study period.

This procedure removes the mean annual cycle before the monthly SST–rainfall relationships are evaluated.

### 5.2 Seasonal definitions

The seasonal analyses use:

- **DJF:** December–January–February
- **MAM:** March–April–May
- **JJA:** June–July–August
- **SON:** September–October–November

The seasonal samples used in the analysis are:

```text
DJF : 2017–2025 | n = 9
MAM : 2016–2025 | n = 10
JJA : 2016–2025 | n = 10
SON : 2016–2024 | n = 9
```

DJF is assigned to the year of January–February. For example, DJF 2017 consists of December 2016, January 2017, and February 2017.

SON 2025 is excluded because the October and November 2025 SST products are unavailable.

### 5.3 Statistical analyses

The principal statistical procedures include:

- Pearson correlation;
- monthly lagged correlation from -6 to +6 months;
- lag-1 autocorrelation assessment;
- autocorrelation-adjusted effective sample size;
- seasonal correlation;
- 10,000-permutation significance testing;
- Fisher-z confidence intervals;
- Benjamini–Hochberg false discovery rate correction;
- leave-one-year-out robustness analysis;
- grid-based spatial correlation;
- partial correlation controlling Niño 3.4 and DMI separately; and
- SST-domain sensitivity testing.

For the monthly lagged analysis:

```text
negative lag = rainfall leads SST
lag 0        = concurrent relationship
positive lag = SST leads rainfall
```

Lagged correlations are interpreted as temporal associations and **not as evidence of causality**.

---

## 6. How to run the code

### Step 1 — Obtain the original datasets

Obtain the following datasets from their official providers:

- Himawari-8/9 Level-3 SST
- CHIRPS v3.0 monthly rainfall
- Niño 3.4 index
- Dipole Mode Index (DMI)

The raw datasets do not need to be stored inside the GitHub repository.

### Step 2 — Run the preprocessing scripts

Run the GrADS scripts in:

```text
01_Preprocessing
```

These scripts are used to spatially subset the original Himawari SST and CHIRPS rainfall datasets to the East Nusa Tenggara study domain.

After preprocessing, CHIRPS rainfall remains in **mm month^-1** throughout the analysis. No additional multiplication or division by 1000 is applied in the final workflow.

### Step 3 — Configure local data paths

Raw and cropped datasets are not included in this repository.

Before running the MATLAB scripts, users should modify the input paths in the relevant scripts according to the locations of the datasets on their local computer.

For example:

```matlab
folder_sst  = 'PATH_TO_CROPPED_SST_DATA';
folder_prec = 'PATH_TO_CROPPED_CHIRPS_DATA';
```

Some scripts use relative paths to outputs generated in earlier analysis folders. Users should preserve the repository folder structure or modify these paths accordingly.

### Step 4 — Install the spatial plotting dependencies

Before running scripts that generate spatial maps, install:

- M_Map
- cmocean

and make the required functions available on the MATLAB path.

A complete M_Map installation may be required for high-resolution coastline plotting.

### Step 5 — Run the analysis stages

Run the analysis folders in the following general order:

```text
01_Preprocessing
      ↓
02_Climatology
      ↓
03_Timeseries
      ↓
04_Correlation
      ↓
05_Spatial_Correlation
      ↓
06_Climate_Mode_Sensitivity
      ↓
07_Box_Sensitivity
```

Within each folder, follow the sequence and instructions provided in the individual script headers.

It is recommended to run the scripts from their respective folders unless the input and output paths have been modified.

Intermediate `.mat` and `.csv` files generated by earlier scripts may be required as inputs for subsequent analyses.

### Step 6 — Climate-mode sensitivity analysis

Before running the scripts in:

```text
06_Climate_Mode_Sensitivity
```

obtain the monthly Niño 3.4 and DMI data described in Section 2.

The climate-index preparation step organizes these data for the monthly and seasonal periods used in the SST–rainfall analysis.

Niño 3.4 and DMI are already anomaly/index products and are therefore **not deseasonalized again**.

The subsequent scripts calculate partial SST–rainfall correlations while controlling Niño 3.4 and DMI separately.

### Step 7 — SST-domain sensitivity analysis

The scripts in:

```text
07_Box_Sensitivity
```

evaluate whether the seasonal SST–rainfall relationships are sensitive to small changes in the SST averaging domains.

The tested SST-domain perturbations are:

```text
-0.2°
-0.1°
Baseline
+0.1°
+0.2°
```

The rainfall regions remain unchanged during this sensitivity analysis.

---

## 7. Reproducibility notes

The following details should be considered when reproducing the analyses.

### Missing SST data

Monthly Himawari Level-3 SST data for **October and November 2025** were unavailable.

These months were retained as missing values and were not temporally interpolated.

### Rainfall units

CHIRPS rainfall is retained in:

```text
mm month^-1
```

throughout the final workflow.

### Deseasonalization

Monthly SST and rainfall anomalies are calculated relative to the climatological mean of the corresponding calendar month.

### Seasonal sample sizes

The seasonal sample sizes are:

- DJF: `n = 9`
- MAM: `n = 10`
- JJA: `n = 10`
- SON: `n = 9`

### Permutation analysis

The main seasonal robustness analyses use **10,000 permutations**.

A fixed random-number seed is used in the relevant scripts to support reproducibility.

### Climate-mode controls

Niño 3.4 and DMI are controlled **separately** in the seasonal partial-correlation analysis.

They are not entered simultaneously because of the small seasonal sample size.

### Spatial correlation

The spatial correlation analysis relates the regional-mean SST anomaly to rainfall anomalies at individual land grid cells.

The spatial grid cells should not be interpreted as independent statistical observations.

---

## 8. Manuscript figures

The repository contains scripts associated with the principal figures in the manuscript:

| Figure | Analysis |
|---|---|
| **Figure 1** | Spatial climatology of rainfall and SST |
| **Figure 2** | Regional monthly climatology and deseasonalized SST/rainfall anomalies |
| **Figure 3** | Monthly lagged and seasonal SST–rainfall correlations |
| **Figure 4** | Spatial heterogeneity of SST–rainfall correlations |
| **Figure 5** | Seasonal partial correlations controlling Niño 3.4 and DMI |

The SST-domain sensitivity analysis in `07_Box_Sensitivity` supports the robustness assessment reported in the manuscript but is not presented as a separate main figure.

---

## 9. Manuscript and citation

This repository accompanies the manuscript:

**Satellite-Based Seasonal and Spatial Sea Surface Temperature–Rainfall Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba, and Timor**

The repository contains the analysis code used to reproduce the principal analyses and figures reported in the manuscript.

Citation details, journal information, and the article DOI will be added after publication.

A permanent repository DOI may also be added after an archived release of this repository is created.

If using or adapting the scripts in this repository, please cite the associated article and the archived repository version once the final citation information becomes available.

---

## 10. Contact

For questions regarding the analysis workflow, code implementation, data preparation, or MATLAB plotting dependencies, please contact the corresponding author using the contact information provided in the associated manuscript.