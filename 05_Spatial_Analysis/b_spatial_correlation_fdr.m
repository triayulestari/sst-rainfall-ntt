%% ========================================================================
% b_spatial_correlation_fdr.m
% GRIDWISE SST-RAINFALL CORRELATION AND FDR | NTT 2016-2025
%
% MATLAB R2021a; Statistics and Machine Learning Toolbox needed (corr,tcdf)
% Save in Data/05_Spatial_Analysis/ and press Run (F5), AFTER script a.
%
% Inputs:
%   spatial_rainfall_anomaly.mat (produced by script a, SAME folder)
%   ../02_Regional_Timeseries/regional_anomalies.mat
%
% Outputs:
%   spatial_correlation_results.mat
%   spatial_correlation_summary.csv
%   spatial_correlation_grid_results.csv
%
% Method:
%   X = regional-mean SST deseasonalized monthly anomaly [120 x 1]
%   Y = CHIRPS rainfall deseasonalized anomaly at each valid land grid
%   Monthly Pearson r at lag 0 with 118 valid paired months.
%   rhoSST/rhoRain = lag-1 autocorrelations of consecutive calendar months
%   (missing Oct-Nov 2025 SST are NEVER bridged).
%   Neff = N*(1-rhoSST*rhoRain)/(1+rhoSST*rhoRain), clamped to [3,N]
%   Two-sided t-test, df = Neff-2, then Benjamini-Hochberg FDR:
%     (1) within each region (Flores, Sumba, Timor) separately
%     (2) pooled across ALL valid grids of the three regions (NTT-wide)
%
% CAVEATS:
%   Rectangular geographic domains (not administrative polygons).
%   Spatial neighboring grids are autocorrelated, not independent replicates.
%   Pooled family refers to all grids IN THESE THREE RECTANGLES, not all NTT.
%   Association is not causation or forecast skill.
%% ========================================================================
clc;
clear;

%% 1. Resolve inputs relative to saved script
script_path = mfilename('fullpath');
if isempty(script_path)
    error('Save this script as b_spatial_correlation_fdr.m first.');
end
out_dir = fileparts(script_path);
data_dir = fileparts(out_dir);
input_grid = fullfile(out_dir,'spatial_rainfall_anomaly.mat');
input_reg = fullfile(data_dir,'02_Regional_Timeseries','regional_anomalies.mat');
if ~isfile(input_grid) || ~isfile(input_reg)
    error('Missing spatial_rainfall_anomaly.mat or regional_anomalies.mat.');
end
G = load(input_grid);
D = load(input_reg,'time','SST_deseason');
if ~isfield(D,'time') || ~isfield(D,'SST_deseason') || ...
        ~isequal(size(D.SST_deseason),[120,3]) || ...
        ~isdatetime(D.time) || ~isequal(G.time(:),D.time(:))
    error('Regional and spatial time dimensions are inconsistent.');
end

regions = {'Flores';'Sumba';'Timor'};
anom_names = {'anom_F','anom_S','anom_T'};
mask_names = {'mask_F','mask_S','mask_T'};
lon_names = {'lon_F','lon_S','lon_T'};
lat_names = {'lat_F','lat_S','lat_T'};

%% 2. Loop over 3 regions and every stable valid CHIRPS grid
r_maps = cell(3,1);
praw_maps = cell(3,1);
padj_maps = cell(3,1);
N_maps = cell(3,1);
Neff_maps = cell(3,1);
rho_maps = cell(3,1);
qregion_maps = cell(3,1);
qpooled_maps = cell(3,1);
p_vectors = cell(3,1);

fprintf('\n===== SPATIAL CORRELATION / EFFECTIVE-N =====\n');
for ir = 1:3
    R = G.(anom_names{ir});
    mask = logical(G.(mask_names{ir}));
    lon = G.(lon_names{ir}); lon = lon(:);
    lat = G.(lat_names{ir}); lat = lat(:);
    if ~isequal(size(R),[numel(lon),numel(lat),120]) || ...
            ~isequal(size(mask),[numel(lon),numel(lat)])
        error('Shape mismatch: %s.',regions{ir});
    end
    x = D.SST_deseason(:,ir);
    if numel(x)~=120 || sum(isfinite(x))~=118
        error('Expected 118 valid SST months for %s.',regions{ir});
    end
    % Use consecutive original months, never remove missing months before rho1
    vx = isfinite(x(1:end-1)) & isfinite(x(2:end));
    if sum(vx)<4
        error('Insufficient adjacent SST samples in %s.',regions{ir});
    end
    idxvx = find(vx);
    rho_x = corr(x(idxvx),x(idxvx+1),'Type','Pearson');

    rr = NaN(size(mask)); pr = rr; pa = rr; nn = rr; ne = rr; ry = rr;
    ids = find(mask);
    for k = 1:numel(ids)
        [i,j] = ind2sub(size(mask),ids(k));
        y = reshape(R(i,j,:),120,1);
        valid = isfinite(x) & isfinite(y);
        n = sum(valid);
        if n<4
            error('Insufficient SST-rainfall pairs: %s grid (%d,%d).', ...
                regions{ir},i,j);
        end
        [r,p] = corr(x(valid),y(valid),'Type','Pearson');
        if ~isfinite(r) || ~isfinite(p)
            error('Undefined Pearson correlation in %s grid (%d,%d).', ...
                regions{ir},i,j);
        end
        vy = isfinite(y(1:end-1)) & isfinite(y(2:end));
        idy = find(vy);
        if numel(idy)<4
            error('Insufficient adjacent rainfall samples in %s.',regions{ir});
        end
        rho_y = corr(y(idy),y(idy+1),'Type','Pearson');
        product = rho_x*rho_y;
        if ~isfinite(product) || 1+product<=0
            error('Invalid lag-1 autocorrelation product for %s.',regions{ir});
        end
        n_eff = max(3,min(n,n*(1-product)/(1+product)));
        if abs(r)>=1
            p_eff = 0;
        else
            test_t = r*sqrt((n_eff-2)/(1-r*r));
            p_eff = 2*tcdf(-abs(test_t),n_eff-2);
        end
        rr(i,j) = r;
        pr(i,j) = p;
        pa(i,j) = p_eff;
        nn(i,j) = n;
        ne(i,j) = n_eff;
        ry(i,j) = rho_y;
    end
    r_maps{ir} = rr;
    praw_maps{ir} = pr;
    padj_maps{ir} = pa;
    N_maps{ir} = nn;
    Neff_maps{ir} = ne;
    rho_maps{ir} = ry;
    p_vectors{ir} = pa(mask);
    if any(~isfinite(p_vectors{ir})) || ...
            any(p_vectors{ir}<0 | p_vectors{ir}>1)
        error('Non-finite adjusted p in %s.',regions{ir});
    end
    fprintf('%s: %d valid grids | rhoSST=%.4f | N range=%d..%d\n', ...
        regions{ir},numel(ids),rho_x,min(nn(mask)),max(nn(mask)));
end

%% 3. Benjamini-Hochberg FDR within each region
for ir = 1:3
    pvec = p_vectors{ir};
    m = numel(pvec);
    [p_sorted,order] = sort(pvec);
    q_sorted = p_sorted.*(m./(1:m)');
    for k = m-1:-1:1
        q_sorted(k) = min(q_sorted(k),q_sorted(k+1));
    end
    q_sorted = min(1,q_sorted);
    qvec = NaN(m,1);
    qvec(order) = q_sorted;
    mask = logical(G.(mask_names{ir}));
    qmap = NaN(size(mask));
    qmap(mask) = qvec;
    qregion_maps{ir} = qmap;
end

%% 4. Benjamini-Hochberg FDR across pooled 2811 grids
p_all = vertcat(p_vectors{:});
m_all = numel(p_all);
[p_sorted,order] = sort(p_all);
q_sorted = p_sorted.*(m_all./(1:m_all)');
for k = m_all-1:-1:1
    q_sorted(k) = min(q_sorted(k),q_sorted(k+1));
end
q_sorted = min(1,q_sorted);
q_all = NaN(m_all,1);
q_all(order) = q_sorted;
position = 0;
for ir = 1:3
    m = numel(p_vectors{ir});
    mask = logical(G.(mask_names{ir}));
    qmap = NaN(size(mask));
    qmap(mask) = q_all(position+(1:m));
    qpooled_maps{ir} = qmap;
    position = position+m;
end

%% 5. Export full per-grid CSV plus compact summary CSV
RegionTables = cell(3,1);
Valid_grids = NaN(3,1);
r_min = NaN(3,1); r_max = r_min; r_mean = r_min;
r_median = r_min; r_std = r_min; Positive_grid_percent = r_min;
Neff_min = r_min; Neff_max = r_min;
N_padj_lt_0_05 = r_min;
N_FDR_region_lt_0_05 = r_min;
N_FDR_pooled_lt_0_05 = r_min;

for ir = 1:3
    mask = logical(G.(mask_names{ir}));
    lon = G.(lon_names{ir}); lon = lon(:);
    lat = G.(lat_names{ir}); lat = lat(:);
    [Lon,Lat] = ndgrid(lon,lat);
    ix = find(mask);
    Region = repmat(regions(ir),numel(ix),1);
    Longitude = Lon(ix);
    Latitude = Lat(ix);
    N = N_maps{ir}(ix);
    Pearson_r = r_maps{ir}(ix);
    Rain_lag1 = rho_maps{ir}(ix);
    N_effective = Neff_maps{ir}(ix);
    p_raw = praw_maps{ir}(ix);
    p_autocorr_adjusted = padj_maps{ir}(ix);
    q_FDR_region = qregion_maps{ir}(ix);
    q_FDR_all_grids = qpooled_maps{ir}(ix);
    T = table(Region,Longitude,Latitude,N,Pearson_r,Rain_lag1, ...
        N_effective,p_raw,p_autocorr_adjusted,q_FDR_region, ...
        q_FDR_all_grids);
    RegionTables{ir} = T;

    Valid_grids(ir) = numel(ix);
    r_min(ir) = min(Pearson_r);
    r_max(ir) = max(Pearson_r);
    r_mean(ir) = mean(Pearson_r);
    r_median(ir) = median(Pearson_r);
    r_std(ir) = std(Pearson_r);
    Positive_grid_percent(ir) = 100*mean(Pearson_r>0);
    Neff_min(ir) = min(N_effective);
    Neff_max(ir) = max(N_effective);
    N_padj_lt_0_05(ir) = sum(p_autocorr_adjusted<0.05);
    N_FDR_region_lt_0_05(ir) = sum(q_FDR_region<0.05);
    N_FDR_pooled_lt_0_05(ir) = sum(q_FDR_all_grids<0.05);
end

GridTable = vertcat(RegionTables{:});
Region = regions;
SummaryTable = table(Region,Valid_grids,r_min,r_max,r_mean,r_median, ...
    r_std,Positive_grid_percent,Neff_min,Neff_max, ...
    N_padj_lt_0_05,N_FDR_region_lt_0_05,N_FDR_pooled_lt_0_05);
writetable(SummaryTable,fullfile(out_dir,'spatial_correlation_summary.csv'));
writetable(GridTable,fullfile(out_dir,'spatial_correlation_grid_results.csv'));

%% 6. Export compatibility variable names for Figure 4 in later stage
lon_F = G.lon_F; lat_F = G.lat_F;
lon_S = G.lon_S; lat_S = G.lat_S;
lon_T = G.lon_T; lat_T = G.lat_T;
mask_F = G.mask_F; mask_S = G.mask_S; mask_T = G.mask_T;
r_map_F = r_maps{1}; r_map_S = r_maps{2}; r_map_T = r_maps{3};
p_raw_map_F = praw_maps{1}; p_raw_map_S = praw_maps{2};
p_raw_map_T = praw_maps{3};
p_adj_map_F = padj_maps{1}; p_adj_map_S = padj_maps{2};
p_adj_map_T = padj_maps{3};
N_map_F = N_maps{1}; N_map_S = N_maps{2}; N_map_T = N_maps{3};
Neff_map_F = Neff_maps{1}; Neff_map_S = Neff_maps{2};
Neff_map_T = Neff_maps{3};
r1_rain_map_F = rho_maps{1}; r1_rain_map_S = rho_maps{2};
r1_rain_map_T = rho_maps{3};
q_region_map_F = qregion_maps{1}; q_region_map_S = qregion_maps{2};
q_region_map_T = qregion_maps{3};
q_global_map_F = qpooled_maps{1}; q_global_map_S = qpooled_maps{2};
q_global_map_T = qpooled_maps{3};
save(fullfile(out_dir,'spatial_correlation_results.mat'), ...
    'lon_F','lat_F','lon_S','lat_S','lon_T','lat_T', ...
    'mask_F','mask_S','mask_T','r_map_F','r_map_S','r_map_T', ...
    'p_raw_map_F','p_raw_map_S','p_raw_map_T', ...
    'p_adj_map_F','p_adj_map_S','p_adj_map_T', ...
    'N_map_F','N_map_S','N_map_T', ...
    'Neff_map_F','Neff_map_S','Neff_map_T', ...
    'r1_rain_map_F','r1_rain_map_S','r1_rain_map_T', ...
    'q_region_map_F','q_region_map_S','q_region_map_T', ...
    'q_global_map_F','q_global_map_S','q_global_map_T', ...
    'SummaryTable','GridTable','-v7');

%% 7. Final numerical QC, with previous results as CHECK (not hardcoded output)
fprintf('\n===== SPATIAL CORRELATION FDR QC =====\n');
fprintf('BH-FDR within 3 regions; pooled family = %d valid grids.\n',m_all);
for ir=1:3
    fprintf('%-6s: grids=%4d, median r=%+.4f, per-region q<0.05=%3d, pooled q<0.05=%3d\n', ...
        regions{ir},Valid_grids(ir),r_median(ir), ...
        N_FDR_region_lt_0_05(ir),N_FDR_pooled_lt_0_05(ir));
end
if m_all~=2811 || ~isequal(N_FDR_region_lt_0_05,[110;0;0]) || ...
        any(N_FDR_pooled_lt_0_05~=0)
    warning(['Differences relative to previous spatial results. ', ...
        'Verify full grid CSV, source data, effective-N calculation, ', ...
        'and regional boxes before changing the manuscript.']);
end
fprintf('Saved: spatial_correlation_results.mat, spatial_correlation_summary.csv, spatial_correlation_grid_results.csv\n');
fprintf('IMPORTANT: Within-region dots do not survive pooled correction if all pooled counts are zero.\n');
