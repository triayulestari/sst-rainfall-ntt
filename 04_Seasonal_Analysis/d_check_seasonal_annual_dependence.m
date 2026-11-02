%% ========================================================================
% d_check_seasonal_annual_dependence.m
% SEASONAL INTERANNUAL DEPENDENCE DIAGNOSTIC | 2016-2025
% MATLAB R2021a | Place in Data/04_Seasonal_Analysis/
%
% INPUT  (same folder): seasonal_mean_anomalies.mat
% OUTPUT (same folder):
%   seasonal_annual_dependence_QC.csv
%   seasonal_adjacent_year_pairs.csv
%   seasonal_annual_dependence_QC.mat
%
% Diagnostic only. This does NOT re-estimate permutation p or BH-FDR q.
% Lag-1 = consecutive *season-years* within the SAME season.
% Only truly adjacent years are paired; no gaps are bridged.
% Small lag-1 does NOT prove independence or exchangeability.
%% ========================================================================
clc;
clear;

this_script = mfilename('fullpath');
if isempty(this_script)
    error('Save file as d_check_seasonal_annual_dependence.m first.');
end
folder_out = fileparts(this_script);
input_file = fullfile(folder_out, 'seasonal_mean_anomalies.mat');
if ~isfile(input_file)
    error('Input not found: %s. Run a_seasonal_mean_anomalies.m first.',input_file);
end
D = load(input_file,'Seasonal');
if ~isfield(D,'Seasonal')
    error('Seasonal struct not found in seasonal_mean_anomalies.mat');
end
regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};

Region = cell(12,1); Season = cell(12,1);
Year_start = NaN(12,1); Year_end = NaN(12,1);
N_seasons = NaN(12,1); N_adjacent_pairs = NaN(12,1);
Pearson_r = NaN(12,1);
SST_lag1_annual = NaN(12,1); Rain_lag1_annual = NaN(12,1);

P_Region = cell(0,1); P_Season = cell(0,1);
Year_t = zeros(0,1); Year_t1 = zeros(0,1);
SST_t = zeros(0,1); SST_t1 = zeros(0,1);
Rain_t = zeros(0,1); Rain_t1 = zeros(0,1);

row = 0;
for ir=1:3
    for is=1:4
        row = row + 1;
        reg = regions{ir}; ss = seasons{is};
        Q = D.Seasonal.(ss);
        yy = double(Q.Year(:));
        x = double(Q.SST(:,ir));
        y = double(Q.RAIN(:,ir));
        if numel(yy)~=numel(x) || numel(yy)~=numel(y) || ...
                any(diff(yy)<=0)
            error('Bad season/year dimensions: %s %s.',reg,ss);
        end
        valid = isfinite(x) & isfinite(y);
        yy = yy(valid); x = x(valid); y = y(valid);
        n = numel(yy);
        if n < 5, error('Too few valid seasons: %s %s.',reg,ss); end
        adjacent = find(diff(yy)==1);
        np = numel(adjacent);

        Region{row} = reg; Season{row} = ss;
        Year_start(row) = yy(1); Year_end(row) = yy(end);
        N_seasons(row) = n; N_adjacent_pairs(row) = np;
        Pearson_r(row) = corr(x,y,'Type','Pearson');
        if np >= 3
            xa = x(adjacent); xb = x(adjacent+1);
            ya = y(adjacent); yb = y(adjacent+1);
            if std(xa)>0 && std(xb)>0
                SST_lag1_annual(row) = corr(xa,xb,'Type','Pearson');
            end
            if std(ya)>0 && std(yb)>0
                Rain_lag1_annual(row) = corr(ya,yb,'Type','Pearson');
            end
        end
        for j=1:np
            k = adjacent(j);
            P_Region{end+1,1} = reg; %#ok<SAGROW>
            P_Season{end+1,1} = ss; %#ok<SAGROW>
            Year_t(end+1,1) = yy(k); %#ok<SAGROW>
            Year_t1(end+1,1) = yy(k+1); %#ok<SAGROW>
            SST_t(end+1,1) = x(k); %#ok<SAGROW>
            SST_t1(end+1,1) = x(k+1); %#ok<SAGROW>
            Rain_t(end+1,1) = y(k); %#ok<SAGROW>
            Rain_t1(end+1,1) = y(k+1); %#ok<SAGROW>
        end
    end
end

ResultTable = table(Region,Season,Year_start,Year_end,N_seasons, ...
    N_adjacent_pairs,Pearson_r,SST_lag1_annual,Rain_lag1_annual);
PairTable = table(P_Region,P_Season,Year_t,Year_t1,SST_t,SST_t1, ...
    Rain_t,Rain_t1,'VariableNames', ...
    {'Region','Season','Year_t','Year_t_plus1', ...
     'SST_t','SST_t_plus1','Rain_t','Rain_t_plus1'});
writetable(ResultTable,fullfile(folder_out,'seasonal_annual_dependence_QC.csv'));
writetable(PairTable,fullfile(folder_out,'seasonal_adjacent_year_pairs.csv'));
save(fullfile(folder_out,'seasonal_annual_dependence_QC.mat'), ...
    'ResultTable','PairTable');

fprintf('\n===== SEASONAL ANNUAL DEPENDENCE QC =====\n');
fprintf('Region   Season   n  Adjacent pairs    SST rho1    Rain rho1\n');
for k=1:12
    fprintf('%-8s %-4s    %2d        %2d          %+0.4f      %+0.4f\n', ...
        Region{k},Season{k},N_seasons(k),N_adjacent_pairs(k), ...
        SST_lag1_annual(k),Rain_lag1_annual(k));
end
fprintf('Saved: seasonal_annual_dependence_QC.csv/.mat and seasonal_adjacent_year_pairs.csv\n');
fprintf('CAUTION: only 8-9 adjacent year pairs; this is descriptive.\n');
fprintf('This diagnostic does NOT prove exchangeability or re-test p/qFDR.\n');
