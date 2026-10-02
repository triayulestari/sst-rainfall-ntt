%%% =========================================================
% 01_Prepare_Spatial_Rainfall_Anomaly.m
%
% PREPARE GRIDDED MONTHLY RAINFALL ANOMALIES
% FOR SPATIAL SST-RAINFALL CORRELATION
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Period:
%   January 2016 - December 2025
%
% Input:
%   ..\1b-Precip_NTT\prec_YYYY.NTT.nc
%
% Variable:
%   prec
%
% Rainfall unit:
%   Raw file is treated consistently with the regional
%   extraction pipeline:
%
%       raw precipitation  = mm/month
%
% Deseasonalized anomaly:
%
%   P'(x,y,t) =
%       P(x,y,t) - monthly climatology(x,y,calendar month)
%
% Outputs:
%   spatial_rainfall_anomaly.mat
%   spatial_rainfall_grid_QC.csv
%   spatial_rainfall_monthly_QC.csv
%
% IMPORTANT:
%   1. No spatial interpolation.
%   2. No temporal interpolation.
%   3. Ocean/non-valid cells remain NaN.
%   4. Only grids valid throughout the analysis period
%      are retained in the final land mask.
%
% MATLAB R2021a
% No local functions are used.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. SETTINGS
%% =========================================================

data_folder = fullfile(...
    '..',...
    '1b-Precip_NTT');


years = 2016:2025;

nyear = length(years);

nmonth_total = nyear * 12;


%% =========================================================
% 2. DEFINE REGIONAL RAINFALL BOXES
%
% These are the SAME boxes used in the final
% regional rainfall extraction.
%% =========================================================

% ---------------------------------------------------------
% Flores
% ---------------------------------------------------------

lon_F_min = 118.975;
lon_F_max = 123.525;

lat_F_min = -9.225;
lat_F_max = -7.875;


% ---------------------------------------------------------
% Sumba
% ---------------------------------------------------------

lon_S_min = 118.775;
lon_S_max = 121.225;

lat_S_min = -10.525;
lat_S_max = -9.175;


% ---------------------------------------------------------
% Timor
% ---------------------------------------------------------

lon_T_min = 123.275;
lon_T_max = 126.025;

lat_T_min = -10.625;
lat_T_max = -8.575;


% Coordinate tolerance
tol = 1e-4;


%% =========================================================
% 3. CREATE MONTHLY TIME VECTOR
%% =========================================================

time = NaT(nmonth_total,1);

kk = 0;

for Y = years

    for M = 1:12

        kk = kk + 1;

        time(kk) = datetime(Y,M,1);

    end

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('PREPARE SPATIAL RAINFALL ANOMALY\n')
fprintf('=========================================================\n')

fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));

fprintf('Total months = %d\n',...
    length(time));


%% =========================================================
% 4. READ GRID COORDINATES FROM FIRST FILE
%% =========================================================

first_file = fullfile(...
    data_folder,...
    sprintf('prec_%d.NTT.nc',years(1)));


if ~exist(first_file,'file')

    error('First rainfall file was not found: %s',...
        first_file);

end


%% ---------------------------------------------------------
% Longitude
%% ---------------------------------------------------------

try

    lon = ncread(first_file,'lon');

catch

    lon = ncread(first_file,'longitude');

end


%% ---------------------------------------------------------
% Latitude
%% ---------------------------------------------------------

try

    lat = ncread(first_file,'lat');

catch

    lat = ncread(first_file,'latitude');

end


lon = double(lon(:));

lat = double(lat(:));


nlon = length(lon);
nlat = length(lat);


fprintf('\nFull rainfall grid:\n')
fprintf('Longitude points = %d\n',nlon);
fprintf('Latitude points  = %d\n',nlat);

fprintf('Longitude range  = %.3f to %.3f\n',...
    min(lon),max(lon));

fprintf('Latitude range   = %.3f to %.3f\n',...
    min(lat),max(lat));


%% =========================================================
% 5. SELECT REGIONAL GRID INDICES
%
% Tolerance avoids floating-point boundary omission.
%% =========================================================

idx_lon_F = find(...
    lon >= lon_F_min-tol & ...
    lon <= lon_F_max+tol);


idx_lat_F = find(...
    lat >= lat_F_min-tol & ...
    lat <= lat_F_max+tol);


idx_lon_S = find(...
    lon >= lon_S_min-tol & ...
    lon <= lon_S_max+tol);


idx_lat_S = find(...
    lat >= lat_S_min-tol & ...
    lat <= lat_S_max+tol);


idx_lon_T = find(...
    lon >= lon_T_min-tol & ...
    lon <= lon_T_max+tol);


idx_lat_T = find(...
    lat >= lat_T_min-tol & ...
    lat <= lat_T_max+tol);


%% =========================================================
% 6. REGIONAL COORDINATES
%% =========================================================

lon_F = lon(idx_lon_F);
lat_F = lat(idx_lat_F);

lon_S = lon(idx_lon_S);
lat_S = lat(idx_lat_S);

lon_T = lon(idx_lon_T);
lat_T = lat(idx_lat_T);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SELECTED REGIONAL RAINFALL GRIDS\n')
fprintf('=========================================================\n')


fprintf('\nFlores:\n')
fprintf('Lon = %.3f to %.3f | n = %d\n',...
    min(lon_F),max(lon_F),length(lon_F));

fprintf('Lat = %.3f to %.3f | n = %d\n',...
    min(lat_F),max(lat_F),length(lat_F));

fprintf('Rectangular grid cells = %d\n',...
    length(lon_F)*length(lat_F));


fprintf('\nSumba:\n')
fprintf('Lon = %.3f to %.3f | n = %d\n',...
    min(lon_S),max(lon_S),length(lon_S));

fprintf('Lat = %.3f to %.3f | n = %d\n',...
    min(lat_S),max(lat_S),length(lat_S));

fprintf('Rectangular grid cells = %d\n',...
    length(lon_S)*length(lat_S));


fprintf('\nTimor:\n')
fprintf('Lon = %.3f to %.3f | n = %d\n',...
    min(lon_T),max(lon_T),length(lon_T));

fprintf('Lat = %.3f to %.3f | n = %d\n',...
    min(lat_T),max(lat_T),length(lat_T));

fprintf('Rectangular grid cells = %d\n',...
    length(lon_T)*length(lat_T));


%% =========================================================
% 7. PREALLOCATE REGIONAL MONTHLY DATA
%
% Dimensions:
%
%   longitude x latitude x time
%% =========================================================

prec_F = NaN(...
    length(lon_F),...
    length(lat_F),...
    nmonth_total);


prec_S = NaN(...
    length(lon_S),...
    length(lat_S),...
    nmonth_total);


prec_T = NaN(...
    length(lon_T),...
    length(lat_T),...
    nmonth_total);


%% =========================================================
% 8. READ YEARLY RAINFALL FILES
%% =========================================================

month_counter = 0;


for iy = 1:nyear

    Y = years(iy);


    filename = fullfile(...
        data_folder,...
        sprintf('prec_%d.NTT.nc',Y));


    fprintf('\nReading %s\n',filename);


    if ~exist(filename,'file')

        error('Rainfall file not found: %s',...
            filename);

    end


    %% -----------------------------------------------------
    % Read precipitation
    %% -----------------------------------------------------

    P = ncread(filename,'prec');

    P = double(P);

    P = squeeze(P);


    %% -----------------------------------------------------
    % Check and correct dimension orientation if necessary
    %% -----------------------------------------------------

    sz = size(P);


    % Expected:
    % lon x lat x 12

    if length(sz) ~= 3

        error(...
            'Unexpected precipitation dimensions in %s',...
            filename);

    end


    if sz(1)==nlon && sz(2)==nlat

        % Already lon x lat x time
        % No action needed


    elseif sz(1)==nlat && sz(2)==nlon

        % lat x lon x time
        P = permute(P,[2 1 3]);


    elseif sz(2)==nlon && sz(3)==nlat

        % time x lon x lat
        P = permute(P,[2 3 1]);


    elseif sz(2)==nlat && sz(3)==nlon

        % time x lat x lon
        P = permute(P,[3 2 1]);


    elseif sz(1)==nlon && sz(3)==nlat

        % lon x time x lat
        P = permute(P,[1 3 2]);


    elseif sz(1)==nlat && sz(3)==nlon

        % lat x time x lon
        P = permute(P,[3 1 2]);


    else

        error(...
            'Cannot determine precipitation dimension order in %s',...
            filename);

    end


    %% -----------------------------------------------------
    % Final dimension check
    %% -----------------------------------------------------

    if size(P,1) ~= nlon || ...
       size(P,2) ~= nlat

        error(...
            'Rainfall grid dimensions do not match lon/lat.');

    end


    if size(P,3) ~= 12

        error(...
            'Expected 12 monthly slices in %s, found %d.',...
            filename,...
            size(P,3));

    end


    %% -----------------------------------------------------
    % Convert raw rainfall to mm/month
    %
    % IMPORTANT:
    % Same conversion as regional extraction.
    %% -----------------------------------------------------

    P = P * 1000;


    %% -----------------------------------------------------
    % Remove obviously invalid fill values if present
    %% -----------------------------------------------------

    P(abs(P) > 1e10) = NaN;


    %% -----------------------------------------------------
    % Extract regional boxes
    %% -----------------------------------------------------

    PF = P(...
        idx_lon_F,...
        idx_lat_F,...
        :);


    PS = P(...
        idx_lon_S,...
        idx_lat_S,...
        :);


    PT = P(...
        idx_lon_T,...
        idx_lat_T,...
        :);


    %% -----------------------------------------------------
    % Insert into 2016-2025 arrays
    %% -----------------------------------------------------

    month_idx = ...
        month_counter + (1:12);


    prec_F(:,:,month_idx) = PF;

    prec_S(:,:,month_idx) = PS;

    prec_T(:,:,month_idx) = PT;


    month_counter = ...
        month_counter + 12;


    fprintf('Completed %d\n',Y);

end


%% =========================================================
% 9. CHECK TOTAL TIME DIMENSION
%% =========================================================

if month_counter ~= 120

    error(...
        'Expected 120 monthly fields, found %d.',...
        month_counter);

end


%% =========================================================
% 10. MONTHLY VALID-GRID COUNTS
%% =========================================================

valid_count_F = NaN(120,1);
valid_count_S = NaN(120,1);
valid_count_T = NaN(120,1);


for t = 1:120

    temp = prec_F(:,:,t);
    valid_count_F(t) = sum(~isnan(temp(:)));


    temp = prec_S(:,:,t);
    valid_count_S(t) = sum(~isnan(temp(:)));


    temp = prec_T(:,:,t);
    valid_count_T(t) = sum(~isnan(temp(:)));

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY VALID RAINFALL GRID COUNTS\n')
fprintf('=========================================================\n')


fprintf('\nFlores:\n')
fprintf('Minimum = %d\n',min(valid_count_F));
fprintf('Mean    = %.1f\n',mean(valid_count_F));
fprintf('Maximum = %d\n',max(valid_count_F));


fprintf('\nSumba:\n')
fprintf('Minimum = %d\n',min(valid_count_S));
fprintf('Mean    = %.1f\n',mean(valid_count_S));
fprintf('Maximum = %d\n',max(valid_count_S));


fprintf('\nTimor:\n')
fprintf('Minimum = %d\n',min(valid_count_T));
fprintf('Mean    = %.1f\n',mean(valid_count_T));
fprintf('Maximum = %d\n',max(valid_count_T));


%% =========================================================
% 11. CREATE STABLE VALID-LAND MASK
%
% A grid is retained only if rainfall exists for
% ALL 120 months.
%% =========================================================

mask_F = all(~isnan(prec_F),3);

mask_S = all(~isnan(prec_S),3);

mask_T = all(~isnan(prec_T),3);


nmask_F = sum(mask_F(:));
nmask_S = sum(mask_S(:));
nmask_T = sum(mask_T(:));


fprintf('\n')
fprintf('=========================================================\n')
fprintf('STABLE VALID LAND MASK\n')
fprintf('=========================================================\n')

fprintf('Flores = %d valid grids\n',nmask_F);
fprintf('Sumba  = %d valid grids\n',nmask_S);
fprintf('Timor  = %d valid grids\n',nmask_T);


%% =========================================================
% 12. CHECK AGAINST EXPECTED FINAL GRID COUNTS
%% =========================================================

expected_F = 1158;
expected_S = 565;
expected_T = 1088;


fprintf('\nExpected from regional extraction:\n')
fprintf('Flores = %d\n',expected_F);
fprintf('Sumba  = %d\n',expected_S);
fprintf('Timor  = %d\n',expected_T);


if nmask_F ~= expected_F

    warning(...
        'Flores valid-grid count differs from expected 1158.');

end


if nmask_S ~= expected_S

    warning(...
        'Sumba valid-grid count differs from expected 565.');

end


if nmask_T ~= expected_T

    warning(...
        'Timor valid-grid count differs from expected 1088.');

end


%% =========================================================
% 13. APPLY STABLE MASK TO RAW DATA
%% =========================================================

for t = 1:120

    temp = prec_F(:,:,t);
    temp(~mask_F) = NaN;
    prec_F(:,:,t) = temp;


    temp = prec_S(:,:,t);
    temp(~mask_S) = NaN;
    prec_S(:,:,t) = temp;


    temp = prec_T(:,:,t);
    temp(~mask_T) = NaN;
    prec_T(:,:,t) = temp;

end


%% =========================================================
% 14. PREALLOCATE MONTHLY CLIMATOLOGY
%
% Dimensions:
% lon x lat x calendar month
%% =========================================================

clim_F = NaN(...
    length(lon_F),...
    length(lat_F),...
    12);


clim_S = NaN(...
    length(lon_S),...
    length(lat_S),...
    12);


clim_T = NaN(...
    length(lon_T),...
    length(lat_T),...
    12);


%% =========================================================
% 15. CALCULATE GRIDDED MONTHLY CLIMATOLOGY
%
% Each calendar month has 10 years:
%
% January climatology = mean(Jan 2016 ... Jan 2025)
% ...
% December climatology = mean(Dec 2016 ... Dec 2025)
%% =========================================================

month_number = month(time);


for M = 1:12

    idx = ...
        month_number == M;


    clim_F(:,:,M) = ...
        mean(prec_F(:,:,idx),3,'omitnan');


    clim_S(:,:,M) = ...
        mean(prec_S(:,:,idx),3,'omitnan');


    clim_T(:,:,M) = ...
        mean(prec_T(:,:,idx),3,'omitnan');

end


%% =========================================================
% 16. CALCULATE DESEASONALIZED GRIDDED ANOMALIES
%% =========================================================

anom_F = NaN(size(prec_F));

anom_S = NaN(size(prec_S));

anom_T = NaN(size(prec_T));


for t = 1:120

    M = month_number(t);


    anom_F(:,:,t) = ...
        prec_F(:,:,t) - clim_F(:,:,M);


    anom_S(:,:,t) = ...
        prec_S(:,:,t) - clim_S(:,:,M);


    anom_T(:,:,t) = ...
        prec_T(:,:,t) - clim_T(:,:,M);

end


%% =========================================================
% 17. REAPPLY MASK TO ANOMALIES
%% =========================================================

for t = 1:120

    temp = anom_F(:,:,t);
    temp(~mask_F) = NaN;
    anom_F(:,:,t) = temp;


    temp = anom_S(:,:,t);
    temp(~mask_S) = NaN;
    anom_S(:,:,t) = temp;


    temp = anom_T(:,:,t);
    temp(~mask_T) = NaN;
    anom_T(:,:,t) = temp;

end


%% =========================================================
% 18. MONTHLY DESEASONALIZATION QC
%
% For each calendar month:
%
% Mean anomaly across the 10 years should be
% approximately zero at every retained grid.
%% =========================================================

QC_max_abs_F = NaN(12,1);
QC_max_abs_S = NaN(12,1);
QC_max_abs_T = NaN(12,1);


for M = 1:12

    idx = ...
        month_number == M;


    %% Flores

    temp = ...
        mean(anom_F(:,:,idx),3,'omitnan');

    values = ...
        abs(temp(mask_F));

    QC_max_abs_F(M) = ...
        max(values);


    %% Sumba

    temp = ...
        mean(anom_S(:,:,idx),3,'omitnan');

    values = ...
        abs(temp(mask_S));

    QC_max_abs_S(M) = ...
        max(values);


    %% Timor

    temp = ...
        mean(anom_T(:,:,idx),3,'omitnan');

    values = ...
        abs(temp(mask_T));

    QC_max_abs_T(M) = ...
        max(values);

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZATION QC\n')
fprintf('Maximum absolute calendar-month mean anomaly\n')
fprintf('=========================================================\n')


fprintf('\nMonth    Flores        Sumba         Timor\n')
fprintf('-----------------------------------------------\n')


month_names = {...
    'Jan';'Feb';'Mar';'Apr';...
    'May';'Jun';'Jul';'Aug';...
    'Sep';'Oct';'Nov';'Dec'};


for M = 1:12

    fprintf('%s     %.10f   %.10f   %.10f\n',...
        month_names{M},...
        QC_max_abs_F(M),...
        QC_max_abs_S(M),...
        QC_max_abs_T(M));

end


%% =========================================================
% 19. OVERALL QC
%% =========================================================

max_QC_F = max(QC_max_abs_F);
max_QC_S = max(QC_max_abs_S);
max_QC_T = max(QC_max_abs_T);


fprintf('\nMaximum QC residual:\n')

fprintf('Flores = %.12f mm/month\n',...
    max_QC_F);

fprintf('Sumba  = %.12f mm/month\n',...
    max_QC_S);

fprintf('Timor  = %.12f mm/month\n',...
    max_QC_T);


%% =========================================================
% 20. ANOMALY RANGE QC
%% =========================================================

values = anom_F(mask_F);
% Above indexing only sees first two dimensions incorrectly,
% therefore calculate through full vector + repeated mask below.


mask3_F = repmat(mask_F,[1 1 120]);
mask3_S = repmat(mask_S,[1 1 120]);
mask3_T = repmat(mask_T,[1 1 120]);


values_F = anom_F(mask3_F);
values_S = anom_S(mask3_S);
values_T = anom_T(mask3_T);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('RAINFALL ANOMALY RANGE\n')
fprintf('=========================================================\n')


fprintf('Flores : %.2f to %.2f mm/month\n',...
    min(values_F),...
    max(values_F));


fprintf('Sumba  : %.2f to %.2f mm/month\n',...
    min(values_S),...
    max(values_S));


fprintf('Timor  : %.2f to %.2f mm/month\n',...
    min(values_T),...
    max(values_T));


%% =========================================================
% 21. CREATE GRID QC TABLE
%% =========================================================

Region = {...
    'Flores';...
    'Sumba';...
    'Timor'};


N_lon = [...
    length(lon_F);...
    length(lon_S);...
    length(lon_T)];


N_lat = [...
    length(lat_F);...
    length(lat_S);...
    length(lat_T)];


Rectangle_cells = [...
    length(lon_F)*length(lat_F);...
    length(lon_S)*length(lat_S);...
    length(lon_T)*length(lat_T)];


Valid_land_grids = [...
    nmask_F;...
    nmask_S;...
    nmask_T];


Expected_valid_grids = [...
    expected_F;...
    expected_S;...
    expected_T];


Min_monthly_valid = [...
    min(valid_count_F);...
    min(valid_count_S);...
    min(valid_count_T)];


Max_monthly_valid = [...
    max(valid_count_F);...
    max(valid_count_S);...
    max(valid_count_T)];


GridQCTable = table(...
    Region,...
    N_lon,...
    N_lat,...
    Rectangle_cells,...
    Valid_land_grids,...
    Expected_valid_grids,...
    Min_monthly_valid,...
    Max_monthly_valid);


%% =========================================================
% 22. CREATE MONTHLY QC TABLE
%% =========================================================

Month = month_names;


MaxAbsMeanAnom_Flores = ...
    QC_max_abs_F;


MaxAbsMeanAnom_Sumba = ...
    QC_max_abs_S;


MaxAbsMeanAnom_Timor = ...
    QC_max_abs_T;


MonthlyQCTable = table(...
    Month,...
    MaxAbsMeanAnom_Flores,...
    MaxAbsMeanAnom_Sumba,...
    MaxAbsMeanAnom_Timor);


%% =========================================================
% 23. DISPLAY GRID QC TABLE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL GRID QC TABLE\n')
fprintf('=========================================================\n')

disp(GridQCTable)


%% =========================================================
% 24. SAVE MAT FILE
%% =========================================================

save(...
    'spatial_rainfall_anomaly.mat',...
    'time',...
    'lon_F','lat_F',...
    'lon_S','lat_S',...
    'lon_T','lat_T',...
    'prec_F','prec_S','prec_T',...
    'clim_F','clim_S','clim_T',...
    'anom_F','anom_S','anom_T',...
    'mask_F','mask_S','mask_T',...
    'nmask_F','nmask_S','nmask_T',...
    'valid_count_F',...
    'valid_count_S',...
    'valid_count_T',...
    'GridQCTable',...
    'MonthlyQCTable',...
    '-v7.3');


%% =========================================================
% 25. SAVE CSV QC FILES
%% =========================================================

writetable(...
    GridQCTable,...
    'spatial_rainfall_grid_QC.csv');


writetable(...
    MonthlyQCTable,...
    'spatial_rainfall_monthly_QC.csv');


%% =========================================================
% 26. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SPATIAL RAINFALL ANOMALY PREPARATION COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n')

fprintf('1. spatial_rainfall_anomaly.mat\n')
fprintf('2. spatial_rainfall_grid_QC.csv\n')
fprintf('3. spatial_rainfall_monthly_QC.csv\n')


fprintf('\nExpected final valid-grid counts:\n')
fprintf('Flores = 1158\n')
fprintf('Sumba  = 565\n')
fprintf('Timor  = 1088\n')


fprintf('\nExpected deseasonalization QC:\n')
fprintf(['Calendar-month mean anomalies should be ',...
         'approximately zero.\n']);


fprintf('\nNext step:\n')
fprintf(['02_Spatial_Correlation_FDR.m will correlate ',...
         'regional SST anomalies with rainfall anomalies ',...
         'at every valid land grid.\n']);