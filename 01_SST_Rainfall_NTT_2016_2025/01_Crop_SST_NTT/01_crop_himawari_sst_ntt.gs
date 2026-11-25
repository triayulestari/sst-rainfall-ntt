* ============================================================
* 01_crop_himawari_sst_ntt.gs
*
* Monthly Himawari Sea Surface Temperature Preprocessing
* Study area : East Nusa Tenggara (NTT), Indonesia
* Period     : January 2016 - December 2025
*
* Input products:
* Himawari-8 L3 SST v2.0 : January 2016 - November 2022
* Himawari-9 L3 SST v2.1 : December 2022 - December 2025
*
* Missing data:
* October and November 2025 are excluded without interpolation.
*
* Geographic domain:
* Longitude : 118.0 to 127.5 degrees East
* Latitude  : -11.5 to -7.0 degrees North
*
* Spatial resolution: 0.02 degrees
* Output units      : degrees Celsius
*
* Working directory:
* 01_SST_Rainfall_NTT_2016_2025/01_Preprocessing/
*
* Input directory:
* ../00_Raw_Data/Himawari_SST_L3_FullDisk/
*
* Output directory:
* ../02_Cropped_Data/SST_NTT/
*
* ============================================================

'reinit'

input_dir  = '../00_Raw_Data/Himawari_SST_L3_FullDisk/'
output_dir = './'

n_saved   = 0
n_missing = 0
n_error   = 0

year = 2016
while (year <= 2025)
  month = 1
  while (month <= 12)

    if (month < 10)
      smonth = '0'%month
    else
      smonth = ''%month
    endif

    missing_month = 0
    if (year = 2025)
      if (month = 10 | month = 11)
        missing_month = 1
      endif
    endif

    if (missing_month = 1)
      say 'SKIP unavailable monthly SST: '%year%smonth
      n_missing = n_missing + 1
    else
      satellite = 'H08'
      product   = '1MSST200'

      if (year > 2022)
        satellite = 'H09'
        product   = '1MSST201'
      endif
      if (year = 2022 & month = 12)
        satellite = 'H09'
        product   = '1MSST201'
      endif

      infile  = input_dir%satellite'_'%year%smonth'01_0000_'%product'_FLDK.06001_06001.nc'
      outfile = output_dir'sst_'%year%smonth'.nc'

      'reinit'
      say 'Reading: '%infile
      'sdfopen 'infile

      if (rc = 0)
        'set lon 118 127.5'
        'set lat -11.5 -7'
        'set t 1'

* GrADS exposes the NetCDF SST variable as sea_surface_tem.
        'define sst = sea_surface_tem - 273.15'
        'set sdfattr sst String units degree_Celsius'
        'set sdfattr sst String long_name Sea_surface_temperature'
        'set sdfwrite -3dt 'outfile
        'sdfwrite sst'

        if (rc = 0)
          say 'Saved: '%outfile
          n_saved = n_saved + 1
        else
          say 'ERROR writing: '%outfile
          n_error = n_error + 1
        endif
      else
        say 'ERROR opening: '%infile
        n_error = n_error + 1
      endif
    endif

    month = month + 1
  endwhile
  year = year + 1
endwhile

say '========================================'
say 'Monthly Himawari SST preprocessing summary'
say 'Saved months      : '%n_saved
say 'Unavailable months: '%n_missing
say 'Errors            : '%n_error
say 'Expected: 118 saved, 2 unavailable, 0 errors.'
say '========================================'
