STEP 01 - SST AND CHIRPS DATA CROPPING (2016-2025)
=================================================

PURPOSE
-------
Crop monthly Himawari-8/9 sea surface temperature (SST) and CHIRPS version
3.0 rainfall data to the East Nusa Tenggara (NTT) study context. This stage
creates the NetCDF files required by the MATLAB scripts in Steps 02, 05,
07 and 08. Raw and cropped NetCDF data are not redistributed via GitHub.

SOFTWARE AND ORIGINAL DATA SOURCES
----------------------------------
- GrADS version 2.2.1 (used for the .gs scripts).
- Himawari SST: JAXA Himawari Monitor/P-Tree
  https://www.eorc.jaxa.jp/ptree/registration_top.html
- CHIRPS v3.0 monthly global NetCDF:
  https://data.chc.ucsb.edu/products/CHIRPS/v3.0/monthly/global/netcdf/by_year/
- Original Himawari-8 SST Level-3 v2.0: January 2016-September 2022.
- Original Himawari-9 SST Level-3 v2.1: October 2022-December 2025,
  excluding unavailable October and November 2025.
- CHIRPS version 3.0 monthly precipitation: January 2016-December 2025.

DIRECTORY STRUCTURE - PRESERVE THESE LOCATIONS
-----------------------------------------------
Data/
  01_SST_Rainfall_NTT_2016_2025/
    README_01_SST_Rainfall_NTT_2016_2025.txt
    00_Raw_Data/                              [LOCAL ONLY; DO NOT UPLOAD]
      Himawari_SST_L3_FullDisk/
        H08_YYYYMM01_0000_1MSST200_FLDK.06001_06001.nc
        H09_YYYYMM01_0000_1MSST201_FLDK.06001_06001.nc
      CHIRPS_v3_Monthly_Global/
        chirps-v3.0.YYYY.monthly.nc
    01_Crop_SST_NTT/
      01_crop_himawari_sst_ntt.gs
      sst_YYYYMM.nc                         [LOCAL OUTPUT; DO NOT UPLOAD]
    02_Crop_CHIRPS_NTT/
      02_crop_chirps_v3_ntt.gs
      prec_YYYY.NTT.nc                      [LOCAL OUTPUT; DO NOT UPLOAD]

IMPORTANT WORKING-DIRECTORY INSTRUCTION
---------------------------------------
The .gs scripts use relative raw-data paths starting with ../00_Raw_Data/
and write cropped files to their current GrADS working directory. Some
header comments in the original scripts describe older directory names;
for execution, follow the actual input/output paths in the code.

Without modifying either script:
1. Put raw provider files into the local 00_Raw_Data directories above.
2. Start GrADS with 01_Crop_SST_NTT as the working directory and run
   01_crop_himawari_sst_ntt.gs.
3. Start GrADS with 02_Crop_CHIRPS_NTT as the working directory and run
   02_crop_chirps_v3_ntt.gs.
4. Verify the generated NetCDF files remain alongside the respective .gs
   scripts, where the subsequent MATLAB scripts expect to find them.

SCRIPT 01 - HIMAWARI SST
-----------------------
- Input NetCDF variable: sea_surface_tem (Kelvin).
- Geographic crop: 118.0-127.5 degrees E, 11.5-7.0 degrees S.
- Calculation: sst = sea_surface_tem - 273.15 (degrees Celsius).
- Output: sst_YYYYMM.nc, monthly, 118 files expected.
- SST for October and November 2025 is intentionally absent; December
  2025 remains present. No missing values are interpolated.

SCRIPT 02 - CHIRPS RAINFALL
--------------------------
- Input NetCDF variable: precip.
- Geographic crop: 118.0-127.5 degrees E, 11.5-7.0 degrees S.
- Output: prec_YYYY.NTT.nc, one file per year, 2016-2025 (10 files).
- Each output contains twelve monthly precipitation totals (120 months).
- Precipitation unit: mm per calendar month. No multiplication or division
  by 1,000 is applied. No spatial or temporal interpolation is performed.

QUALITY CHECK AND REPRODUCTION LIMITATIONS
------------------------------------------
- Confirm that cropped SST variables are named sst and rainfall variables
  are named prec, with lon/lat coordinates and the expected units.
- Confirm SST coverage: 118 of 120 months; missing October-November 2025.
- Confirm CHIRPS coverage: 120 of 120 months.
- MATLAB Step 02 loads the cropped outputs by their exact relative paths.
- Source data are not included in this repository. Full reconstruction from
  the raw observations requires separate access to the provider products,
  compatible GrADS software, and the same file naming conventions.
- The transition from Himawari-8 to Himawari-9 and product versions is
  documented but has not been independently validated for SST continuity.