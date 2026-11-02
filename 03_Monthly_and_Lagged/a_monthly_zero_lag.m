%% ========================================================================
% a_monthly_zero_lag.m
% MONTHLY ZERO-LAG SST-RAINFALL CORRELATIONS | NTT 2016-2025
%
% MATLAB R2021a; requires Statistics and Machine Learning Toolbox (corr).
% Save in: Data/03_Monthly_and_Lagged/
% Input:   ../02_Regional_Timeseries/regional_anomalies.mat
% Outputs (saved beside this script):
%   monthly_zero_lag_correlation.csv
%   monthly_zero_lag_correlation.mat
%
% Four clearly separated analyses, for each region:
%   Raw monthly values
%   Overall-mean-centered anomalies (same Pearson r as raw)
%   Deseasonalized anomalies (calendar-month means removed)
%   Deseasonalized + linearly detrended anomalies
%
% Two-sided ordinary Pearson p-values are DESCRIPTIVE here; adjustment for
% monthly lag-1 persistence is performed by b_autocorrelation_effective_n.m.
% Oct-Nov 2025 SST remain NaN. No interpolation, randomization or unit change.
%% ========================================================================
clc;
clear;

%% 1. Resolve paths independently of MATLAB's current directory
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this file as a_monthly_zero_lag.m before running.');
end
out_dir = fileparts(script_file);
data_dir = fileparts(out_dir);
input_file = fullfile(data_dir,'02_Regional_Timeseries','regional_anomalies.mat');
if ~isfile(input_file)
    error('Input not found: %s',input_file);
end
D = load(input_file);

%% 2. Validate input variables and calendar alignment
required = {'time','SST','RAIN','SST_overall_anom','RAIN_overall_anom', ...
    'SST_deseason','RAIN_deseason', ...
    'SST_deseason_detrended','RAIN_deseason_detrended'};
for k = 1:numel(required)
    if ~isfield(D,required{k})
        error('Missing variable in input MAT: %s',required{k});
    end
end
if ~isdatetime(D.time) || numel(D.time) ~= 120
    error('Expected time as 120-element MATLAB datetime vector.');
end
time = D.time(:);
expected_time = datetime(2016,1,1) + calmonths((0:119)');
if ~all(time == expected_time)
    error('Monthly timeline is not Jan 2016 through Dec 2025 in order.');
end
for k = 2:numel(required)
    if ~isequal(size(D.(required{k})),[120,3])
        error('%s must have 120 rows x 3 columns.',required{k});
    end
end
missing = year(time)==2025 & ismember(month(time),[10 11]);
if ~all(all(isnan(D.SST(missing,:)))) || ...
        any(any(~isfinite(D.SST(~missing,:)))) || ...
        any(~isfinite(D.RAIN(:)))
    error('Unexpected missing-data pattern in regional time series.');
end

%% 3. Compute correlations (each dataset on its own valid monthly pairs)
regions = {'Flores','Sumba','Timor'};
series_names = {'Raw','Overall_mean_anomaly', ...
    'Deseasonalized','Deseasonalized_detrended'};
X = {D.SST,D.SST_overall_anom,D.SST_deseason,D.SST_deseason_detrended};
Y = {D.RAIN,D.RAIN_overall_anom,D.RAIN_deseason,D.RAIN_deseason_detrended};
nrows = 3*4;
Region = cell(nrows,1);
Series = cell(nrows,1);
N_valid_pairs = NaN(nrows,1);
Pearson_r = NaN(nrows,1);
p_raw = NaN(nrows,1);
row = 0;
for ir = 1:3
    for it = 1:4
        row = row+1;
        Region{row} = regions{ir};
        Series{row} = series_names{it};
        x = X{it}(:,ir);
        y = Y{it}(:,ir);
        valid = isfinite(x) & isfinite(y);
        N_valid_pairs(row) = sum(valid);
        if N_valid_pairs(row) < 3
            error('Too few valid pairs for %s / %s.',Region{row},Series{row});
        end
        [Pearson_r(row),p_raw(row)] = corr(x(valid),y(valid),'Type','Pearson');
    end
    base = (ir-1)*4;
    if abs(Pearson_r(base+1)-Pearson_r(base+2)) > 1e-10
        error('Overall-mean centering changed r for %s.',regions{ir});
    end
end

%% 4. Save output files
Results = table(Region,Series,N_valid_pairs,Pearson_r,p_raw);
writetable(Results,fullfile(out_dir,'monthly_zero_lag_correlation.csv'));
save(fullfile(out_dir,'monthly_zero_lag_correlation.mat'), ...
    'Results','Region','Series','N_valid_pairs','Pearson_r','p_raw');

%% 5. Print concise QC summary
fprintf('\n===== MONTHLY ZERO-LAG QC | 2016-2025 =====\n');
fprintf('Source: %s\n',input_file);
fprintf('All region-series pairs should have n = 118.\n\n');
fprintf('%-8s %5s %11s %13s %13s\n', ...
    'Region','N','r(raw)','r(deseason)','r(detrended)');
for ir = 1:3
    j = (ir-1)*4;
    fprintf('%-8s %5d %+11.4f %+13.4f %+13.4f\n',regions{ir}, ...
        N_valid_pairs(j+1),Pearson_r(j+1),Pearson_r(j+3),Pearson_r(j+4));
end
fprintf('\nSaved: monthly_zero_lag_correlation.csv/.mat\n');
fprintf('Ordinary p-values are NOT autocorrelation-adjusted.\n');
