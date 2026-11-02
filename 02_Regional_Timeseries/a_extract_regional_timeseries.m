%% ========================================================================
% 01_extract_regional_timeseries.m
% REGIONAL SST AND RAINFALL MONTHLY TIME SERIES | NTT 2016-2025
%
% MATLAB R2021a
% Run this script from ANY MATLAB working directory.
% Save this script in:
%   Data/02_Regional_Timeseries/
%
% Inputs (inside the sibling crop-project folder):
%   ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_YYYYMM.nc
%   ../01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
%
% Outputs (saved next to THIS script):
%   regional_timeseries_raw.mat
%   regional_timeseries_raw.csv
%   regional_grid_check.csv
%   regional_domain_grid_metadata.csv
%   regional_data_availability.csv
%
% Important:
%   - Rectangular regions are the SAME as in the previous analysis.
%   - No coastline polygon, administrative mask, interpolation, or weighting.
%   - Means use FINITE (non-NaN) cells in each region and each month.
%   - SST is already degree Celsius; precipitation is already mm/month.
%   - NO *1000 or /1000 conversion is performed.
%   - Missing SST October-November 2025 remains NaN in the 120-month series.
%   - A regional CHIRPS rectangle can include neighboring land, including
%     part of Timor-Leste; it is NOT equivalent to an NTT administrative mask.
%% ========================================================================

clc;
clear;

%% 1. Working paths (relative to the location of this .m file)
script_path = mfilename('fullpath');
if isempty(script_path)
    error('Save the .m script as a file before running it.');
end
folder_out = fileparts(script_path);
folder_data = fileparts(folder_out);
folder_crops = fullfile(folder_data, '01_SST_Rainfall_NTT_2016_2025');
folder_sst  = fullfile(folder_crops, '01_Crop_SST_NTT');
folder_prec = fullfile(folder_crops, '02_Crop_CHIRPS_NTT');

if ~isfolder(folder_sst)
    error('SST cropped-data folder not found: %s', folder_sst);
end
if ~isfolder(folder_prec)
    error('CHIRPS cropped-data folder not found: %s', folder_prec);
end

fprintf('\n===== REGIONAL EXTRACTION 2016-2025 =====\n');
fprintf('SST directory    : %s\n',folder_sst);
fprintf('CHIRPS directory : %s\n',folder_prec);
fprintf('Output directory : %s\n',folder_out);

%% 2. Input samples and metadata/units
sst_sample  = fullfile(folder_sst,  'sst_201601.nc');
prec_sample = fullfile(folder_prec, 'prec_2016.NTT.nc');
if ~isfile(sst_sample) || ~isfile(prec_sample)
    error('Sample NetCDF files not found. Check filenames in crop folders.');
end

sst_unit  = char(ncreadatt(sst_sample,'sst','units'));
prec_unit = char(ncreadatt(prec_sample,'prec','units'));
if ~contains(lower(sst_unit),'celsius')
    error('Expected SST in Celsius; metadata says: %s',sst_unit);
end
if ~strcmpi(strtrim(prec_unit),'mm')
    error('Expected monthly rainfall totals in mm; metadata says: %s',prec_unit);
end

lon_sst = double(ncread(sst_sample,'lon')); lon_sst = lon_sst(:);
lat_sst = double(ncread(sst_sample,'lat')); lat_sst = lat_sst(:);
lon_prec = double(ncread(prec_sample,'lon')); lon_prec = lon_prec(:);
lat_prec = double(ncread(prec_sample,'lat')); lat_prec = lat_prec(:);

fprintf('\nSST grid: %d lon x %d lat; units = %s\n', ...
    numel(lon_sst),numel(lat_sst),sst_unit);
fprintf('CHIRPS grid: %d lon x %d lat; units = %s (monthly total)\n', ...
    numel(lon_prec),numel(lat_prec),prec_unit);

%% 3. Define geographical rectangles (WGS84 degrees)
% Region order: Flores, Sumba, Timor.
regions = {'Flores';'Sumba';'Timor'};

% Columns: lon_min, lon_max, lat_min, lat_max.
% Original marine SST boxes: retained to compare with previous publication.
sst_boxes = [ ...
    119.0  123.5  -9.2  -7.9;  ... % Flores
    118.8  121.2 -10.5  -9.2;  ... % Sumba
    123.3  126.0 -10.6  -8.6];     % Timor

% CHIRPS boxes have half-grid margins matching the previous regional study.
prec_boxes = [ ...
    118.975 123.525  -9.225 -7.875; ... % Flores
    118.775 121.225 -10.525 -9.175; ... % Sumba
    123.275 126.025 -10.625 -8.575];    % Timor

tol = 1e-4;
sst_ix = cell(3,1); sst_iy = cell(3,1);
prec_ix = cell(3,1); prec_iy = cell(3,1);
for r = 1:3
    sst_ix{r} = find(lon_sst >= sst_boxes(r,1)-tol & lon_sst <= sst_boxes(r,2)+tol);
    sst_iy{r} = find(lat_sst >= sst_boxes(r,3)-tol & lat_sst <= sst_boxes(r,4)+tol);
    prec_ix{r} = find(lon_prec >= prec_boxes(r,1)-tol & lon_prec <= prec_boxes(r,2)+tol);
    prec_iy{r} = find(lat_prec >= prec_boxes(r,3)-tol & lat_prec <= prec_boxes(r,4)+tol);
    if isempty(sst_ix{r}) || isempty(sst_iy{r}) || ...
       isempty(prec_ix{r}) || isempty(prec_iy{r})
        error('Empty selection for region: %s. Check crop bounds.',regions{r});
    end
    fprintf('\n%s: SST rectangle = %d x %d; CHIRPS rectangle = %d x %d cells\n', ...
        regions{r},numel(sst_ix{r}),numel(sst_iy{r}), ...
        numel(prec_ix{r}),numel(prec_iy{r}));
end

%% 4. Common calendar: 120 actual month positions
nMonths = 120;
time = datetime(2016,1,1) + calmonths((0:nMonths-1)');
SST  = NaN(nMonths,3);
RAIN = NaN(nMonths,3);
ValidSST  = zeros(nMonths,3);
ValidRAIN = zeros(nMonths,3);
SSTfilePresent = false(nMonths,1);
RAINfilePresent = false(nMonths,1);

%% 5. SST extraction (one file per available month)
fprintf('\n===== READING MONTHLY SST (Celsius) =====\n');
for k = 1:nMonths
    yr = year(time(k)); mo = month(time(k));
    filename = sprintf('sst_%04d%02d.nc',yr,mo);
    inputfile = fullfile(folder_sst, filename);
    expectedMissing = (yr == 2025 && (mo == 10 || mo == 11));

    if ~isfile(inputfile)
        if expectedMissing
            fprintf('%s: missing SST as expected -> NaN\n',datestr(time(k),'yyyy-mm'));
            continue;
        else
            error('UNEXPECTED missing SST file: %s',inputfile);
        end
    end
    if expectedMissing
        error('Unexpected SST file for an intentionally missing month: %s',inputfile);
    end

    SSTfilePresent(k) = true;
    A = double(ncread(inputfile,'sst'));
    if size(A,1) ~= numel(lon_sst) || size(A,2) ~= numel(lat_sst)
        error('SST grid shape mismatch: %s',filename);
    end
    A = A(:,:,1);
    A(~isfinite(A) | abs(A) > 1e7) = NaN; % protect against NetCDF fill values

    for r = 1:3
        piece = A(sst_ix{r},sst_iy{r});
        vals = piece(isfinite(piece));
        ValidSST(k,r) = numel(vals);
        if ~isempty(vals)
            SST(k,r) = mean(vals);           % arithmetic, NOT area weighted
        end
    end
    fprintf('%s: SST  F=%6.2f  S=%6.2f  T=%6.2f C\n', ...
        datestr(time(k),'yyyy-mm'),SST(k,1),SST(k,2),SST(k,3));
end

%% 6. CHIRPS extraction (12 months in each annual file)
fprintf('\n===== READING CHIRPS MONTHLY TOTALS (mm/month) =====\n');
for yr = 2016:2025
    filename = sprintf('prec_%04d.NTT.nc',yr);
    inputfile = fullfile(folder_prec,filename);
    if ~isfile(inputfile)
        error('Missing annual CHIRPS file: %s',inputfile);
    end
    info = ncinfo(inputfile,'prec');
    if numel(info.Size) < 3 || info.Size(3) ~= 12 || ...
       info.Size(1) ~= numel(lon_prec) || info.Size(2) ~= numel(lat_prec)
        error('Unexpected CHIRPS shape (need lon x lat x 12): %s',filename);
    end
    if ~strcmpi(strtrim(char(ncreadatt(inputfile,'prec','units'))),'mm')
        error('CHIRPS units changed in %s; conversion not implemented.',filename);
    end

    for mo = 1:12
        k = (yr-2016)*12 + mo;
        A = double(ncread(inputfile,'prec',[1 1 mo],[Inf Inf 1]));
        A = A(:,:,1);
        A(~isfinite(A) | abs(A)>1e7) = NaN;  % protect against fill values
        % Rainfall should not be negative; flag unexpected data rather than
        % silently applying additional conversions or corrections.
        if any(A(isfinite(A)) < 0)
            error('Negative valid CHIRPS value in %s month %02d',filename,mo);
        end
        RAINfilePresent(k) = true;
        for r = 1:3
            piece = A(prec_ix{r},prec_iy{r});
            vals = piece(isfinite(piece));
            ValidRAIN(k,r) = numel(vals);
            if ~isempty(vals)
                RAIN(k,r) = mean(vals);      % already monthly mm, NO *1000
            end
        end
        fprintf('%04d-%02d: RAIN F=%7.2f S=%7.2f T=%7.2f mm/month\n', ...
            yr,mo,RAIN(k,1),RAIN(k,2),RAIN(k,3));
    end
end

%% 7. Basic quality control
if sum(SSTfilePresent) ~= 118 || sum(RAINfilePresent) ~= 120
    error('Expected 118 SST monthly files and 120 rainfall months.');
end
if any(ValidSST(SSTfilePresent,:) == 0,'all') || any(ValidRAIN(:) == 0)
    error('At least one available time/region has no valid grid values.');
end
if any(SST(isfinite(SST)) < -2.5) || any(SST(isfinite(SST)) > 45)
    warning('SST values outside expected oceanographic range; verify units.');
end
missingRows = (year(time)==2025 & (month(time)==10 | month(time)==11));
if ~all(all(isnan(SST(missingRows,:)))) || any(isnan(RAIN(missingRows,:)),'all')
    error('October-November 2025 missing-month handling failed.');
end

fprintf('\n===== FINAL QC =====\n');
for r = 1:3
    fprintf('%s: SST valid months = %d; RAIN valid months = %d\n', ...
        regions{r},sum(isfinite(SST(:,r))),sum(isfinite(RAIN(:,r))));
end

%% 8. Named vectors for compatibility with following steps
sst_flores = SST(:,1); sst_sumba = SST(:,2); sst_timor = SST(:,3);
prec_flores = RAIN(:,1); prec_sumba = RAIN(:,2); prec_timor = RAIN(:,3);
valid_sst_flores = ValidSST(:,1);
valid_sst_sumba = ValidSST(:,2);
valid_sst_timor = ValidSST(:,3);
valid_prec_flores = ValidRAIN(:,1);
valid_prec_sumba = ValidRAIN(:,2);
valid_prec_timor = ValidRAIN(:,3);

%% 9. Output: raw time series, grid coverage, geographic metadata
TS = table(time,sst_flores,sst_sumba,sst_timor, ...
    prec_flores,prec_sumba,prec_timor, ...
    'VariableNames',{'Time','SST_Flores_C','SST_Sumba_C','SST_Timor_C', ...
    'Rain_Flores_mm_month','Rain_Sumba_mm_month','Rain_Timor_mm_month'});

GridCheck = table(time,valid_sst_flores,valid_sst_sumba,valid_sst_timor, ...
    valid_prec_flores,valid_prec_sumba,valid_prec_timor, ...
    'VariableNames',{'Time','Valid_SST_Flores','Valid_SST_Sumba', ...
    'Valid_SST_Timor','Valid_Rain_Flores','Valid_Rain_Sumba','Valid_Rain_Timor'});

Avail = table(time,SSTfilePresent,RAINfilePresent, ...
    'VariableNames',{'Time','SST_File_Present','CHIRPS_Month_Present'});

Product = [repmat({'SST_Himawari'},3,1);repmat({'Rain_CHIRPS'},3,1)];
Region = [regions;regions];
Requested = [sst_boxes;prec_boxes];
Actual = NaN(6,4);
Grid_cells_rectangle = zeros(6,1);
for r = 1:3
    Actual(r,:) = [min(lon_sst(sst_ix{r})), max(lon_sst(sst_ix{r})), ...
                   min(lat_sst(sst_iy{r})), max(lat_sst(sst_iy{r}))];
    Actual(r+3,:) = [min(lon_prec(prec_ix{r})), max(lon_prec(prec_ix{r})), ...
                     min(lat_prec(prec_iy{r})), max(lat_prec(prec_iy{r}))];
    Grid_cells_rectangle(r) = numel(sst_ix{r})*numel(sst_iy{r});
    Grid_cells_rectangle(r+3) = numel(prec_ix{r})*numel(prec_iy{r});
end
Domains = table(Product,Region,Requested(:,1),Requested(:,2), ...
    Requested(:,3),Requested(:,4),Actual(:,1),Actual(:,2), ...
    Actual(:,3),Actual(:,4),Grid_cells_rectangle, ...
    'VariableNames',{'Product','Region','Requested_Lon_Min','Requested_Lon_Max', ...
    'Requested_Lat_Min','Requested_Lat_Max','Actual_Lon_Min', ...
    'Actual_Lon_Max','Actual_Lat_Min','Actual_Lat_Max','Box_Grid_Count'});

writetable(TS,fullfile(folder_out,'regional_timeseries_raw.csv'));
writetable(GridCheck,fullfile(folder_out,'regional_grid_check.csv'));
writetable(Domains,fullfile(folder_out,'regional_domain_grid_metadata.csv'));
writetable(Avail,fullfile(folder_out,'regional_data_availability.csv'));
save(fullfile(folder_out,'regional_timeseries_raw.mat'), ...
    'time','sst_flores','sst_sumba','sst_timor', ...
    'prec_flores','prec_sumba','prec_timor', ...
    'valid_sst_flores','valid_sst_sumba','valid_sst_timor', ...
    'valid_prec_flores','valid_prec_sumba','valid_prec_timor', ...
    'lon_sst','lat_sst','lon_prec','lat_prec', ...
    'sst_boxes','prec_boxes','SSTfilePresent','RAINfilePresent');

fprintf('\nDONE. Outputs saved to: %s\n',folder_out);
fprintf('Next step: QC the regional means before computing anomalies.\n');
