%% ========================================================================
% e_compile_seasonal_uncertainty.m
% READABLE 12-TEST UNCERTAINTY TABLE FOR REVIEWERS
% MATLAB R2021a | Place in Data/04_Seasonal_Analysis/
%
% INPUTS (same folder):
%   seasonal_robustness_results.csv       (from script c)
%   seasonal_annual_dependence_QC.csv    (from script d)
% OUTPUT (same folder): seasonal_uncertainty_summary.csv
%
% This script only COMPILES previously calculated results.
% It does not change statistical methods or re-run permutations.
%% ========================================================================
clc;
clear;
this_script = mfilename('fullpath');
if isempty(this_script), error('Save the script as an .m file.'); end
folder_out = fileparts(this_script);
f_rob = fullfile(folder_out,'seasonal_robustness_results.csv');
f_dep = fullfile(folder_out,'seasonal_annual_dependence_QC.csv');
if ~isfile(f_rob) || ~isfile(f_dep)
    error('Missing input(s). Run c_seasonal_robustness.m and d_check_seasonal_annual_dependence.m first.');
end
T = readtable(f_rob);
D = readtable(f_dep);
needed = {'Region','Season','N','Pearson_r','CI95_lower','CI95_upper', ...
    'p_permutation','q_FDR_permutation','LOYO_min_r','LOYO_max_r', ...
    'LOYO_same_sign_percent'};
if height(T)~=12 || height(D)~=12 || ...
        ~all(ismember(needed,T.Properties.VariableNames))
    error('Input CSV format or number of tests is unexpected.');
end

Annual_adjacent_pairs = NaN(12,1);
SST_annual_lag1 = NaN(12,1);
Rain_annual_lag1 = NaN(12,1);
FDR_interpretation = cell(12,1);
for k=1:12
    ii = strcmp(string(D.Region),string(T.Region(k))) & ...
         strcmp(string(D.Season),string(T.Season(k)));
    if sum(ii)~=1
        error('Could not uniquely match dependence QC for row %d.',k);
    end
    if T.N(k) ~= D.N_seasons(ii) || ...
         abs(T.Pearson_r(k)-D.Pearson_r(ii))>1e-8
        error('Mismatch between seasonal robustness and annual QC at row %d.',k);
    end
    Annual_adjacent_pairs(k) = D.N_adjacent_pairs(ii);
    SST_annual_lag1(k) = D.SST_lag1_annual(ii);
    Rain_annual_lag1(k) = D.Rain_lag1_annual(ii);
    if T.q_FDR_permutation(k) < 0.05
        FDR_interpretation{k} = 'FDR-retained (q<0.05)';
    elseif T.q_FDR_permutation(k) < 0.10
        FDR_interpretation{k} = 'Suggestive only (0.05<=q<0.10)';
    else
        FDR_interpretation{k} = 'Not retained (q>=0.10)';
    end
end

Summary = T(:,needed);
Summary.Annual_adjacent_pairs = Annual_adjacent_pairs;
Summary.SST_annual_lag1 = SST_annual_lag1;
Summary.Rain_annual_lag1 = Rain_annual_lag1;
Summary.FDR_interpretation = FDR_interpretation;
out_file = fullfile(folder_out,'seasonal_uncertainty_summary.csv');
writetable(Summary,out_file);

fprintf('\n===== SEASONAL UNCERTAINTY SUMMARY QC =====\n');
fprintf('Tests=%d; FDR q<0.05=%d; 0.05<=q<0.10=%d\n', ...
    height(Summary),sum(T.q_FDR_permutation<0.05), ...
    sum(T.q_FDR_permutation>=0.05 & T.q_FDR_permutation<0.10));
fprintf('Saved: %s\n',out_file);
fprintf(['Note: Fisher-z 95%% intervals are approximate and NOT multiple-testing ' ...
    'adjusted or serial-dependence corrected.\n']);
fprintf('Yearwise permutations do not preserve potential interannual persistence.\n');
