%% ========================================================================
% b_autocorrelation_effective_n.m
% AUTOCORRELATION-AWARE MONTHLY ZERO-LAG TEST | NTT 2016-2025
%
% MATLAB R2021a; requires Statistics and Machine Learning Toolbox.
% Save in: Data/03_Monthly_and_Lagged/
% Input:   ../02_Regional_Timeseries/regional_anomalies.mat
% Outputs: autocorrelation_effectiveN.csv/.mat (same folder as script)
%
% Analysis: 120 calendar positions, 118 paired valid SST-rainfall months.
% Pearson r uses DESEASONALIZED anomalies, not raw monthly values.
% Lag-1 autocorrelation uses ORIGINAL calendar positions. Adjacent valid
% months only: the gap Oct-Nov 2025 is NEVER compressed/bridged.
%
% Effective sample size (Bretherton/Pyper-Peterman-style approximation):
%   Neff = N * (1 - rho_SST(1)*rho_Rain(1)) /
%                (1 + rho_SST(1)*rho_Rain(1))
% bounded to 3 <= Neff <= N. Two-sided t test uses df = Neff - 2.
% Neff is an approximation; this does NOT establish causal evidence.
%% ========================================================================
clc;
clear;

%% 1. Paths and input checks
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this file as b_autocorrelation_effective_n.m first.');
end
out_dir = fileparts(script_file);
data_dir = fileparts(out_dir);
input_file = fullfile(data_dir,'02_Regional_Timeseries','regional_anomalies.mat');
if ~isfile(input_file)
    error('Input not found: %s',input_file);
end
D = load(input_file);
for name = {'time','SST_deseason','RAIN_deseason'}
    if ~isfield(D,name{1})
        error('Input MAT missing: %s',name{1});
    end
end
if ~isequal(size(D.SST_deseason),[120,3]) || ...
        ~isequal(size(D.RAIN_deseason),[120,3]) || ...
        ~isdatetime(D.time) || numel(D.time)~=120
    error('Expected 120 monthly observations x 3 regions and datetime time.');
end
expected_time = datetime(2016,1,1)+calmonths((0:119)');
if ~all(D.time(:)==expected_time)
    error('Monthly time positions are not Jan 2016 - Dec 2025.');
end

%% 2. Pearson r, valid adjacent-month rho1 and adjusted significance
Region = {'Flores';'Sumba';'Timor'};
N_original = NaN(3,1);
Pearson_r = NaN(3,1);
p_raw = NaN(3,1);
SST_lag1 = NaN(3,1);
Rain_lag1 = NaN(3,1);
SST_adjacent_pairs = NaN(3,1);
Rain_adjacent_pairs = NaN(3,1);
N_effective = NaN(3,1);
N_reduction_percent = NaN(3,1);
p_autocorr_adjusted = NaN(3,1);

for ir = 1:3
    x = D.SST_deseason(:,ir);    % uncompressed calendar timeline
    y = D.RAIN_deseason(:,ir);
    paired = isfinite(x) & isfinite(y);
    n = sum(paired);
    if n<4
        error('Insufficient paired data for %s.',Region{ir});
    end
    N_original(ir) = n;
    [Pearson_r(ir),p_raw(ir)] = corr(x(paired),y(paired),'Type','Pearson');

    % Adjacent months ONLY (do not remove NaNs before building lag pairs).
    valid_x = isfinite(x(1:end-1)) & isfinite(x(2:end));
    valid_y = isfinite(y(1:end-1)) & isfinite(y(2:end));
    SST_adjacent_pairs(ir) = sum(valid_x);
    Rain_adjacent_pairs(ir) = sum(valid_y);
    if sum(valid_x)<3 || sum(valid_y)<3
        error('Too few adjacent-month pairs for %s.',Region{ir});
    end
    SST_lag1(ir) = corr(x(find(valid_x)),x(find(valid_x)+1), ...
        'Type','Pearson');
    Rain_lag1(ir) = corr(y(find(valid_y)),y(find(valid_y)+1), ...
        'Type','Pearson');

    rho_product = SST_lag1(ir)*Rain_lag1(ir);
    if ~isfinite(rho_product) || (1+rho_product)<=0
        error('Invalid rho(1) product for %s.',Region{ir});
    end
    n_eff = n*(1-rho_product)/(1+rho_product);
    n_eff = max(3,min(n,n_eff));
    N_effective(ir) = n_eff;
    N_reduction_percent(ir) = 100*(1-n_eff/n);

    df = n_eff-2;
    rr = max(-1,min(1,Pearson_r(ir)));
    if abs(rr)==1
        p_autocorr_adjusted(ir) = 0;
    else
        t_value = rr*sqrt(df/(1-rr^2));
        p_autocorr_adjusted(ir) = 2*tcdf(-abs(t_value),df);
    end
end

%% 3. Save
Results = table(Region,Pearson_r,N_original,SST_lag1,Rain_lag1, ...
    SST_adjacent_pairs,Rain_adjacent_pairs,N_effective, ...
    N_reduction_percent,p_raw,p_autocorr_adjusted);
writetable(Results,fullfile(out_dir,'autocorrelation_effectiveN.csv'));
save(fullfile(out_dir,'autocorrelation_effectiveN.mat'), ...
    'Results','Pearson_r','N_original','SST_lag1','Rain_lag1', ...
    'SST_adjacent_pairs','Rain_adjacent_pairs','N_effective', ...
    'p_raw','p_autocorr_adjusted');

%% 4. QC
fprintf('\n===== ZERO-LAG AUTOCORRELATION / EFFECTIVE-N QC =====\n');
fprintf('Region       r        N        Neff      rhoSST     rhoRain    p_adjusted\n');
for ir = 1:3
    fprintf('%-8s  %+0.4f   %3d      %6.2f     %+0.4f    %+0.4f      %.4f\n', ...
        Region{ir},Pearson_r(ir),N_original(ir),N_effective(ir), ...
        SST_lag1(ir),Rain_lag1(ir),p_autocorr_adjusted(ir));
end
fprintf('Saved: autocorrelation_effectiveN.csv/.mat\n');
fprintf('No missing SST months are bridged when calculating lag-1.\n');
