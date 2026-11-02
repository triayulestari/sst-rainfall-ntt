%% ========================================================================
% d_spatial_coarsegrid_sensitivity.m
%
% SPATIAL-RESOLUTION SENSITIVITY FOR SST-RAINFALL CORRELATIONS
% CHIRPS original grid ~0.05 degree -> 2 x 2 aggregation (~0.10 degree)
%
% Save and run from:
%   Data\07_Robustness_Tests
%
% REQUIRED INPUTS (the original results are READ ONLY):
%   ../05_Spatial_Analysis/spatial_rainfall_anomaly.mat
%   ../05_Spatial_Analysis/spatial_correlation_results.mat
%   ../02_Regional_Timeseries/regional_anomalies.mat
%
% ANALYSIS:
%   1. Within each original regional box, combine 2x2 neighboring
%      CHIRPS cells, using an arithmetic mean of VALID LAND cells only.
%   2. Retain a coarse cell only if >= 2 original land cells are present.
%      This avoids treating single coastal pixels as a coarse-grid average.
%   3. Correlate the new rainfall anomalies with the SAME regional SST
%      anomaly time series (no re-cropping and no interpolation).
%   4. Match the original temporal method: Pearson r, adjacent-month
%      lag-1 autocorrelations, effective N, two-sided adjusted p-values.
%   5. Apply BH-FDR within each region AND across all coarse cells.
%   6. Compare coarse r with the original fine-grid result within each
%      corresponding 2x2 footprint and summarize both resolutions.
%
% IMPORTANT LIMITATIONS:
%   - Aggregation is a RESOLUTION SENSITIVITY analysis, not a proof that
%     remaining coarse cells are spatially independent.
%   - Cell-level FDR depends on the number/family of tests and cannot be
%     directly compared as though fine and coarse families were identical.
%   - Blocks are aligned to the FIRST native grid index within each
%     REGIONAL box. This is a region-specific 2x2 grouping, not a new
%     externally registered/global 0.10 degree CHIRPS product.
%   - No conversion of rainfall units is made here: positive scaling
%     does not affect Pearson correlation, but units must be correct in
%     the original preprocessing file for physical interpretation.
%   - Regional boxes, including Timor, are UNCHANGED.
%   - MATLAB R2021a; Statistics and Machine Learning Toolbox (corr/tcdf).
%
% OUTPUTS (does not overwrite original results):
%   spatial_coarse010_summary.csv
%   spatial_coarse010_grid_results.csv
%   spatial_coarse010_results.mat
%
% Author's study period: Jan 2016 - Dec 2025; SST Oct-Nov 2025 is NaN.
%% ========================================================================

clc;
clear;

%% 1. SETTINGS AND INPUTS
native_spacing_deg = 0.05;
block_size = 2;
min_valid_fine_cells = 2;
sig_alpha = 0.05;

script_file = mfilename('fullpath');
if isempty(script_file), error('Save as d_spatial_coarsegrid_sensitivity.m.'); end
outdir = fileparts(script_file); rootdir = fileparts(outdir);
rain_file = fullfile(rootdir,'05_Spatial_Analysis','spatial_rainfall_anomaly.mat');
main_file = fullfile(rootdir,'05_Spatial_Analysis','spatial_correlation_results.mat');
sst_file = fullfile(rootdir,'02_Regional_Timeseries','regional_anomalies.mat');

fprintf('\n============================================================\n');
fprintf('SPATIAL COARSE-GRID SENSITIVITY: ~0.05 to ~0.10 degree\n');
fprintf('============================================================\n');
fprintf('Original regional domains are retained. No interpolation.\n');
fprintf('At least %d valid fine land cells per coarse block.\n', ...
    min_valid_fine_cells);

for f = {rain_file,main_file,sst_file}
    if ~isfile(f{1})
        error('Required input file not found: %s',f{1});
    end
end

A = load(rain_file);
R = load(main_file);
T = load(sst_file);

required_A = {'time','anom_F','anom_S','anom_T', ...
    'mask_F','mask_S','mask_T','lon_F','lon_S','lon_T', ...
    'lat_F','lat_S','lat_T'};
required_R = {'r_map_F','r_map_S','r_map_T', ...
    'mask_F','mask_S','mask_T', ...
    'q_region_map_F','q_region_map_S','q_region_map_T', ...
    'q_global_map_F','q_global_map_S','q_global_map_T'};
required_T = {'time','SST_deseason'};

for k = 1:numel(required_A)
    if ~isfield(A,required_A{k})
        error('Variable %s is missing from %s.',required_A{k},rain_file);
    end
end
for k = 1:numel(required_R)
    if ~isfield(R,required_R{k})
        error('Variable %s is missing from %s.',required_R{k},main_file);
    end
end
for k = 1:numel(required_T)
    if ~isfield(T,required_T{k})
        error('Variable %s is missing from %s.',required_T{k},sst_file);
    end
end

if ~isequal(A.time(:),T.time(:))
    error('Rainfall and SST monthly time axes are NOT identical.');
end

ntime = numel(A.time);
if ntime ~= 120
    warning('Expected 120 calendar months; detected %d.',ntime);
end

%% 2. SELECT THREE REGIONS
names = {'Flores','Sumba','Timor'};
codes = {'F','S','T'};
nreg = numel(names);

coarse = struct([]);

for ir = 1:nreg
    reg = names{ir};
    code = codes{ir};
    fprintf('\n---- %s ----\n',reg);

    P = double(A.(['anom_' code]));
    native_mask = logical(A.(['mask_' code]));
    native_lon = double(A.(['lon_' code]));
    native_lat = double(A.(['lat_' code]));
    native_lon = native_lon(:);
    native_lat = native_lat(:);
    original_r = double(R.(['r_map_' code]));
    original_mask = logical(R.(['mask_' code]));
    original_q_region = double(R.(['q_region_map_' code]));
    original_q_global = double(R.(['q_global_map_' code]));
    x = double(T.SST_deseason(:,ir));
    x = x(:);

    nlon = numel(native_lon);
    nlat = numel(native_lat);
    if size(P,1)~=nlon || size(P,2)~=nlat || size(P,3)~=ntime
        error('%s anomaly array is not lon x lat x time.',reg);
    end
    if ~isequal(size(native_mask),[nlon,nlat]) || ...
       ~isequal(size(original_r),[nlon,nlat]) || ...
       ~isequal(size(original_q_region),[nlon,nlat]) || ...
       ~isequal(size(original_q_global),[nlon,nlat])
        error('%s: spatial mask/map dimensions mismatch.',reg);
    end
    if ~isequal(native_mask,original_mask)
        error('%s: original correlation mask differs from rainfall mask.',reg);
    end
    if numel(x) ~= ntime
        error('%s: SST monthly time series has unexpected length.',reg);
    end

    % Native grid resolution QC; tolerate NetCDF float rounding.
    if any(abs(abs(diff(native_lon))-native_spacing_deg)>0.002) || ...
       any(abs(abs(diff(native_lat))-native_spacing_deg)>0.002)
        error('%s: native lon/lat grid spacing is not ~0.05 degree.',reg);
    end

    % Require stable fully observed rainfall at native land cells.
    mask3 = repmat(native_mask,[1 1 ntime]);
    if any(~isfinite(P(mask3)))
        error('%s: invalid rainfall value in stable original land mask.',reg);
    end

    % SST AR(1) exactly as in b_Spatial_Correlation_FDR.m:
    % adjacent calendar months, NOT a shortened list of SST months.
    xs1 = x(1:end-1);
    xs2 = x(2:end);
    valid_xlag = isfinite(xs1) & isfinite(xs2);
    if sum(valid_xlag)<4
        error('%s: insufficient consecutive SST observations.',reg);
    end
    rho_sst = corr(xs1(valid_xlag),xs2(valid_xlag), ...
        'Type','Pearson');

    nc_lon = ceil(nlon/block_size);
    nc_lat = ceil(nlat/block_size);

    coarse_lon = NaN(nc_lon,1);
    coarse_lat = NaN(nc_lat,1);
    for ilon = 1:nc_lon
        native_i = (1+(ilon-1)*block_size):min(ilon*block_size,nlon);
        coarse_lon(ilon) = mean(native_lon(native_i));
    end
    for ilat = 1:nc_lat
        native_j = (1+(ilat-1)*block_size):min(ilat*block_size,nlat);
        coarse_lat(ilat) = mean(native_lat(native_j));
    end

    % Preallocate coarse outputs, lon x lat.
    cmask = false(nc_lon,nc_lat);
    nfine = zeros(nc_lon,nc_lat);
    rmap = NaN(nc_lon,nc_lat);
    pmap = NaN(nc_lon,nc_lat);
    prawmap = NaN(nc_lon,nc_lat);
    Nmap = NaN(nc_lon,nc_lat);
    Neffmap = NaN(nc_lon,nc_lat);
    rhoYmap = NaN(nc_lon,nc_lat);
    rfine_mean_map = NaN(nc_lon,nc_lat);
    amean_map = NaN(nc_lon,nc_lat); % absolute difference in r

    % 3. COARSE BLOCKS: arithmetic mean of only valid original land cells.
    for ilon = 1:nc_lon
        native_i = (1+(ilon-1)*block_size):min(ilon*block_size,nlon);
        for ilat = 1:nc_lat
            native_j = (1+(ilat-1)*block_size):min(ilat*block_size,nlat);

            block_mask = native_mask(native_i,native_j);
            numland = sum(block_mask(:));
            nfine(ilon,ilat) = numland;
            if numland < min_valid_fine_cells
                continue
            end

            block_rain = P(native_i,native_j,:);
            block_matrix = reshape(block_rain,[],ntime);
            land_vec = block_mask(:);
            Y = mean(block_matrix(land_vec,:),1)';
            if any(~isfinite(Y))
                error('%s: coarse block contains invalid rainfall anomalies.',reg);
            end

            % Pairwise valid observations: SST missing months remain NaN.
            valid_xy = isfinite(x) & isfinite(Y);
            n = sum(valid_xy);
            if n < 4 || std(x(valid_xy))<=0 || std(Y(valid_xy))<=0
                continue
            end
            [rr, pp_raw] = corr(x(valid_xy),Y(valid_xy), ...
                'Type','Pearson');

            % Rainfall AR(1) using the ORIGINAL 120-position calendar.
            yy1 = Y(1:end-1);
            yy2 = Y(2:end);
            valid_ylag = isfinite(yy1) & isfinite(yy2);
            if sum(valid_ylag)<4 || ...
                std(yy1(valid_ylag))<=0 || std(yy2(valid_ylag))<=0
                continue
            end
            rho_rain = corr(yy1(valid_ylag),yy2(valid_ylag), ...
                'Type','Pearson');

            % Match the original Neff and two-sided Student-t procedure.
            product_rho = rho_sst * rho_rain;
            if (1+product_rho)<=0
                error('Invalid AR(1) product in %s.',reg);
            end
            Neff = n*(1-product_rho)/(1+product_rho);
            Neff = min(max(Neff,3),n);
            df = Neff - 2;
            r_safe = min(max(rr,-1+1e-12),1-1e-12);
            t_stat = r_safe*sqrt(df/(1-r_safe^2));
            p_adjusted = 2*tcdf(-abs(t_stat),df);

            % Compare coarse r to mean native r of the SAME 2x2 block.
            block_fine_r = original_r(native_i,native_j);
            block_fine_r = block_fine_r(block_mask & isfinite(block_fine_r));
            if isempty(block_fine_r)
                continue
            end
            local_mean_r = mean(block_fine_r);

            cmask(ilon,ilat) = true;
            rmap(ilon,ilat) = rr;
            prawmap(ilon,ilat) = pp_raw;
            pmap(ilon,ilat) = p_adjusted;
            Nmap(ilon,ilat) = n;
            Neffmap(ilon,ilat) = Neff;
            rhoYmap(ilon,ilat) = rho_rain;
            rfine_mean_map(ilon,ilat) = local_mean_r;
            amean_map(ilon,ilat) = abs(rr-local_mean_r);
        end
    end

    if ~any(cmask(:))
        error('No coarse cells retained for %s. Check masks.',reg);
    end

    % 4. FDR within this region's retained coarse cells.
    q_region_map = NaN(size(cmask));
    q_region_map(cmask) = local_bh_fdr(pmap(cmask));

    coarse(ir).Region = reg;
    coarse(ir).code = code;
    coarse(ir).lon = coarse_lon;
    coarse(ir).lat = coarse_lat;
    coarse(ir).mask = cmask;
    coarse(ir).original_mask = native_mask;
    coarse(ir).num_fine = nfine;
    coarse(ir).r_map = rmap;
    coarse(ir).p_raw_map = prawmap;
    coarse(ir).p_adj_map = pmap;
    coarse(ir).q_region_map = q_region_map;
    coarse(ir).q_all_map = NaN(size(cmask));
    coarse(ir).N_map = Nmap;
    coarse(ir).Neff_map = Neffmap;
    coarse(ir).rain_lag1_map = rhoYmap;
    coarse(ir).sst_lag1 = rho_sst;
    coarse(ir).mean_fine_r_map = rfine_mean_map;
    coarse(ir).abs_r_diff_map = amean_map;
    coarse(ir).original_r = original_r;
    coarse(ir).original_q_region = original_q_region;
    coarse(ir).original_q_all = original_q_global;

    fprintf('Fine valid land grid cells : %d\n',sum(native_mask(:)));
    fprintf('Coarse retained cells      : %d\n',sum(cmask(:)));
    fprintf('Fine cells represented     : %d\n',sum(nfine(cmask)));
    fprintf('Native SST valid months    : %d\n',sum(isfinite(x)));
    fprintf('Coarse r median            : %+.4f\n',median(rmap(cmask)));
    fprintf('Coarse within-region FDR   : %d retained q<0.05\n', ...
        sum(q_region_map(cmask)<sig_alpha));
end

%% 5. SECOND BH-FDR: ONE COMBINED FAMILY OF ALL COARSE CELLS
p_all = [];
for ir = 1:nreg
    p_all = [p_all; coarse(ir).p_adj_map(coarse(ir).mask)]; %#ok<AGROW>
end
q_all = local_bh_fdr(p_all);
start_idx = 1;
for ir = 1:nreg
    n_here = nnz(coarse(ir).mask);
    q = q_all(start_idx:(start_idx+n_here-1));
    qmap = NaN(size(coarse(ir).mask));
    qmap(coarse(ir).mask) = q;
    coarse(ir).q_all_map = qmap;
    start_idx = start_idx + n_here;
end

%% 6. SUMMARY AND PER-CELL AUDIT TABLE
summary_rows = struct([]);
gridTables = cell(nreg,1);

for ir = 1:nreg
    C = coarse(ir);
    code = codes{ir};
    mf = C.original_mask;
    mc = C.mask;
    native_r_vals = C.original_r(mf);
    coarse_r_vals = C.r_map(mc);

    fine_r_sig = nnz(C.original_q_region(mf)<sig_alpha);
    fine_all_sig = nnz(C.original_q_all(mf)<sig_alpha);
    coarse_r_sig = nnz(C.q_region_map(mc)<sig_alpha);
    coarse_all_sig = nnz(C.q_all_map(mc)<sig_alpha);

    represented_pixels = sum(C.num_fine(mc));

    summary_rows(ir).Region = C.Region;
    summary_rows(ir).Fine_grids = nnz(mf);
    summary_rows(ir).Coarse_grids = nnz(mc);
    summary_rows(ir).Fine_grids_represented = represented_pixels;
    summary_rows(ir).Fine_grids_excluded_at_coast = nnz(mf)-represented_pixels;
    summary_rows(ir).Fine_mean_r = mean(native_r_vals);
    summary_rows(ir).Coarse_mean_r = mean(coarse_r_vals);
    summary_rows(ir).Fine_median_r = median(native_r_vals);
    summary_rows(ir).Coarse_median_r = median(coarse_r_vals);
    summary_rows(ir).Fine_positive_pct = 100*mean(native_r_vals>0);
    summary_rows(ir).Coarse_positive_pct = 100*mean(coarse_r_vals>0);
    summary_rows(ir).Mean_abs_r_diff_vs_local_fine = ...
        mean(C.abs_r_diff_map(mc));
    summary_rows(ir).Fine_FDR_region_005 = fine_r_sig;
    summary_rows(ir).Coarse_FDR_region_005 = coarse_r_sig;
    summary_rows(ir).Fine_FDR_all_005 = fine_all_sig;
    summary_rows(ir).Coarse_FDR_all_005 = coarse_all_sig;

    [G_lon,G_lat] = ndgrid(C.lon,C.lat);
    ncell = nnz(mc);
    Region = repmat({C.Region},ncell,1);
    Longitude = G_lon(mc);
    Latitude = G_lat(mc);
    Native_land_cells = C.num_fine(mc);
    N = C.N_map(mc);
    Pearson_r = C.r_map(mc);
    Mean_native_r_within_block = C.mean_fine_r_map(mc);
    Delta_r_vs_mean_native = Pearson_r-Mean_native_r_within_block;
    SST_lag1 = repmat(C.sst_lag1,ncell,1);
    Rain_lag1 = C.rain_lag1_map(mc);
    N_effective = C.Neff_map(mc);
    p_raw = C.p_raw_map(mc);
    p_autocorr_adjusted = C.p_adj_map(mc);
    q_FDR_region = C.q_region_map(mc);
    q_FDR_all_coarse = C.q_all_map(mc);
    gridTables{ir} = table(Region,Longitude,Latitude,Native_land_cells, ...
        N,Pearson_r,Mean_native_r_within_block,Delta_r_vs_mean_native, ...
        SST_lag1,Rain_lag1,N_effective,p_raw,p_autocorr_adjusted, ...
        q_FDR_region,q_FDR_all_coarse);
end

SummaryTable = struct2table(summary_rows);
GridResultTable = vertcat(gridTables{:});

%% 7. OUTPUT, WITHOUT ALTERING OR REPLACING MAIN RESULTS
writetable(SummaryTable,fullfile(outdir,'spatial_coarse010_summary.csv'));
writetable(GridResultTable,fullfile(outdir,'spatial_coarse010_grid_results.csv'));
save(fullfile(outdir,'spatial_coarse010_results.mat'),'coarse','SummaryTable', ...
    'GridResultTable','native_spacing_deg','block_size', ...
    'min_valid_fine_cells','sig_alpha','-v7.3');

fprintf('\n============================================================\n');
fprintf('SENSITIVITY SUMMARY: NATIVE ~0.05 vs COARSE ~0.10 degree\n');
fprintf('============================================================\n');
disp(SummaryTable);
fprintf('\nCombined coarse-grid FDR family: %d cells.\n',numel(p_all));
fprintf('Coarse cells with pooled q<0.05: %d.\n',sum(q_all<sig_alpha));
fprintf('\nOutputs created (original results remain unchanged):\n');
fprintf('1. spatial_coarse010_summary.csv\n');
fprintf('2. spatial_coarse010_grid_results.csv\n');
fprintf('3. spatial_coarse010_results.mat\n');
fprintf('\nInterpretation: compare r magnitudes, medians and signs; do NOT\n');
fprintf('treat separate FDR families or spatial cells as independent samples.\n');

%% ========================================================================
% LOCAL FUNCTION: Benjamini-Hochberg FDR (MATLAB R2021a script functions)
%% ========================================================================
function q = local_bh_fdr(p)
    p = p(:);
    q = NaN(size(p));
    idxvalid = find(isfinite(p) & p>=0 & p<=1);
    m = numel(idxvalid);
    if m == 0
        return
    end
    [ps,order] = sort(p(idxvalid),'ascend');
    qs = ps.*(m./(1:m)');
    for i=m-1:-1:1
        qs(i) = min(qs(i),qs(i+1));
    end
    qs = min(qs,1);
    q(idxvalid(order)) = qs;
end
