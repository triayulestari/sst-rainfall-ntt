%% ========================================================================
% b_seasonal_correlation.m
% BASIC SEASONAL PEARSON CORRELATION | NTT 2016-2025
%
% MATLAB R2021a; requires Statistics and Machine Learning Toolbox (corr).
% Input : seasonal_mean_anomalies.mat (same folder)
% Outputs: seasonal_correlation_basic.csv/.mat (same folder)
%
% NOTE: These are ordinary parametric p-values, NOT permutation p-values.
%       The main inference (10,000 permutations and BH-FDR across 12 tests)
%       is performed in c_seasonal_robustness.m.
%% ========================================================================
clc;
clear;

script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as b_seasonal_correlation.m first.');
end
out_dir = fileparts(script_file);
in_file = fullfile(out_dir,'seasonal_mean_anomalies.mat');
if ~isfile(in_file)
    error('Missing %s. Run a_seasonal_mean_anomalies.m first.',in_file);
end
D = load(in_file,'Seasonal');
if ~isfield(D,'Seasonal')
    error('Input MAT has no Seasonal struct.');
end
regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};
n_tests = 12;
Region = cell(n_tests,1);
Season = cell(n_tests,1);
N = NaN(n_tests,1);
Pearson_r = NaN(n_tests,1);
p_parametric = NaN(n_tests,1);

k = 0;
for ir = 1:3
    for is = 1:4
        k = k+1;
        ss = seasons{is};
        if ~isfield(D.Seasonal,ss)
            error('Missing seasonal field %s.',ss);
        end
        x = D.Seasonal.(ss).SST(:,ir);
        y = D.Seasonal.(ss).RAIN(:,ir);
        valid = isfinite(x) & isfinite(y);
        n = sum(valid);
        expected_n = numel(D.Seasonal.(ss).Year);
        if n ~= expected_n || n < 5
            error('%s %s: expected %d complete season-year pairs, got %d.', ...
                regions{ir},ss,expected_n,n);
        end
        Region{k} = regions{ir};
        Season{k} = ss;
        N(k) = n;
        [Pearson_r(k),p_parametric(k)] = corr(x(valid),y(valid),'Type','Pearson');
    end
end

CorrelationTable = table(Region,Season,N,Pearson_r,p_parametric);
writetable(CorrelationTable,fullfile(out_dir,'seasonal_correlation_basic.csv'));
save(fullfile(out_dir,'seasonal_correlation_basic.mat'), ...
    'CorrelationTable','Region','Season','N','Pearson_r','p_parametric');

fprintf('\n===== BASIC SEASONAL CORRELATION QC =====\n');
fprintf('Region     Season    N       r         p_parametric\n');
for k = 1:n_tests
    fprintf('%-9s  %-5s   %2d    %+0.4f      %.4f\n', ...
        Region{k},Season{k},N(k),Pearson_r(k),p_parametric(k));
end
fprintf('Saved: seasonal_correlation_basic.csv/.mat\n');
fprintf('Do not infer statistical significance before c_seasonal_robustness.m.\n');
