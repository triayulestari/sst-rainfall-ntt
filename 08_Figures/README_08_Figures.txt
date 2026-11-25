STEP 08 - MANUSCRIPT FIGURES 1-5 AND FIGURE QUALITY CONTROL
=========================================================

1. PURPOSE AND SCOPE
--------------------
This folder contains the MATLAB scripts used to generate Figures 1-5 of
"Satellite-Based Seasonal and Spatial Sea Surface Temperature-Rainfall
Relationships across Tropical Drylands of East Nusa Tenggara: Flores, Sumba,
and Timor". It also contains figure-specific quality-control (QC) tables,
optional plotting data, and visual inspection images.

The figures are graphical presentations of the data and statistical outputs
from preceding stages. Figures 2-5 read existing upstream results; they do
not perform new hypothesis tests. Figure 1 independently derives mapped
study-period means from the locally cropped monthly NetCDF files in Step 01.

2. SOFTWARE AND EXTERNAL DEPENDENCIES
-------------------------------------
- MATLAB R2021a.
- M_Map and its GSHHS high-resolution coastline data: required for Figures
  1 and 4 (including the m_gshhs_h function).
  M_Map project: https://www.eoas.ubc.ca/~rich/map.html
- Statistics and Machine Learning Toolbox: required by Figure 4 for boxplot.
- cmocean for MATLAB: optional for Figure 1. If cmocean is unavailable,
  the script uses built-in MATLAB fallback color maps.
  https://github.com/chadagreene/cmocean
- All external toolboxes and coastline data must be obtained from their
  providers and made available on the MATLAB search path. They are not
  redistributed in this repository. The exact local GSHHS release should be
  recorded separately when known; do not infer a release number from the
  MATLAB function name alone.

3. REQUIRED UPSTREAM DATA AND FOLDER STRUCTURE
-----------------------------------------------
Keep the numbered analysis folders as siblings under the same project root.
Scripts resolve inputs relative to their own saved .m file locations.

Data/
  01_SST_Rainfall_NTT_2016_2025/
    01_Crop_SST_NTT/sst_YYYYMM.nc                  [LOCAL ONLY]
    02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc            [LOCAL ONLY]
  02_Regional_Timeseries/
    regional_anomalies.mat
  03_Monthly_and_Lagged/
    lagged_correlation_results.csv
  04_Seasonal_Analysis/
    seasonal_robustness_results.csv
  05_Spatial_Analysis/
    spatial_correlation_results.mat
    spatial_correlation_summary.csv
    spatial_correlation_grid_results.csv           [CSV fallback for Figure 4]
    spatial_valid_grid_mask.csv                    [CSV fallback for Figure 4]
  06_Climate_Mode_Sensitivity/
    seasonal_partial_robustness_results.csv
  08_Figures/
    README_08_Figures.txt
    a_figure1_spatial_climatology.m
    b_figure2_seasonal_patterns.m
    c_figure3_lagged_seasonal_correlations.m
    d_figure4_spatial_correlations.m
    e_figure5_partial_correlation_heatmaps.m
    [generated figures, QC tables, optional MAT/PDF/metadata files]

A complete rerun of Figure 1 requires the cropped SST and CHIRPS NetCDF
files, which are not publicly redistributed. Figure 4 can use its Stage 05
MAT input or the full gridded-result and valid-mask CSV alternative. A Stage
05 summary CSV alone is not enough to reconstruct Figure 4.

4. EXECUTION ORDER AND FIGURE-SPECIFIC METHODS
-----------------------------------------------
The five plotting scripts may be run in the following order after all their
respective upstream inputs are available. Do not modify upstream numerical
results merely to change figure appearance.

A. a_figure1_spatial_climatology.m
   Panels:
     (a) Land rainfall from CHIRPS v3.0; (b) marine SST from Himawari L3.
   Input:
     Step 01 cropped CHIRPS annual NetCDFs and Himawari monthly NetCDFs.
   Calculations and map conventions:
     - At each location, calculate the mean for each calendar month using
       available study-period years, then average the twelve calendar-month
       means with equal weight. These are 2016-2025 study-period means,
       not a 30-year climatological normal.
     - SST: 118 monthly source fields. October-November 2025 are absent;
       consequently October and November calendar-month means use nine
       years, while the other SST months use ten years.
     - CHIRPS: 120 months (ten years for every calendar month).
     - The red rectangles indicate CHIRPS regional geographic selections,
       not administrative/polygon masks. SST study boxes are defined
       separately in Step 02 and need not have exactly the same edges.
     - Mercator projection; GSHHS coastline is used for display. The
       approximately 100-km map-scale annotation is approximate.
     - Maps are not spatially interpolated or area-weighted.
   Outputs:
     Figure_1_Spatial_Climatology.png
     Figure_1_Spatial_Climatology.pdf
     Figure_1_Spatial_Climatology_Data.mat
     Figure_1_Monthly_Data_QC.csv
     Figure_1_Geographic_Metadata.txt
   PDF export is raster/image based (400 dpi); PNG export is 600 dpi.

B. b_figure2_seasonal_patterns.m
   Panels:
     (a) Regional SST calendar-month means;
     (b) regional rainfall calendar-month means;
     (c) monthly deseasonalized SST anomalies;
     (d) monthly deseasonalized rainfall anomalies.
   Input:
     ../02_Regional_Timeseries/regional_anomalies.mat
   Methods and data display:
     - Deseasonalized anomaly = monthly value minus the study-period mean
       for the SAME calendar month. Neither overall-mean anomalies nor
       detrended anomalies are plotted in panels (c) and (d).
     - SST October-November 2025 remain missing (NaN) and are NOT connected
       across the gap; available December 2025 SST values appear separately.
     - SST and rainfall use 118 and 120 available monthly observations,
       respectively, for each regional time series.
   Outputs:
     Figure_2_Seasonal_Patterns_Anomalies.png
     Figure_2_Seasonal_Patterns_Anomalies.pdf
     Figure_2_Plot_Data.mat
     Figure_2_Data_QC.csv
     Figure_2_Methods_Metadata.txt
   PNG export is 600 dpi; PDF export is vector.

C. c_figure3_lagged_seasonal_correlations.m
   Panels:
     (a) Monthly deseasonalized SST-rainfall lag correlations (-6 to +6);
     (b) seasonal SST-rainfall correlation heatmap (DJF/MAM/JJA/SON).
   Inputs:
     ../03_Monthly_and_Lagged/lagged_correlation_results.csv
     ../04_Seasonal_Analysis/seasonal_robustness_results.csv
   Methods and annotations:
     - Positive lag +k means SST(t) is correlated with rainfall(t+k);
       negative lag denotes rainfall leading SST.
     - Lag-panel q-values are from BH-FDR over all 39 region-lag tests,
       using autocorrelation-adjusted p-values from Step 03.
     - Seasonal-panel q-values are from BH-FDR across 12 region-season
       tests, based on 10,000 two-sided yearwise permutations in Step 04.
     - * and a solid outline: q_FDR < 0.05 (FDR-retained).
     - Dagger and a dashed outline/ring: 0.05 <= q_FDR < 0.10
       (suggestive only; NOT significant at the primary 5% threshold).
     - No mark: q_FDR >= 0.10.
     - Heatmap colors encode Pearson r, not significance.
   Outputs:
     Figure_3_Lagged_Seasonal_Correlations.png
     Figure_3_Lagged_Seasonal_Correlations.pdf
     Figure_3_Annotation_QC.csv
     Figure_3_Methods_Metadata.txt
   The QC CSV records 39 lag results plus 12 seasonal results (51 rows).
   PNG export is 600 dpi; PDF export is vector.

D. d_figure4_spatial_correlations.m
   Panels:
     (a) Flores gridded correlations;
     (b) Sumba gridded correlations;
     (c) Timor gridded correlations;
     (d) descriptive regional distributions of gridwise Pearson r.
   Inputs:
     ../05_Spatial_Analysis/spatial_correlation_results.mat
     ../05_Spatial_Analysis/spatial_correlation_summary.csv
   Alternative if the MAT file is unavailable:
     ../05_Spatial_Analysis/spatial_correlation_grid_results.csv
     ../05_Spatial_Analysis/spatial_valid_grid_mask.csv
     (plus the summary CSV).
   Methods and annotations:
     - Each raster grid correlates one regional-mean marine SST monthly
       deseasonalized anomaly series with the local CHIRPS rainfall
       deseasonalized anomaly series, at ZERO lag over the study period.
       This is not a JJA-specific spatial analysis.
     - Black dots identify grid cells retained under WITHIN-REGION
       BH-FDR q < 0.05. They do not identify pooled-FDR discoveries.
     - A separate POOLED BH-FDR treats all 2,811 region-grid tests as one
       family covering the three study rectangles, NOT all NTT land.
     - The 2,811 tests cover 2,791 distinct geographic coordinates because
       20 coordinates occur in overlapping regional boxes. Nearby cells
       are spatially dependent, not independent sample replications.
     - The plotted r color scale is centered on zero with limits -0.4 to
       +0.4. The regional boxplots summarize grid coefficients and are
       descriptive rather than independent regional inference.
   Outputs:
     Figure_4_Spatial_Correlations.png
     Figure_4_Spatial_Correlations.pdf
     Figure_4_Spatial_Correlations_Grayscale_QC.png
     Figure_4_Visual_QC.csv
     Figure_4_Methods_Metadata.txt
   PNG export is 600 dpi; PDF export is image/raster based (600 dpi).
   The grayscale image is a visual legibility check, not a new analysis.

E. e_figure5_partial_correlation_heatmaps.m
   Panels:
     (a) Seasonal SST-rainfall partial correlations with Niño 3.4 controlled;
     (b) corresponding partial correlations with DMI controlled.
   Input:
     ../06_Climate_Mode_Sensitivity/
       seasonal_partial_robustness_results.csv
   Methods and annotations:
     - Niño 3.4 and DMI are adjusted for SEPARATELY, not jointly.
     - The published q-values are based on two separate 12-test BH-FDR
       families (one family for each climate index), calculated in Step 06.
     - Both heatmaps share a common -1 to +1 correlation color scale.
     - Top-to-bottom region order: Flores, Sumba, Timor.
     - Dagger indicates only 0.05 <= q_FDR < 0.10; it is not evidence
       of statistical significance at q_FDR < 0.05.
   Outputs:
     Figure_5_Partial_Correlation_Heatmaps.png
     Figure_5_Partial_Correlation_Heatmaps.pdf
     Figure_5_Partial_Correlation_Heatmaps_Grayscale_QC.png
     Figure_5_Annotation_QC.csv
     Figure_5_Methods_Metadata.txt
   PNG export is 600 dpi; PDF export is vector. The grayscale PNG is a
   separate visual-quality check and does not change underlying r values.

5. REFERENCE QC RESULTS FOR THE DEPOSITED ANALYSIS VERSION
-----------------------------------------------------------
These numbers describe the uploaded outputs, NOT hard-coded scientific
assumptions. If source data or methods are revised, regenerate the outputs
and update this section only after comparing the new QC tables.

- Figure 1: SST available = 118/120 months; CHIRPS = 120/120 months;
  SST October and November calendar-month counts = 9 each.
- Figure 2: Flores, Sumba and Timor each have 118 SST and 120 rainfall
  monthly values; missing SST in October-November 2025, December present.
- Figure 3: 39 lag tests: 0 retained at q<0.05 and 0 suggestive at
  0.05<=q<0.10. Twelve seasonal tests: 4 FDR-retained (Flores JJA,
  Sumba JJA, Timor JJA, Timor SON) and 1 suggestive (Flores DJF).
- Figure 4: valid CHIRPS grid tests: Flores 1,158; Sumba 565; Timor
  1,088; total 2,811. Within-region FDR-retained: 78, 0, 0;
  pooled FDR-retained: 0 across all three regions.
- Figure 5: Neither the Niño 3.4-controlled nor DMI-controlled family
  has a result with q<0.05 (0/12 each). Flores JJA and Timor JJA under
  separate Niño 3.4 control have q approximately 0.0840 (suggestive only).

For Figure 1, the map displays SST using the interval 27.5-29.5 deg C.
The saved climatology MAT contains 91,554 finite SST cells; 36 are below
27.5 deg C and 95 are above 29.5 deg C. Their display colors are saturated
at the selected limits, although their original numerical values are retained
in the MAT file. This affects approximately 0.14% of finite SST cells.
Review any unusually high/low local SST values and state or revise display
limits if required by the journal; do not silently alter the underlying SST.

6. FILES TO INCLUDE IN THE PUBLIC GITHUB FOLDER
-----------------------------------------------
Recommended core files:
- README_08_Figures.txt (this document).
- All five .m scripts, under their exact canonical names listed in section 3.
- The five manuscript color PNG files (Figures 1-5).
- Figure_1_Monthly_Data_QC.csv
- Figure_2_Data_QC.csv
- Figure_3_Annotation_QC.csv
- Figure_4_Visual_QC.csv
- Figure_5_Annotation_QC.csv

Useful additional provenance and plotting files:
- Figure_1_Spatial_Climatology_Data.mat
- Figure_2_Plot_Data.mat
- Figure_1_Geographic_Metadata.txt
- Figure_2_Methods_Metadata.txt
- Figure_3_Methods_Metadata.txt
- Figure_4_Methods_Metadata.txt
- Figure_5_Methods_Metadata.txt

The .m scripts generate the metadata TXT files, but those outputs must be
collected from the MATLAB execution directory before publication; do not
claim that absent files have been deposited. PDFs and Figure 4/5 grayscale
QC PNGs may be retained locally or uploaded optionally. PDF and grayscale
copies are not required if the journal accepts the final color PNGs.

Remove browser/download duplicate suffixes such as '(3)', '(4)' or dated
suffixes from filenames when organizing the public repository. Use the
canonical filenames expected by the scripts. For each image, upload the
version generated from the same upstream data and QC tables that accompany
it; do not combine outputs from different analysis revisions.

7. QUALITY-CONTROL AND REPRODUCIBILITY CHECKLIST
------------------------------------------------
- Compare Figure 1 month counts against Figure_1_Monthly_Data_QC.csv;
  verify map units, coordinates, geographic box meaning, latitude labels,
  coastline appearance and approximate scale bar in the exported file.
- Compare Figure 2 displayed series and sample counts against the Step 02
  MAT output; confirm the 2025 SST gap and isolated December values.
- Compare every Figure 3 correlation and symbol against the Step 03/04
  CSV results and Figure_3_Annotation_QC.csv.
- Compare Figure 4 grid counts, displayed black-dot counts, and both FDR
  families against the Step 05 outputs and Figure_4_Visual_QC.csv.
- Compare all Figure 5 numeric labels, sample counts and daggers against
  Step 06 and Figure_5_Annotation_QC.csv.
- Visually inspect the final exported PNGs at manuscript print scale,
  including text/legend readability, map labels and grayscale distinctions.
- Regeneration of Figure 1 requires Step 01 data; the figure-related MAT
  files are derived display data, NOT replacements for upstream inputs.

8. INTERPRETATION LIMITATIONS
-----------------------------
- The mapped and regional statistics describe the specified 2016-2025
  observational record and the rectangular geographic selections used.
- Statistical annotations are based on the exact FDR families indicated
  above. Suggestive q-values are not significant at q<0.05.
- Correlation strengths and lag direction are not evidence of physical
  causality, climate-mode independence, or out-of-sample predictive skill.
- A geographic concentration of individually significant mapped grid tests
  does not amount to independent confirmation across neighboring cells.
- The complete source-to-figure workflow depends on source-derived NetCDF
  data and external MATLAB mapping packages not included in GitHub.
