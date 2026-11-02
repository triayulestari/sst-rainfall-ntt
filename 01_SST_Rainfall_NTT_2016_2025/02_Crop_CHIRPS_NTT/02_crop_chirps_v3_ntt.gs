* ============================================================
* 02_crop_chirps_v3_ntt.gs
* Study area: NTT context frame, 118-127.5 E, 11.5-7 S
* Expected working directory: 01_Preprocessing
* Raw: ../00_Raw_Data/CHIRPS_v3_Monthly_Global/
* Output (create first): ../02_Cropped_Data/CHIRPS_NTT/
* CHIRPS v3 monthly values are accumulated mm per calendar month.
* NO /1000 and NO *1000 conversion.
* No interpolation; missing/undefined values retained as missing.
* ============================================================

'reinit'
year = 2016
while (year <= 2025)
  infile = '../00_Raw_Data/CHIRPS_v3_Monthly_Global/chirps-v3.0.'%year'.monthly.nc'
  outfile = 'prec_'%year'.NTT.nc'

  'reinit'
  say 'Opening: '%infile
  'sdfopen 'infile
  if (rc = 0)
    'set lon 118 127.5'
    'set lat -11.5 -7'
    'set t 1 12'
    'define prec = precip'
    'set sdfattr prec String units mm'
    'set sdfattr prec String long_name Monthly_precipitation_total'
    'set sdfwrite -3dt 'outfile
    'sdfwrite prec'
    if (rc = 0)
      say 'Saved: '%outfile
    else
      say 'ERROR writing: '%outfile
    endif
  else
    say 'ERROR opening: '%infile
  endif
  year = year + 1
endwhile
say 'CHIRPS cropping loop completed.'
