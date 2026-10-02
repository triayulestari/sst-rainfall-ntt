%% =========================================================
% 01_Extract_Regional_Timeseries.m
%
% EXTRACT REGIONAL MONTHLY TIME SERIES
% Flores - Sumba - Timor
%
% Period : January 2016 - December 2025
%
% SST:
%   folder = ..\1a-SST_NTT\
%   unit   = degree C
%
% Rainfall:
%   folder = ..\1b-Precip_NTT\
%   original unit = mm/month
%   output unit   = mm/month
%
% Run this script from:
%   Data\3-Timeseries
%
% OUTPUT:
%   regional_timeseries_raw.mat
%   regional_timeseries_raw.csv
%   regional_grid_check.csv
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. FOLDERS
%% =========================================================

folder_sst  = '..\1a-SST_NTT\';
folder_prec = '..\1b-Precip_NTT\';

var_sst  = 'sst';
var_prec = 'prec';

years  = 2016:2025;
months = 1:12;

nYear  = length(years);
nMonth = length(months);

Ntime = nYear * nMonth;


%% =========================================================
% 2. TIME VECTOR
%% =========================================================

time = NaT(Ntime,1);

k = 0;

for yr = years
    for mon = months

        k = k + 1;

        time(k) = datetime(yr,mon,1);

    end
end


%% =========================================================
% 3. READ SST GRID
%% =========================================================

file_sst_sample = fullfile(...
    folder_sst,...
    'sst_201601.nc');

lon_sst = double(ncread(file_sst_sample,'lon'));
lat_sst = double(ncread(file_sst_sample,'lat'));

lon_sst = lon_sst(:);
lat_sst = lat_sst(:);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SST GRID INFORMATION\n')
fprintf('=========================================================\n')

fprintf('Longitude : %.3f to %.3f | %d points\n',...
    min(lon_sst),...
    max(lon_sst),...
    length(lon_sst));

fprintf('Latitude  : %.3f to %.3f | %d points\n',...
    min(lat_sst),...
    max(lat_sst),...
    length(lat_sst));


%% =========================================================
% 4. DEFINE SST REGIONAL BOXES
%% =========================================================

% ---------------------------------------------------------
% FLORES
% ---------------------------------------------------------

lon_F_sst_min = 119.0;
lon_F_sst_max = 123.5;

lat_F_sst_min = -9.2;
lat_F_sst_max = -7.9;


% ---------------------------------------------------------
% SUMBA
% ---------------------------------------------------------

lon_S_sst_min = 118.8;
lon_S_sst_max = 121.2;

lat_S_sst_min = -10.5;
lat_S_sst_max = -9.2;


% ---------------------------------------------------------
% TIMOR
% ---------------------------------------------------------

lon_T_sst_min = 123.3;
lon_T_sst_max = 126.0;

lat_T_sst_min = -10.6;
lat_T_sst_max = -8.6;


%% =========================================================
% 5. FIND SST GRID INDICES FROM COORDINATES
%
% Tolerance is used to avoid floating-point precision
% problems in NetCDF coordinates.
%% =========================================================

tol_sst = 1e-4;

% FLORES
idx_lon_F_sst = find(...
    lon_sst >= lon_F_sst_min - tol_sst & ...
    lon_sst <= lon_F_sst_max + tol_sst);

idx_lat_F_sst = find(...
    lat_sst >= lat_F_sst_min - tol_sst & ...
    lat_sst <= lat_F_sst_max + tol_sst);


% SUMBA
idx_lon_S_sst = find(...
    lon_sst >= lon_S_sst_min - tol_sst & ...
    lon_sst <= lon_S_sst_max + tol_sst);

idx_lat_S_sst = find(...
    lat_sst >= lat_S_sst_min - tol_sst & ...
    lat_sst <= lat_S_sst_max + tol_sst);


% TIMOR
idx_lon_T_sst = find(...
    lon_sst >= lon_T_sst_min - tol_sst & ...
    lon_sst <= lon_T_sst_max + tol_sst);

idx_lat_T_sst = find(...
    lat_sst >= lat_T_sst_min - tol_sst & ...
    lat_sst <= lat_T_sst_max + tol_sst);

%% =========================================================
% 6. CHECK ACTUAL SST BOXES
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ACTUAL SST BOXES SELECTED\n')
fprintf('=========================================================\n')


fprintf('\nFlores SST\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_sst(idx_lon_F_sst)),...
    max(lon_sst(idx_lon_F_sst)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_sst(idx_lat_F_sst)),...
    max(lat_sst(idx_lat_F_sst)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_F_sst),...
    length(idx_lat_F_sst),...
    length(idx_lon_F_sst)*length(idx_lat_F_sst));


fprintf('\nSumba SST\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_sst(idx_lon_S_sst)),...
    max(lon_sst(idx_lon_S_sst)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_sst(idx_lat_S_sst)),...
    max(lat_sst(idx_lat_S_sst)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_S_sst),...
    length(idx_lat_S_sst),...
    length(idx_lon_S_sst)*length(idx_lat_S_sst));


fprintf('\nTimor SST\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_sst(idx_lon_T_sst)),...
    max(lon_sst(idx_lon_T_sst)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_sst(idx_lat_T_sst)),...
    max(lat_sst(idx_lat_T_sst)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_T_sst),...
    length(idx_lat_T_sst),...
    length(idx_lon_T_sst)*length(idx_lat_T_sst));


%% =========================================================
% 7. PREALLOCATE SST TIME SERIES
%% =========================================================

sst_flores = NaN(Ntime,1);
sst_sumba  = NaN(Ntime,1);
sst_timor  = NaN(Ntime,1);

valid_sst_flores = NaN(Ntime,1);
valid_sst_sumba  = NaN(Ntime,1);
valid_sst_timor  = NaN(Ntime,1);


%% =========================================================
% 8. EXTRACT MONTHLY SST
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('EXTRACTING REGIONAL SST TIME SERIES\n')
fprintf('=========================================================\n')


k = 0;

for yr = years

    for mon = months

        k = k + 1;


        namefile = sprintf(...
            'sst_%d%02d.nc',...
            yr,...
            mon);

        file = fullfile(...
            folder_sst,...
            namefile);


        fprintf('%03d/120  %d-%02d : ',...
            k,...
            yr,...
            mon);


        %% -------------------------------------------------
        % Missing file
        %% -------------------------------------------------

        if ~isfile(file)

            fprintf('FILE MISSING -> NaN\n')

            continue

        end


        %% -------------------------------------------------
        % Read SST
        %% -------------------------------------------------

        sst = double(...
            ncread(...
            file,...
            var_sst));

        sst = squeeze(sst);


        %% Remove invalid/fill values
        sst(abs(sst) > 1000) = NaN;


        %% -------------------------------------------------
        % FLORES
        %% -------------------------------------------------

        flores = sst(...
            idx_lon_F_sst,...
            idx_lat_F_sst);

        sst_flores(k) = ...
            mean(...
            flores(:),...
            'omitnan');

        valid_sst_flores(k) = ...
            sum(~isnan(flores(:)));


        %% -------------------------------------------------
        % SUMBA
        %% -------------------------------------------------

        sumba = sst(...
            idx_lon_S_sst,...
            idx_lat_S_sst);

        sst_sumba(k) = ...
            mean(...
            sumba(:),...
            'omitnan');

        valid_sst_sumba(k) = ...
            sum(~isnan(sumba(:)));


        %% -------------------------------------------------
        % TIMOR
        %% -------------------------------------------------

        timor = sst(...
            idx_lon_T_sst,...
            idx_lat_T_sst);

        sst_timor(k) = ...
            mean(...
            timor(:),...
            'omitnan');

        valid_sst_timor(k) = ...
            sum(~isnan(timor(:)));


        fprintf(...
            'OK | F=%.2f  S=%.2f  T=%.2f C\n',...
            sst_flores(k),...
            sst_sumba(k),...
            sst_timor(k));

    end
end


%% =========================================================
% 9. READ RAINFALL GRID
%% =========================================================

file_prec_sample = fullfile(...
    folder_prec,...
    'prec_2016.NTT.nc');

lon_prec = double(...
    ncread(...
    file_prec_sample,...
    'lon'));

lat_prec = double(...
    ncread(...
    file_prec_sample,...
    'lat'));

lon_prec = lon_prec(:);
lat_prec = lat_prec(:);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('RAINFALL GRID INFORMATION\n')
fprintf('=========================================================\n')

fprintf('Longitude : %.3f to %.3f | %d points\n',...
    min(lon_prec),...
    max(lon_prec),...
    length(lon_prec));

fprintf('Latitude  : %.3f to %.3f | %d points\n',...
    min(lat_prec),...
    max(lat_prec),...
    length(lat_prec));


%% =========================================================
% 10. DEFINE RAINFALL REGIONAL BOXES
%% =========================================================

% ---------------------------------------------------------
% FLORES
% ---------------------------------------------------------

lon_F_prec_min = 118.975;
lon_F_prec_max = 123.525;

lat_F_prec_min = -9.225;
lat_F_prec_max = -7.875;


% ---------------------------------------------------------
% SUMBA
% ---------------------------------------------------------

lon_S_prec_min = 118.775;
lon_S_prec_max = 121.225;

lat_S_prec_min = -10.525;
lat_S_prec_max = -9.175;


% ---------------------------------------------------------
% TIMOR
% ---------------------------------------------------------

lon_T_prec_min = 123.275;
lon_T_prec_max = 126.025;

lat_T_prec_min = -10.625;
lat_T_prec_max = -8.575;


%% =========================================================
% 11. FIND RAINFALL GRID INDICES
%
% Tolerance avoids floating-point precision problems.
%% =========================================================

tol_prec = 1e-4;

% FLORES
idx_lon_F_prec = find(...
    lon_prec >= lon_F_prec_min - tol_prec & ...
    lon_prec <= lon_F_prec_max + tol_prec);

idx_lat_F_prec = find(...
    lat_prec >= lat_F_prec_min - tol_prec & ...
    lat_prec <= lat_F_prec_max + tol_prec);


% SUMBA
idx_lon_S_prec = find(...
    lon_prec >= lon_S_prec_min - tol_prec & ...
    lon_prec <= lon_S_prec_max + tol_prec);

idx_lat_S_prec = find(...
    lat_prec >= lat_S_prec_min - tol_prec & ...
    lat_prec <= lat_S_prec_max + tol_prec);


% TIMOR
idx_lon_T_prec = find(...
    lon_prec >= lon_T_prec_min - tol_prec & ...
    lon_prec <= lon_T_prec_max + tol_prec);

idx_lat_T_prec = find(...
    lat_prec >= lat_T_prec_min - tol_prec & ...
    lat_prec <= lat_T_prec_max + tol_prec);
%% =========================================================
% 12. CHECK ACTUAL RAINFALL BOXES
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ACTUAL RAINFALL BOXES SELECTED\n')
fprintf('=========================================================\n')


fprintf('\nFlores rainfall\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_prec(idx_lon_F_prec)),...
    max(lon_prec(idx_lon_F_prec)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_prec(idx_lat_F_prec)),...
    max(lat_prec(idx_lat_F_prec)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_F_prec),...
    length(idx_lat_F_prec),...
    length(idx_lon_F_prec)*length(idx_lat_F_prec));


fprintf('\nSumba rainfall\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_prec(idx_lon_S_prec)),...
    max(lon_prec(idx_lon_S_prec)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_prec(idx_lat_S_prec)),...
    max(lat_prec(idx_lat_S_prec)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_S_prec),...
    length(idx_lat_S_prec),...
    length(idx_lon_S_prec)*length(idx_lat_S_prec));


fprintf('\nTimor rainfall\n')
fprintf('Lon = %.3f to %.3f\n',...
    min(lon_prec(idx_lon_T_prec)),...
    max(lon_prec(idx_lon_T_prec)));

fprintf('Lat = %.3f to %.3f\n',...
    min(lat_prec(idx_lat_T_prec)),...
    max(lat_prec(idx_lat_T_prec)));

fprintf('Grid rectangle = %d x %d = %d cells\n',...
    length(idx_lon_T_prec),...
    length(idx_lat_T_prec),...
    length(idx_lon_T_prec)*length(idx_lat_T_prec));


%% =========================================================
% 13. PREALLOCATE RAINFALL TIME SERIES
%
% Final unit = mm/month
%% =========================================================

prec_flores = NaN(Ntime,1);
prec_sumba  = NaN(Ntime,1);
prec_timor  = NaN(Ntime,1);

valid_prec_flores = NaN(Ntime,1);
valid_prec_sumba  = NaN(Ntime,1);
valid_prec_timor  = NaN(Ntime,1);


%% =========================================================
% 14. EXTRACT MONTHLY RAINFALL
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('EXTRACTING REGIONAL RAINFALL TIME SERIES\n')
fprintf('OUTPUT UNIT = mm/month\n')
fprintf('=========================================================\n')


k = 0;

for yr = years

    namefile = sprintf(...
        'prec_%d.NTT.nc',...
        yr);

    file = fullfile(...
        folder_prec,...
        namefile);


    if ~isfile(file)

        warning(...
            'Rainfall file missing: %s',...
            namefile);

        k = k + 12;

        continue

    end


    for mon = months

        k = k + 1;


        fprintf('%03d/120  %d-%02d : ',...
            k,...
            yr,...
            mon);


        %% -------------------------------------------------
        % Read one monthly rainfall field
        %% -------------------------------------------------

        prec = double(...
            ncread(...
            file,...
            var_prec,...
            [1 1 mon],...
            [Inf Inf 1]));

        prec = squeeze(prec);


        %% Remove fill/invalid values
        prec(~isfinite(prec)) = NaN;
		prec(prec <= -9990) = NaN;

        %% -------------------------------------------------
        % FLORES
        %% -------------------------------------------------

        flores = prec(...
            idx_lon_F_prec,...
            idx_lat_F_prec);

        prec_flores(k) = ...
            mean(...
            flores(:),...
            'omitnan');

        valid_prec_flores(k) = ...
            sum(~isnan(flores(:)));


        %% -------------------------------------------------
        % SUMBA
        %% -------------------------------------------------

        sumba = prec(...
            idx_lon_S_prec,...
            idx_lat_S_prec);

        prec_sumba(k) = ...
            mean(...
            sumba(:),...
            'omitnan');

        valid_prec_sumba(k) = ...
            sum(~isnan(sumba(:)));


        %% -------------------------------------------------
        % TIMOR
        %% -------------------------------------------------

        timor = prec(...
            idx_lon_T_prec,...
            idx_lat_T_prec);

        prec_timor(k) = ...
            mean(...
            timor(:),...
            'omitnan');

        valid_prec_timor(k) = ...
            sum(~isnan(timor(:)));


        fprintf(...
            'OK | F=%.1f  S=%.1f  T=%.1f mm/month\n',...
            prec_flores(k),...
            prec_sumba(k),...
            prec_timor(k));

    end
end


%% =========================================================
% 15. FINAL DATA CHECK
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL TIME SERIES CHECK\n')
fprintf('=========================================================\n')


fprintf('\nNumber of months = %d\n',Ntime);


fprintf('\nSST valid months:\n')

fprintf('Flores = %d / %d\n',...
    sum(~isnan(sst_flores)),...
    Ntime);

fprintf('Sumba  = %d / %d\n',...
    sum(~isnan(sst_sumba)),...
    Ntime);

fprintf('Timor  = %d / %d\n',...
    sum(~isnan(sst_timor)),...
    Ntime);


fprintf('\nRainfall valid months:\n')

fprintf('Flores = %d / %d\n',...
    sum(~isnan(prec_flores)),...
    Ntime);

fprintf('Sumba  = %d / %d\n',...
    sum(~isnan(prec_sumba)),...
    Ntime);

fprintf('Timor  = %d / %d\n',...
    sum(~isnan(prec_timor)),...
    Ntime);


%% =========================================================
% 16. SPECIFIC CHECK:
% OCTOBER-NOVEMBER 2025 SST
%% =========================================================

idx_oct2025 = find(...
    year(time)==2025 &...
    month(time)==10);

idx_nov2025 = find(...
    year(time)==2025 &...
    month(time)==11);


fprintf('\n')
fprintf('2025 missing-SST check:\n')

fprintf('October 2025 Flores SST = %.3f\n',...
    sst_flores(idx_oct2025));

fprintf('November 2025 Flores SST = %.3f\n',...
    sst_flores(idx_nov2025));


%% =========================================================
% 17. CREATE OUTPUT TABLE
%% =========================================================

TS = table(...
    time,...
    sst_flores,...
    sst_sumba,...
    sst_timor,...
    prec_flores,...
    prec_sumba,...
    prec_timor,...
    'VariableNames',{...
    'Time',...
    'SST_Flores_C',...
    'SST_Sumba_C',...
    'SST_Timor_C',...
    'Rain_Flores_mm_month',...
    'Rain_Sumba_mm_month',...
    'Rain_Timor_mm_month'});


%% =========================================================
% 18. GRID CHECK TABLE
%% =========================================================

GridCheck = table(...
    time,...
    valid_sst_flores,...
    valid_sst_sumba,...
    valid_sst_timor,...
    valid_prec_flores,...
    valid_prec_sumba,...
    valid_prec_timor,...
    'VariableNames',{...
    'Time',...
    'Valid_SST_Flores',...
    'Valid_SST_Sumba',...
    'Valid_SST_Timor',...
    'Valid_Rain_Flores',...
    'Valid_Rain_Sumba',...
    'Valid_Rain_Timor'});


%% =========================================================
% 19. DISPLAY FIRST AND LAST ROWS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FIRST 6 MONTHS\n')
fprintf('=========================================================\n')

disp(TS(1:6,:))


fprintf('\n')
fprintf('=========================================================\n')
fprintf('LAST 6 MONTHS\n')
fprintf('=========================================================\n')

disp(TS(end-5:end,:))


%% =========================================================
% 20. SAVE MAT FILE
%% =========================================================

save(...
    'regional_timeseries_raw.mat',...
    'time',...
    'sst_flores',...
    'sst_sumba',...
    'sst_timor',...
    'prec_flores',...
    'prec_sumba',...
    'prec_timor',...
    'valid_sst_flores',...
    'valid_sst_sumba',...
    'valid_sst_timor',...
    'valid_prec_flores',...
    'valid_prec_sumba',...
    'valid_prec_timor',...
    'lon_sst',...
    'lat_sst',...
    'lon_prec',...
    'lat_prec',...
    'lon_F_sst_min',...
    'lon_F_sst_max',...
    'lat_F_sst_min',...
    'lat_F_sst_max',...
    'lon_S_sst_min',...
    'lon_S_sst_max',...
    'lat_S_sst_min',...
    'lat_S_sst_max',...
    'lon_T_sst_min',...
    'lon_T_sst_max',...
    'lat_T_sst_min',...
    'lat_T_sst_max',...
    'lon_F_prec_min',...
    'lon_F_prec_max',...
    'lat_F_prec_min',...
    'lat_F_prec_max',...
    'lon_S_prec_min',...
    'lon_S_prec_max',...
    'lat_S_prec_min',...
    'lat_S_prec_max',...
    'lon_T_prec_min',...
    'lon_T_prec_max',...
    'lat_T_prec_min',...
    'lat_T_prec_max');


%% =========================================================
% 21. SAVE CSV FILES
%% =========================================================

writetable(...
    TS,...
    'regional_timeseries_raw.csv');


writetable(...
    GridCheck,...
    'regional_grid_check.csv');

%% =========================================================
% VALID GRID SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID GRID CELL SUMMARY\n')
fprintf('=========================================================\n')

fprintf('\nSST\n')

fprintf('Flores : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_sst_flores,[],'omitnan'),...
    mean(valid_sst_flores,'omitnan'),...
    max(valid_sst_flores,[],'omitnan'));

fprintf('Sumba  : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_sst_sumba,[],'omitnan'),...
    mean(valid_sst_sumba,'omitnan'),...
    max(valid_sst_sumba,[],'omitnan'));

fprintf('Timor  : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_sst_timor,[],'omitnan'),...
    mean(valid_sst_timor,'omitnan'),...
    max(valid_sst_timor,[],'omitnan'));


fprintf('\nRAINFALL\n')

fprintf('Flores : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_prec_flores,[],'omitnan'),...
    mean(valid_prec_flores,'omitnan'),...
    max(valid_prec_flores,[],'omitnan'));

fprintf('Sumba  : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_prec_sumba,[],'omitnan'),...
    mean(valid_prec_sumba,'omitnan'),...
    max(valid_prec_sumba,[],'omitnan'));

fprintf('Timor  : min = %.0f | mean = %.1f | max = %.0f\n',...
    min(valid_prec_timor,[],'omitnan'),...
    mean(valid_prec_timor,'omitnan'),...
    max(valid_prec_timor,[],'omitnan'));

%% =========================================================
% 22. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('REGIONAL TIME SERIES EXTRACTION COMPLETED\n')
fprintf('=========================================================\n')

fprintf('\nFiles saved:\n')
fprintf('1. regional_timeseries_raw.mat\n')
fprintf('2. regional_timeseries_raw.csv\n')
fprintf('3. regional_grid_check.csv\n')

fprintf('\nUnits:\n')
fprintf('SST      = degree C\n')
fprintf('Rainfall = mm/month\n')

fprintf('\nIMPORTANT:\n')
fprintf('SST October-November 2025 should remain NaN.\n')
fprintf('Do not interpolate the missing SST months.\n')