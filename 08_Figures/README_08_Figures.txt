STEP 08 - MANUSCRIPT FIGURES 1-5 AND VISUAL QUALITY CONTROL
==========================================================

PURPOSE
-------
Regenerate and audit the five manuscript figures using MATLAB R2021a.
Plotting scripts generally read numerical results from earlier stages
rather than recalculating the study's statistical tests.

SOFTWARE
--------
MATLAB R2021a. Figures 1 and 4 require M_Map with appropriate GSHHS
high-resolution coastline files; cmocean may be used for color schemes.
M_Map: https://www.eoas.ubc.ca/~rich/map.html
cmocean for MATLAB: https://github.com/chadagreene/cmocean
External MATLAB mapping/colormap files are not redistributed here.
Download them from their original providers and either place the required
functions in the same MATLAB working directory (the original setup) or
add their installed directories to the MATLAB search path. Preserve any
supporting files/subdirectories required by M_Map/GSHHS.

FIGURE SCRIPTS - INPUTS AND OUTPUTS
----------------------------------
1. a_figure1_spatial_climatology.m
   Input: cropped SST and CHIRPS NetCDFs from Step 01.
   Output: Figure_1_Spatial_Climatology.png,
           Figure_1_Spatial_Climatology_Data.mat,
           Figure_1_Monthly_Data_QC.csv.
   Maps study-period mean SST and rainfall. The map gives equal weight
   to all twelve study-period calendar-month means, accounting for
   unavailable SST data in October-November 2025.
2. b_figure2_seasonal_patterns.m
   Input: ../02_Regional_Timeseries/regional_anomalies.mat
   Output: Figure_2_Seasonal_Patterns_Anomalies.png,
           Figure_2_Plot_Data.mat, Figure_2_Data_QC.csv.
   Shows study-period monthly means and monthly deseasonalized anomalies;
   missing SST October-November 2025 is a gap, not interpolated.
3. c_figure3_lagged_seasonal_correlations.m
   Input: ../03_Monthly_and_Lagged/lagged_correlation_results.csv;
          ../04_Seasonal_Analysis/seasonal_robustness_results.csv
   Output: Figure_3_Lagged_Seasonal_Correlations.png,
           Figure_3_Annotation_QC.csv.
   Plots lag -6...+6 and four-season correlation; annotations use qFDR
   from the source CSVs (39 lag tests, 12 seasonal tests).
4. d_figure4_spatial_correlations.m
   Input: ../05_Spatial_Analysis/spatial_correlation_results.mat;
          ../05_Spatial_Analysis/spatial_correlation_summary.csv
   Output: Figure_4_Spatial_Correlations.png,
           Figure_4_Visual_QC.csv.
   Plots grid-level Pearson r maps and descriptive regional boxplots.
   Black markers represent within-region qFDR findings; no grid is
   significant under pooled BH-FDR across the three study regions.
5. e_figure5_partial_correlation_heatmaps.m
   Input: ../06_Climate_Mode_Sensitivity/
          seasonal_partial_robustness_results.csv
   Output: Figure_5_Partial_Correlation_Heatmaps.png,
           Figure_5_Annotation_QC.csv.
   Niño 3.4/DMI-adjusted partial correlation heatmaps use separate
   families of 12 BH-FDR tests. No partial result meets qFDR < 0.05.

WHAT TO UPLOAD
--------------
- README.txt, the five original .m scripts, the five FINAL color PNGs,
  and the five numerical/visual QC CSVs.
- Optionally retain Figure_1_Spatial_Climatology_Data.mat and
  Figure_2_Plot_Data.mat as inspectable plotting outputs.
- PDF duplicates and grayscale QC images need not be published in the
  public repository unless desired for journal production.
- The MAT plotting outputs do not replace the MATLAB source inputs:
  Figure 2 requires regional_anomalies.mat from Step 02; Figure 4 requires
  spatial_correlation_results.mat from Step 05; Figure 1 requires cropped
  source NetCDFs from Step 01.

QUALITY CONTROL AND LIMITATIONS
-------------------------------
- Confirm output panels, correct axes/units, the two missing SST months,
  and correct annotation symbols against final source CSV results.
- Figures show observations and estimated statistical associations, not
  direct evidence of physical causality or prediction performance.
- Do not rename the original scripts (e.g. remove accidental browser
  download suffixes such as '(1)' before uploading).
