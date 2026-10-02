%% =========================================================
% 02_Spatial_Correlation_FDR.m
%
% SPATIAL SST-RAINFALL CORRELATION
%
% Regional-mean SST anomaly is correlated with
% rainfall anomaly at every valid land grid.
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Period:
%   January 2016 - December 2025
%
% Inputs:
%
%   spatial_rainfall_anomaly.mat
%
%   ..\3-Timeseries\
%      regional_timeseries_anomaly.mat
%
% Analysis at every valid rainfall grid:
%
%   1. Pearson correlation r
%   2. Ordinary p-value
%   3. Rainfall lag-1 autocorrelation
%   4. Effective sample size (Neff)
%   5. Autocorrelation-adjusted p-value
%   6. BH-FDR within each regional spatial field
%   7. BH-FDR across all grids as sensitivity check
%
% Outputs:
%
%   spatial_correlation_results.mat
%   spatial_correlation_summary.csv
%   spatial_correlation_grid_results.csv
%
% IMPORTANT:
%
%   The same regional SST anomaly is correlated
%   against every rainfall grid within that region.
%
%   No interpolation is performed.
%
% No local functions are used.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD GRIDDED RAINFALL ANOMALIES
%% =========================================================

load('spatial_rainfall_anomaly.mat',...
    'time',...
    'lon_F','lat_F',...
    'lon_S','lat_S',...
    'lon_T','lat_T',...
    'anom_F','anom_S','anom_T',...
    'mask_F','mask_S','mask_T',...
    'nmask_F','nmask_S','nmask_T');


%% =========================================================
% 2. LOAD REGIONAL SST ANOMALIES
%% =========================================================

SSTdata = load(...
    '..\3-Timeseries\regional_timeseries_anomaly.mat',...
    'time',...
    'anom_sst_flores',...
    'anom_sst_sumba',...
    'anom_sst_timor');


%% =========================================================
% 3. CHECK TIME DIMENSIONS
%% =========================================================

if length(time) ~= length(SSTdata.time)

    error('Rainfall and SST time dimensions do not match.');

end


if any(time ~= SSTdata.time)

    error('Rainfall and SST time vectors are not identical.');

end


sst_F = SSTdata.anom_sst_flores(:);
sst_S = SSTdata.anom_sst_sumba(:);
sst_T = SSTdata.anom_sst_timor(:);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SPATIAL SST-RAINFALL CORRELATION\n')
fprintf('=========================================================\n')

fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));

fprintf('Monthly positions = %d\n',...
    length(time));


fprintf('\nValid regional SST months:\n')

fprintf('Flores = %d\n',...
    sum(~isnan(sst_F)));

fprintf('Sumba  = %d\n',...
    sum(~isnan(sst_S)));

fprintf('Timor  = %d\n',...
    sum(~isnan(sst_T)));


%% =========================================================
% 4. SST LAG-1 AUTOCORRELATION
%
% Calculated once per region.
%% =========================================================

%% -------------------------
% Flores
%% -------------------------

x1 = sst_F(1:end-1);
x2 = sst_F(2:end);

valid = ...
    ~isnan(x1) & ...
    ~isnan(x2);

r1_sst_F = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');


%% -------------------------
% Sumba
%% -------------------------

x1 = sst_S(1:end-1);
x2 = sst_S(2:end);

valid = ...
    ~isnan(x1) & ...
    ~isnan(x2);

r1_sst_S = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');


%% -------------------------
% Timor
%% -------------------------

x1 = sst_T(1:end-1);
x2 = sst_T(2:end);

valid = ...
    ~isnan(x1) & ...
    ~isnan(x2);

r1_sst_T = corr(...
    x1(valid),...
    x2(valid),...
    'Type','Pearson');


fprintf('\n')
fprintf('Regional SST lag-1 autocorrelation:\n')

fprintf('Flores = %.4f\n',r1_sst_F);
fprintf('Sumba  = %.4f\n',r1_sst_S);
fprintf('Timor  = %.4f\n',r1_sst_T);


%% =========================================================
% 5. PREALLOCATE FLORES MAPS
%% =========================================================

r_map_F = NaN(size(mask_F));

p_raw_map_F = NaN(size(mask_F));

p_adj_map_F = NaN(size(mask_F));

N_map_F = NaN(size(mask_F));

Neff_map_F = NaN(size(mask_F));

r1_rain_map_F = NaN(size(mask_F));


%% =========================================================
% 6. FLORES GRID-BY-GRID CORRELATION
%% =========================================================

[idx_i,idx_j] = find(mask_F);


for k = 1:length(idx_i)

    i = idx_i(k);
    j = idx_j(k);


    y = squeeze(...
        anom_F(i,j,:));


    %% -----------------------------------------------------
    % Paired valid SST-rainfall observations
    %% -----------------------------------------------------

    valid_pair = ...
        ~isnan(sst_F) & ...
        ~isnan(y);


    x_pair = sst_F(valid_pair);
    y_pair = y(valid_pair);


    n = length(x_pair);


    %% -----------------------------------------------------
    % Pearson correlation
    %% -----------------------------------------------------

    [r_obs,p_obs] = corr(...
        x_pair,...
        y_pair,...
        'Type','Pearson');


    %% -----------------------------------------------------
    % Rainfall lag-1 autocorrelation
    %
    % Use original monthly sequence so missing periods
    % would not be bridged.
    %% -----------------------------------------------------

    y1 = y(1:end-1);
    y2 = y(2:end);


    valid_y = ...
        ~isnan(y1) & ...
        ~isnan(y2);


    r1_rain = corr(...
        y1(valid_y),...
        y2(valid_y),...
        'Type','Pearson');


    %% -----------------------------------------------------
    % Effective sample size
    %% -----------------------------------------------------

    Neff = ...
        n * ...
        (1-r1_sst_F*r1_rain) / ...
        (1+r1_sst_F*r1_rain);


    Neff = min(Neff,n);

    Neff = max(Neff,3);


    %% -----------------------------------------------------
    % Autocorrelation-adjusted significance
    %% -----------------------------------------------------

    df = Neff - 2;


    t_stat = ...
        r_obs * ...
        sqrt(df/(1-r_obs^2));


    p_adj = ...
        2 * ...
        (1-tcdf(abs(t_stat),df));


    %% -----------------------------------------------------
    % Save
    %% -----------------------------------------------------

    r_map_F(i,j) = r_obs;

    p_raw_map_F(i,j) = p_obs;

    p_adj_map_F(i,j) = p_adj;

    N_map_F(i,j) = n;

    Neff_map_F(i,j) = Neff;

    r1_rain_map_F(i,j) = r1_rain;

end


%% =========================================================
% 7. PREALLOCATE SUMBA MAPS
%% =========================================================

r_map_S = NaN(size(mask_S));

p_raw_map_S = NaN(size(mask_S));

p_adj_map_S = NaN(size(mask_S));

N_map_S = NaN(size(mask_S));

Neff_map_S = NaN(size(mask_S));

r1_rain_map_S = NaN(size(mask_S));


%% =========================================================
% 8. SUMBA GRID-BY-GRID CORRELATION
%% =========================================================

[idx_i,idx_j] = find(mask_S);


for k = 1:length(idx_i)

    i = idx_i(k);
    j = idx_j(k);


    y = squeeze(...
        anom_S(i,j,:));


    valid_pair = ...
        ~isnan(sst_S) & ...
        ~isnan(y);


    x_pair = sst_S(valid_pair);
    y_pair = y(valid_pair);


    n = length(x_pair);


    [r_obs,p_obs] = corr(...
        x_pair,...
        y_pair,...
        'Type','Pearson');


    y1 = y(1:end-1);
    y2 = y(2:end);


    valid_y = ...
        ~isnan(y1) & ...
        ~isnan(y2);


    r1_rain = corr(...
        y1(valid_y),...
        y2(valid_y),...
        'Type','Pearson');


    Neff = ...
        n * ...
        (1-r1_sst_S*r1_rain) / ...
        (1+r1_sst_S*r1_rain);


    Neff = min(Neff,n);

    Neff = max(Neff,3);


    df = Neff - 2;


    t_stat = ...
        r_obs * ...
        sqrt(df/(1-r_obs^2));


    p_adj = ...
        2 * ...
        (1-tcdf(abs(t_stat),df));


    r_map_S(i,j) = r_obs;

    p_raw_map_S(i,j) = p_obs;

    p_adj_map_S(i,j) = p_adj;

    N_map_S(i,j) = n;

    Neff_map_S(i,j) = Neff;

    r1_rain_map_S(i,j) = r1_rain;

end


%% =========================================================
% 9. PREALLOCATE TIMOR MAPS
%% =========================================================

r_map_T = NaN(size(mask_T));

p_raw_map_T = NaN(size(mask_T));

p_adj_map_T = NaN(size(mask_T));

N_map_T = NaN(size(mask_T));

Neff_map_T = NaN(size(mask_T));

r1_rain_map_T = NaN(size(mask_T));


%% =========================================================
% 10. TIMOR GRID-BY-GRID CORRELATION
%% =========================================================

[idx_i,idx_j] = find(mask_T);


for k = 1:length(idx_i)

    i = idx_i(k);
    j = idx_j(k);


    y = squeeze(...
        anom_T(i,j,:));


    valid_pair = ...
        ~isnan(sst_T) & ...
        ~isnan(y);


    x_pair = sst_T(valid_pair);
    y_pair = y(valid_pair);


    n = length(x_pair);


    [r_obs,p_obs] = corr(...
        x_pair,...
        y_pair,...
        'Type','Pearson');


    y1 = y(1:end-1);
    y2 = y(2:end);


    valid_y = ...
        ~isnan(y1) & ...
        ~isnan(y2);


    r1_rain = corr(...
        y1(valid_y),...
        y2(valid_y),...
        'Type','Pearson');


    Neff = ...
        n * ...
        (1-r1_sst_T*r1_rain) / ...
        (1+r1_sst_T*r1_rain);


    Neff = min(Neff,n);

    Neff = max(Neff,3);


    df = Neff - 2;


    t_stat = ...
        r_obs * ...
        sqrt(df/(1-r_obs^2));


    p_adj = ...
        2 * ...
        (1-tcdf(abs(t_stat),df));


    r_map_T(i,j) = r_obs;

    p_raw_map_T(i,j) = p_obs;

    p_adj_map_T(i,j) = p_adj;

    N_map_T(i,j) = n;

    Neff_map_T(i,j) = Neff;

    r1_rain_map_T(i,j) = r1_rain;

end


%% =========================================================
% 11. SAMPLE-SIZE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SPATIAL SAMPLE SIZE QC\n')
fprintf('=========================================================\n')


fprintf('\nFlores:\n')
fprintf('Minimum N = %.0f\n',...
    min(N_map_F(mask_F)));

fprintf('Maximum N = %.0f\n',...
    max(N_map_F(mask_F)));


fprintf('\nSumba:\n')
fprintf('Minimum N = %.0f\n',...
    min(N_map_S(mask_S)));

fprintf('Maximum N = %.0f\n',...
    max(N_map_S(mask_S)));


fprintf('\nTimor:\n')
fprintf('Minimum N = %.0f\n',...
    min(N_map_T(mask_T)));

fprintf('Maximum N = %.0f\n',...
    max(N_map_T(mask_T)));


%% =========================================================
% 12. BH-FDR WITHIN EACH REGION
%
% This is the PRIMARY spatial FDR interpretation.
%% =========================================================


%% -------------------------
% Flores
%% -------------------------

pF = p_adj_map_F(mask_F);

mF = length(pF);


[p_sort,idx_sort] = sort(pF);


q_sort = ...
    p_sort .* mF ./ (1:mF)';


for k = mF-1:-1:1

    q_sort(k) = ...
        min(q_sort(k),q_sort(k+1));

end


q_sort = min(q_sort,1);


qF = NaN(mF,1);

qF(idx_sort) = q_sort;


q_region_map_F = NaN(size(mask_F));

q_region_map_F(mask_F) = qF;


%% -------------------------
% Sumba
%% -------------------------

pS = p_adj_map_S(mask_S);

mS = length(pS);


[p_sort,idx_sort] = sort(pS);


q_sort = ...
    p_sort .* mS ./ (1:mS)';


for k = mS-1:-1:1

    q_sort(k) = ...
        min(q_sort(k),q_sort(k+1));

end


q_sort = min(q_sort,1);


qS = NaN(mS,1);

qS(idx_sort) = q_sort;


q_region_map_S = NaN(size(mask_S));

q_region_map_S(mask_S) = qS;


%% -------------------------
% Timor
%% -------------------------

pT = p_adj_map_T(mask_T);

mT = length(pT);


[p_sort,idx_sort] = sort(pT);


q_sort = ...
    p_sort .* mT ./ (1:mT)';


for k = mT-1:-1:1

    q_sort(k) = ...
        min(q_sort(k),q_sort(k+1));

end


q_sort = min(q_sort,1);


qT = NaN(mT,1);

qT(idx_sort) = q_sort;


q_region_map_T = NaN(size(mask_T));

q_region_map_T(mask_T) = qT;


%% =========================================================
% 13. GLOBAL FDR ACROSS ALL VALID GRIDS
%
% Sensitivity check:
%
% Flores + Sumba + Timor
%% =========================================================

p_all = [...
    pF;...
    pS;...
    pT];


m_all = length(p_all);


[p_sort,idx_sort] = ...
    sort(p_all);


q_sort = ...
    p_sort .* m_all ./ (1:m_all)';


for k = m_all-1:-1:1

    q_sort(k) = ...
        min(q_sort(k),q_sort(k+1));

end


q_sort = ...
    min(q_sort,1);


q_all = NaN(m_all,1);

q_all(idx_sort) = q_sort;


%% =========================================================
% 14. SPLIT GLOBAL FDR BACK INTO REGIONS
%% =========================================================

q_all_F = ...
    q_all(1:mF);


q_all_S = ...
    q_all(mF+1:mF+mS);


q_all_T = ...
    q_all(mF+mS+1:end);


q_global_map_F = ...
    NaN(size(mask_F));

q_global_map_S = ...
    NaN(size(mask_S));

q_global_map_T = ...
    NaN(size(mask_T));


q_global_map_F(mask_F) = ...
    q_all_F;

q_global_map_S(mask_S) = ...
    q_all_S;

q_global_map_T(mask_T) = ...
    q_all_T;


%% =========================================================
% 15. SPATIAL CORRELATION SUMMARY
%% =========================================================

rF_values = r_map_F(mask_F);
rS_values = r_map_S(mask_S);
rT_values = r_map_T(mask_T);


neffF_values = Neff_map_F(mask_F);
neffS_values = Neff_map_S(mask_S);
neffT_values = Neff_map_T(mask_T);


%% ---------------------------------------------------------
% Basic spatial statistics
%% ---------------------------------------------------------

r_min = [...
    min(rF_values);...
    min(rS_values);...
    min(rT_values)];


r_max = [...
    max(rF_values);...
    max(rS_values);...
    max(rT_values)];


r_mean = [...
    mean(rF_values);...
    mean(rS_values);...
    mean(rT_values)];


r_median = [...
    median(rF_values);...
    median(rS_values);...
    median(rT_values)];


r_std = [...
    std(rF_values);...
    std(rS_values);...
    std(rT_values)];


Positive_grid_percent = [...
    100*sum(rF_values>0)/length(rF_values);...
    100*sum(rS_values>0)/length(rS_values);...
    100*sum(rT_values>0)/length(rT_values)];


%% ---------------------------------------------------------
% Significance counts
%% ---------------------------------------------------------

N_grid = [...
    nmask_F;...
    nmask_S;...
    nmask_T];


N_padj_lt_005 = [...
    sum(pF<0.05);...
    sum(pS<0.05);...
    sum(pT<0.05)];


N_FDR_region_lt_005 = [...
    sum(qF<0.05);...
    sum(qS<0.05);...
    sum(qT<0.05)];


N_FDR_global_lt_005 = [...
    sum(q_all_F<0.05);...
    sum(q_all_S<0.05);...
    sum(q_all_T<0.05)];


Neff_min = [...
    min(neffF_values);...
    min(neffS_values);...
    min(neffT_values)];


Neff_max = [...
    max(neffF_values);...
    max(neffS_values);...
    max(neffT_values)];


%% =========================================================
% 16. CREATE SUMMARY TABLE
%% =========================================================

RegionSummary = {...
    'Flores';...
    'Sumba';...
    'Timor'};


SummaryTable = table(...
    RegionSummary,...
    N_grid,...
    r_min,...
    r_max,...
    r_mean,...
    r_median,...
    r_std,...
    Positive_grid_percent,...
    Neff_min,...
    Neff_max,...
    N_padj_lt_005,...
    N_FDR_region_lt_005,...
    N_FDR_global_lt_005,...
    'VariableNames',{...
    'Region',...
    'Valid_grids',...
    'r_min',...
    'r_max',...
    'r_mean',...
    'r_median',...
    'r_std',...
    'Positive_grid_percent',...
    'Neff_min',...
    'Neff_max',...
    'N_padj_lt_0_05',...
    'N_FDR_region_lt_0_05',...
    'N_FDR_global_lt_0_05'});


%% =========================================================
% 17. DISPLAY SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SPATIAL CORRELATION SUMMARY\n')
fprintf('=========================================================\n')

disp(SummaryTable)


fprintf('\n')
fprintf('FDR-significant grid counts (regional correction):\n')

fprintf('Flores = %d / %d\n',...
    N_FDR_region_lt_005(1),...
    nmask_F);

fprintf('Sumba  = %d / %d\n',...
    N_FDR_region_lt_005(2),...
    nmask_S);

fprintf('Timor  = %d / %d\n',...
    N_FDR_region_lt_005(3),...
    nmask_T);


%% =========================================================
% 18. CREATE GRID COORDINATE MATRICES
%% =========================================================

[LonF,LatF] = ...
    ndgrid(lon_F,lat_F);


[LonS,LatS] = ...
    ndgrid(lon_S,lat_S);


[LonT,LatT] = ...
    ndgrid(lon_T,lat_T);


%% =========================================================
% 19. CREATE LONG GRID RESULT TABLE
%% =========================================================

%% -------------------------
% Flores
%% -------------------------

Region_F = ...
    repmat({'Flores'},nmask_F,1);


TableF = table(...
    Region_F,...
    LonF(mask_F),...
    LatF(mask_F),...
    N_map_F(mask_F),...
    r_map_F(mask_F),...
    r1_rain_map_F(mask_F),...
    Neff_map_F(mask_F),...
    p_raw_map_F(mask_F),...
    p_adj_map_F(mask_F),...
    q_region_map_F(mask_F),...
    q_global_map_F(mask_F),...
    'VariableNames',{...
    'Region',...
    'Longitude',...
    'Latitude',...
    'N',...
    'Pearson_r',...
    'Rain_lag1',...
    'N_effective',...
    'p_raw',...
    'p_autocorr_adjusted',...
    'q_FDR_region',...
    'q_FDR_all_grids'});


%% -------------------------
% Sumba
%% -------------------------

Region_S = ...
    repmat({'Sumba'},nmask_S,1);


TableS = table(...
    Region_S,...
    LonS(mask_S),...
    LatS(mask_S),...
    N_map_S(mask_S),...
    r_map_S(mask_S),...
    r1_rain_map_S(mask_S),...
    Neff_map_S(mask_S),...
    p_raw_map_S(mask_S),...
    p_adj_map_S(mask_S),...
    q_region_map_S(mask_S),...
    q_global_map_S(mask_S),...
    'VariableNames',{...
    'Region',...
    'Longitude',...
    'Latitude',...
    'N',...
    'Pearson_r',...
    'Rain_lag1',...
    'N_effective',...
    'p_raw',...
    'p_autocorr_adjusted',...
    'q_FDR_region',...
    'q_FDR_all_grids'});


%% -------------------------
% Timor
%% -------------------------

Region_T = ...
    repmat({'Timor'},nmask_T,1);


TableT = table(...
    Region_T,...
    LonT(mask_T),...
    LatT(mask_T),...
    N_map_T(mask_T),...
    r_map_T(mask_T),...
    r1_rain_map_T(mask_T),...
    Neff_map_T(mask_T),...
    p_raw_map_T(mask_T),...
    p_adj_map_T(mask_T),...
    q_region_map_T(mask_T),...
    q_global_map_T(mask_T),...
    'VariableNames',{...
    'Region',...
    'Longitude',...
    'Latitude',...
    'N',...
    'Pearson_r',...
    'Rain_lag1',...
    'N_effective',...
    'p_raw',...
    'p_autocorr_adjusted',...
    'q_FDR_region',...
    'q_FDR_all_grids'});


GridResultTable = [...
    TableF;...
    TableS;...
    TableT];


%% =========================================================
% 20. SAVE MAT FILE
%% =========================================================

save(...
    'spatial_correlation_results.mat',...
    'lon_F','lat_F',...
    'lon_S','lat_S',...
    'lon_T','lat_T',...
    'mask_F','mask_S','mask_T',...
    'r_map_F','r_map_S','r_map_T',...
    'p_raw_map_F','p_raw_map_S','p_raw_map_T',...
    'p_adj_map_F','p_adj_map_S','p_adj_map_T',...
    'N_map_F','N_map_S','N_map_T',...
    'Neff_map_F','Neff_map_S','Neff_map_T',...
    'r1_rain_map_F',...
    'r1_rain_map_S',...
    'r1_rain_map_T',...
    'r1_sst_F','r1_sst_S','r1_sst_T',...
    'q_region_map_F',...
    'q_region_map_S',...
    'q_region_map_T',...
    'q_global_map_F',...
    'q_global_map_S',...
    'q_global_map_T',...
    'SummaryTable',...
    'GridResultTable',...
    '-v7.3');


%% =========================================================
% 21. SAVE CSV FILES
%% =========================================================

writetable(...
    SummaryTable,...
    'spatial_correlation_summary.csv');


writetable(...
    GridResultTable,...
    'spatial_correlation_grid_results.csv');


%% =========================================================
% 22. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SPATIAL CORRELATION ANALYSIS COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n')

fprintf('1. spatial_correlation_results.mat\n')
fprintf('2. spatial_correlation_summary.csv\n')
fprintf('3. spatial_correlation_grid_results.csv\n')


fprintf('\nPrimary spatial inference:\n')

fprintf(['BH-FDR correction is applied separately ',...
         'within each regional spatial field.\n']);


fprintf('\nSensitivity check:\n')

fprintf(['A second BH-FDR correction is applied across ',...
         'all Flores + Sumba + Timor grids.\n']);


fprintf('\nNext step:\n')

fprintf(['03_Plot_Spatial_Correlation.m will display ',...
         'the complete spatial r fields and overlay ',...
         'FDR-significant grids if present.\n']);