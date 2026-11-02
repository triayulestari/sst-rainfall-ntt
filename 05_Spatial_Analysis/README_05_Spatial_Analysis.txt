STEP 05 - GRID-LEVEL SPATIAL SST-RAINFALL CORRELATIONS
=====================================================

PURPOSE
-------
Estimate zero-lag monthly Pearson correlations between a single regional-
mean marine SST deseasonalized anomaly time series and the rainfall
deseasonalized anomaly time series at each valid CHIRPS land grid.
Spatial correlations here are NOT restricted to JJA.

SOFTWARE AND INPUTS
-------------------
MATLAB R2021a; Statistics and Machine Learning Toolbox.
- ../01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
  (local source-derived data, not provided on GitHub)
- ../02_Regional_Timeseries/regional_anomalies.mat

RUN IN ORDER
------------
1. a_prepare_spatial_rainfall_anomalies.m
   Outputs: spatial_rainfall_anomaly.mat,
            spatial_rainfall_grid_QC.csv,
            spatial_rainfall_monthly_QC.csv,
            spatial_valid_grid_mask.csv
   Requires finite CHIRPS rainfall data for all 120 months when defining
   the fixed grid-selection mask. Computes calendar-month anomalies.
2. b_spatial_correlation_fdr.m
   Outputs: spatial_correlation_results.mat,
            spatial_correlation_summary.csv,
            spatial_correlation_grid_results.csv
   Computes r, autocorrelation-based N_eff/p, and two distinct BH-FDR
   multiple-testing corrections.

SPATIAL DEFINITIONS AND MULTIPLE TESTING
----------------------------------------
- A valid CHIRPS grid is a land-data grid with available rainfall values;
  Step 05 uses a fixed availability mask requiring all 120 months finite.
- The mask is based on numerical validity, not administrative boundaries,
  coastlines, polygon shapefiles, interpolation or area weighting.
- Within-region BH-FDR: corrections are computed separately for Flores
  (1,158 valid grids), Sumba (565) and Timor (1,088).
- Pooled BH-FDR across the three study regions: one correction across
  all 2,811 valid CHIRPS grids.

QUALITY-CHECK REFERENCE RESULTS
-------------------------------
- Flores: 110 / 1,158 grids at within-region qFDR < 0.05.
- Sumba: 0 / 565 grids at within-region qFDR < 0.05.
- Timor: 0 / 1,088 grids at within-region qFDR < 0.05.
- Pooled BH-FDR: 0 / 2,811 grids significant.
- The Flores cluster survives ONLY the within-region correction framework.
- Nearby grids are spatially dependent. Counts of significant cells are
  not independent statistical replications, and prevalence of positive
  coefficients is not proof of a region-wide significant association.

FILE DEPENDENCIES AND LIMITATIONS
---------------------------------
- Figure 4 reads spatial_correlation_results.mat and
  spatial_correlation_summary.csv from this folder.
- Step 07 coarse-resolution sensitivity uses spatial_rainfall_anomaly.mat
  and spatial_correlation_results.mat.
- Publish required intermediate MAT files with corresponding CSV results;
  the summary CSV alone cannot reconstruct the gridded correlation maps.
- Original cropped CHIRPS NetCDFs are not deposited, so rebuilding the
  gridded anomalies from original rainfall observations requires Step 01.
