%% ========================================================================
% a_prepare_spatial_rainfall_anomalies.m
% SPATIAL CHIRPS RAINFALL ANOMALIES | NTT, January 2016-December 2025
%
% MATLAB R2021a
% Save this script in Data/05_Spatial_Analysis/ and press Run (F5).
%
% Inputs:
%   ../01_SST_Rainfall_NTT_2016_2025/02_Crop_CHIRPS_NTT/prec_YYYY.NTT.nc
%   ../02_Regional_Timeseries/regional_anomalies.mat
%
% Outputs, all saved beside this script:
%   spatial_rainfall_anomaly.mat
%   spatial_rainfall_grid_QC.csv
%   spatial_rainfall_monthly_QC.csv
%   spatial_valid_grid_mask.csv
%
% IMPORTANT METHOD AND UNIT DEFINITIONS
%  - CHIRPS monthly total is ALREADY in mm (mm/month at monthly scale).
%    NO division or multiplication by 1000 is applied anywhere here.
%  - Rectangular geographic selection, not administrative/coastline polygons.
%  - A valid-data mask retains only grid cells with finite rainfall in ALL
%    120 calendar months: mask = all(isfinite(precipitation),3).
%  - No spatial/temporal interpolation; no area weighting.
%  - Rainfall anomaly = value - 2016-2025 mean for SAME calendar month,
%    independently at each grid. This is DESEASONALIZATION, not subtraction
%    of the overall 10-year mean.
%  - The Timor box can include grid cells in Timor-Leste.
%  - CHIRPS v3 land-only grid may not align exactly with plotted coastlines.
%% ========================================================================
clc;
clear;

%% 1. Resolve data folders independently of MATLAB Current Folder
script_path = mfilename('fullpath');
if isempty(script_path)
    error('Save this script as a_prepare_spatial_rainfall_anomalies.m first.');
end
out_dir = fileparts(script_path);
data_dir = fileparts(out_dir);
prec_dir = fullfile(data_dir,'01_SST_Rainfall_NTT_2016_2025', ...
    '02_Crop_CHIRPS_NTT');
reg_file = fullfile(data_dir,'02_Regional_Timeseries', ...
    'regional_anomalies.mat');
if ~isfolder(prec_dir) || ~isfile(reg_file)
    error('Missing CHIRPS folder or regional_anomalies.mat. Check folder layout.');
end

D = load(reg_file,'time','RAIN');
if ~isfield(D,'time') || ~isfield(D,'RAIN') || ...
        ~isdatetime(D.time) || ~isequal(size(D.RAIN),[120 3])
    error('Regional MAT must contain datetime time and RAIN [120 x 3].');
end
time = D.time(:);
expected_time = datetime(2016,1,1) + calmonths((0:119)');
if ~all(time == expected_time)
    error('Regional data must use all 120 calendar positions, Jan 2016-Dec 2025.');
end

%% 2. Read coordinates / verify native CHIRPS monthly units
sample_file = fullfile(prec_dir,'prec_2016.NTT.nc');
if ~isfile(sample_file)
    error('CHIRPS crop missing: %s',sample_file);
end
units = char(ncreadatt(sample_file,'prec','units'));
if ~strcmpi(strtrim(units),'mm')
    error('Expected CHIRPS monthly totals in mm, got "%s".',units);
end
lon = double(ncread(sample_file,'lon')); lon = lon(:);
lat = double(ncread(sample_file,'lat')); lat = lat(:);
nlon = numel(lon); nlat = numel(lat);
if nlon~=192 || nlat~=92
    warning('CHIRPS crop has %d x %d grid, instead of previous 192 x 92.',nlon,nlat);
end

%% 3. SAME CHIRPS rectangles as regional extraction (WGS84 decimal degrees)
regions = {'Flores';'Sumba';'Timor'};
% lon_min lon_max lat_min lat_max
boxes = [ ...
    118.975 123.525  -9.225  -7.875; ... % Flores
    118.775 121.225 -10.525  -9.175; ... % Sumba
    123.275 126.025 -10.625  -8.575];    % Timor
idx_lon = cell(3,1);
idx_lat = cell(3,1);
rlon = cell(3,1);
rlat = cell(3,1);
R = cell(3,1);
monthly_valid = NaN(120,3);
regional_check = NaN(120,3);
tol = 1e-4;
for ir = 1:3
    idx_lon{ir} = find(lon >= boxes(ir,1)-tol & lon <= boxes(ir,2)+tol);
    idx_lat{ir} = find(lat >= boxes(ir,3)-tol & lat <= boxes(ir,4)+tol);
    if isempty(idx_lon{ir}) || isempty(idx_lat{ir})
        error('No CHIRPS grid points in %s box.',regions{ir});
    end
    rlon{ir} = lon(idx_lon{ir});
    rlat{ir} = lat(idx_lat{ir});
    R{ir} = NaN(numel(rlon{ir}),numel(rlat{ir}),120);
end

fprintf('\n===== SPATIAL CHIRPS PREPARATION =====\n');
fprintf('Source: %s\n',prec_dir);
fprintf('Native unit: %s per calendar month (NO unit conversion)\n',units);

%% 4. Read each annual CHIRPS file in original chronological order
for yr = 2016:2025
    f = fullfile(prec_dir,sprintf('prec_%04d.NTT.nc',yr));
    if ~isfile(f)
        error('Missing CHIRPS year: %s',f);
    end
    infop = ncinfo(f,'prec');
    if numel(infop.Size) ~= 3 || ~isequal(infop.Size,[nlon nlat 12])
        error('CHIRPS variable is not [lon x lat x 12]: %s',f);
    end
    this_unit = char(ncreadatt(f,'prec','units'));
    if ~strcmpi(strtrim(this_unit),'mm')
        error('Unexpected CHIRPS unit in %s: %s',f,this_unit);
    end
    lon_year = double(ncread(f,'lon'));
    lat_year = double(ncread(f,'lat'));
    lon_year = lon_year(:);
    lat_year = lat_year(:);
    if ~isequal(lon_year,lon) || ~isequal(lat_year,lat)
        error('CHIRPS coordinates differ between years: %s',f);
    end
    for mo = 1:12
        t = (yr-2016)*12 + mo;
        P = double(ncread(f,'prec',[1 1 mo],[Inf Inf 1]));
        P = reshape(P,nlon,nlat);
        % Guard against unconverted NetCDF fill values; ncread often
        % already maps _FillValue to NaN.
        P(~isfinite(P) | abs(P)>1e7) = NaN;
        if any(P(isfinite(P))<0)
            error('Negative finite monthly rainfall in %04d-%02d.',yr,mo);
        end
        for ir = 1:3
            block = P(idx_lon{ir},idx_lat{ir});
            R{ir}(:,:,t) = block;
            vals = block(isfinite(block));
            monthly_valid(t,ir) = numel(vals);
            if isempty(vals)
                error('No valid rainfall cells for %s, %04d-%02d.', ...
                    regions{ir},yr,mo);
            end
            regional_check(t,ir) = mean(vals);
        end
    end
    fprintf('Read CHIRPS %d (12 months).\n',yr);
end

%% 5. Reproducibility QC: grid mean must match regional extraction exactly
max_difference = max(abs(regional_check-D.RAIN),[],1);
for ir = 1:3
    fprintf('%s regional rainfall mean consistency: max abs diff = %.9g mm\n', ...
        regions{ir},max_difference(ir));
end
if any(max_difference > 1e-5) || any(~isfinite(max_difference))
    error(['Spatial CHIRPS means disagree with 02_Regional_Timeseries. ', ...
        'Verify same regional boxes, mask handling, units and data files.']);
end

%% 6. Retain grid cells available in ALL 120 months (no polygon mask)
masks = cell(3,1);
clims = cell(3,1);
anoms = cell(3,1);
nmask = zeros(3,1);
max_residual = NaN(3,1);
for ir = 1:3
    mask = all(isfinite(R{ir}),3);
    nmask(ir) = sum(mask(:));
    if nmask(ir)<1
        error('No stable valid cells for %s.',regions{ir});
    end
    masks{ir} = mask;
    C = NaN(size(mask,1),size(mask,2),12);
    A = NaN(size(R{ir}));
    for mo = 1:12
        ids = mo:12:120;
        % Mean each calendar month over 2016-2025 (10 observations).
        C(:,:,mo) = mean(R{ir}(:,:,ids),3,'omitnan');
        for j = 1:numel(ids)
            t = ids(j);
            A(:,:,t) = R{ir}(:,:,t) - C(:,:,mo);
        end
    end
    for t = 1:120
        B = A(:,:,t);
        B(~mask) = NaN;
        A(:,:,t) = B;
    end
    worst = 0;
    for mo = 1:12
        Z = mean(A(:,:,mo:12:120),3,'omitnan');
        residuals = abs(Z(mask));
        worst = max(worst,max(residuals));
    end
    if ~isfinite(worst) || worst>1e-8
        error('Deseasonalization QC failed for %s: %.3g mm.', ...
            regions{ir},worst);
    end
    clims{ir} = C;
    anoms{ir} = A;
    max_residual(ir) = worst;
    fprintf('%s: rectangle=%d cells | stable valid=%d | ', ...
        regions{ir},numel(mask),nmask(ir));
    fprintf('deseason QC residual=%.3g mm\n',worst);
end

expected_nmask = [1158;565;1088];
if ~isequal(nmask,expected_nmask)
    warning(['Grid counts differ from previous reproducibility check: ', ...
        'expected [1158 565 1088], got [%d %d %d].'],nmask);
end

%% 7. Export a human-readable spatial-mask coordinate inventory
MaskRegion = {};
MaskLongitude = [];
MaskLatitude = [];
MaskValidAll120 = [];
for ir = 1:3
    [X,Y] = ndgrid(rlon{ir},rlat{ir});
    nn = numel(X);
    MaskRegion = [MaskRegion;repmat(regions(ir),nn,1)]; %#ok<AGROW>
    MaskLongitude = [MaskLongitude;X(:)]; %#ok<AGROW>
    MaskLatitude = [MaskLatitude;Y(:)]; %#ok<AGROW>
    MaskValidAll120 = [MaskValidAll120;masks{ir}(:)]; %#ok<AGROW>
end
MaskTable = table(MaskRegion,MaskLongitude,MaskLatitude, ...
    logical(MaskValidAll120),'VariableNames', ...
    {'Region','Longitude_WGS84','Latitude_WGS84','Valid_all_120_months'});
writetable(MaskTable,fullfile(out_dir,'spatial_valid_grid_mask.csv'));

%% 8. QC CSV tables
Rectangle_cells = cellfun(@numel,masks);
Valid_grid_count = nmask;
Min_monthly_valid = min(monthly_valid,[],1)';
Max_monthly_valid = max(monthly_valid,[],1)';
Max_abs_regional_mean_diff_mm = max_difference(:);
Max_abs_calendar_month_anomaly_mean_mm = max_residual;
GridQC = table(regions,Rectangle_cells,Valid_grid_count, ...
    Min_monthly_valid,Max_monthly_valid,Max_abs_regional_mean_diff_mm, ...
    Max_abs_calendar_month_anomaly_mean_mm,'VariableNames', ...
    {'Region','Rectangle_cells','Valid_all_120_months', ...
    'Min_monthly_valid','Max_monthly_valid', ...
    'Max_abs_regional_mean_diff_mm','Max_abs_deseason_residual_mm'});
Time = time;
Valid_Flores = monthly_valid(:,1);
Valid_Sumba = monthly_valid(:,2);
Valid_Timor = monthly_valid(:,3);
MonthlyQC = table(Time,Valid_Flores,Valid_Sumba,Valid_Timor);
writetable(GridQC,fullfile(out_dir,'spatial_rainfall_grid_QC.csv'));
writetable(MonthlyQC,fullfile(out_dir,'spatial_rainfall_monthly_QC.csv'));

%% 9. Save arrays in accessible MATLAB v7 format
lon_F = rlon{1}; lat_F = rlat{1};
lon_S = rlon{2}; lat_S = rlat{2};
lon_T = rlon{3}; lat_T = rlat{3};
mask_F = masks{1}; mask_S = masks{2}; mask_T = masks{3};
anom_F = anoms{1}; anom_S = anoms{2}; anom_T = anoms{3};
clim_F = clims{1}; clim_S = clims{2}; clim_T = clims{3};
nmask_F = nmask(1); nmask_S = nmask(2); nmask_T = nmask(3);
save(fullfile(out_dir,'spatial_rainfall_anomaly.mat'), ...
    'time','lon_F','lat_F','lon_S','lat_S','lon_T','lat_T', ...
    'mask_F','mask_S','mask_T','nmask_F','nmask_S','nmask_T', ...
    'anom_F','anom_S','anom_T','clim_F','clim_S','clim_T', ...
    'GridQC','MonthlyQC','MaskTable','-v7');

fprintf('\n===== SPATIAL RAINFALL ANOMALY QC =====\n');
disp(GridQC);
fprintf('Expected stable grid counts: Flores=1158, Sumba=565, Timor=1088.\n');
fprintf('Files saved beside script: spatial_rainfall_anomaly.mat and 3 QC CSVs.\n');
fprintf('Next: run b_spatial_correlation_fdr.m.\n');
