%% ========================================================================
% c_seasonal_robustness.m
% SEASONAL CORRELATION UNCERTAINTY AND ROBUSTNESS | NTT 2016-2025
%
% MATLAB R2021a; requires Statistics and Machine Learning Toolbox (corr).
% Input : seasonal_mean_anomalies.mat (same folder)
% Outputs (same folder):
%   seasonal_robustness_results.csv
%   seasonal_robustness_results.mat
%   seasonal_LOYO_results.csv
%
% 12 tests ordered Flores(DJF,MAM,JJA,SON), Sumba(...), Timor(...).
% 10,000 two-sided permutations; rng(2026,'twister') initialized once.
% Yearwise rainfall observations are permuted against fixed seasonal SST.
% BH-FDR is applied to ALL 12 permutation p-values (not per island).
% 95% Fisher-z CI is an approximate iid CI (n=9 or 10 only).
% LOYO removes one season-year at a time (DJF year = Jan/Feb year).
%
% CAUTION: Unrestricted yearwise permutations do not preserve potential
% serial dependence / ENSO-IOD persistence. This is a sensitivity method,
% not proof of exchangeability or causality.
%% ========================================================================
clc;
clear;

%% 1. Reproducible settings and input
Nperm = 10000;
seed = 2026;
rng(seed,'twister');
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as c_seasonal_robustness.m first.');
end
out_dir = fileparts(script_file);
in_file = fullfile(out_dir,'seasonal_mean_anomalies.mat');
if ~isfile(in_file)
    error('Missing %s. Run a_seasonal_mean_anomalies.m first.',in_file);
end
D = load(in_file,'Seasonal');
if ~isfield(D,'Seasonal')
    error('Input MAT does not contain Seasonal struct.');
end
regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};
n_tests = 12;

%% 2. Allocate 12 tests and LOYO long-format audit fields
Region = cell(n_tests,1);
Season = cell(n_tests,1);
N = NaN(n_tests,1);
Pearson_r = NaN(n_tests,1);
p_parametric = NaN(n_tests,1);
CI95_lower = NaN(n_tests,1);
CI95_upper = NaN(n_tests,1);
p_permutation = NaN(n_tests,1);
LOYO_min_r = NaN(n_tests,1);
LOYO_max_r = NaN(n_tests,1);
LOYO_median_r = NaN(n_tests,1);
LOYO_same_sign_percent = NaN(n_tests,1);
LOYO_region = {};
LOYO_season = {};
LOYO_removed_year = [];
LOYO_r = [];

%% 3. Observed correlation, permutation p, Fisher CI and LOYO
k = 0;
for ir = 1:3
    for is = 1:4
        k = k+1;
        ss = seasons{is};
        if ~isfield(D.Seasonal,ss)
            error('Missing season %s.',ss);
        end
        x = D.Seasonal.(ss).SST(:,ir);
        y = D.Seasonal.(ss).RAIN(:,ir);
        years = D.Seasonal.(ss).Year(:);
        x = x(:); y = y(:);
        if numel(x)~=numel(years) || numel(y)~=numel(years)
            error('Season/year length mismatch: %s %s.',regions{ir},ss);
        end
        valid = isfinite(x) & isfinite(y);
        x = x(valid);
        y = y(valid);
        years = years(valid);
        n = numel(x);
        expected_n = numel(D.Seasonal.(ss).Year);
        if n~=expected_n || n<5
            error('Incomplete season-year observations at %s %s.',regions{ir},ss);
        end
        Region{k} = regions{ir};
        Season{k} = ss;
        N(k) = n;

        [r_obs,p_obs] = corr(x,y,'Type','Pearson');
        Pearson_r(k) = r_obs;
        p_parametric(k) = p_obs;

        % Approximate 95%% Fisher-z confidence interval, n seasons.
        r_safe = max(min(r_obs,0.999999),-0.999999);
        z = atanh(r_safe);
        z_se = 1/sqrt(n-3);
        CI95_lower(k) = tanh(z-1.96*z_se);
        CI95_upper(k) = tanh(z+1.96*z_se);

        % Two-sided yearwise permutation; fixed seed at top of script.
        xc = x-mean(x);
        yc = y-mean(y);
        denom = sqrt(sum(xc.^2)*sum(yc.^2));
        if ~isfinite(denom) || denom<=0
            error('Zero variance: %s %s.',regions{ir},ss);
        end
        extreme_count = 0;
        for b = 1:Nperm
            idx = randperm(n);
            r_perm = sum(xc.*yc(idx))/denom;
            if abs(r_perm) >= abs(r_obs)
                extreme_count = extreme_count+1;
            end
        end
        p_permutation(k) = (extreme_count+1)/(Nperm+1);

        % Leave-one-year-out (LOYO), one actual season-year at a time.
        rr = NaN(n,1);
        for j = 1:n
            keep = true(n,1);
            keep(j) = false;
            rr(j) = corr(x(keep),y(keep),'Type','Pearson');
            LOYO_region{end+1,1} = regions{ir}; %#ok<SAGROW>
            LOYO_season{end+1,1} = ss; %#ok<SAGROW>
            LOYO_removed_year(end+1,1) = years(j); %#ok<SAGROW>
            LOYO_r(end+1,1) = rr(j); %#ok<SAGROW>
        end
        LOYO_min_r(k) = min(rr);
        LOYO_max_r(k) = max(rr);
        LOYO_median_r(k) = median(rr);
        if r_obs > 0
            LOYO_same_sign_percent(k) = 100*sum(rr>0)/n;
        elseif r_obs < 0
            LOYO_same_sign_percent(k) = 100*sum(rr<0)/n;
        else
            LOYO_same_sign_percent(k) = 100*sum(rr==0)/n;
        end
    end
end

%% 4. BH-FDR correction of all 12 permutation p-values
if any(~isfinite(p_permutation)) || ...
        any(p_permutation<0 | p_permutation>1)
    error('Invalid permutation p-values.');
end
[ps,order] = sort(p_permutation);
qs = ps*n_tests./(1:n_tests)';
for i = n_tests-1:-1:1
    qs(i) = min(qs(i),qs(i+1));
end
qs = min(qs,1);
q_FDR_permutation = NaN(n_tests,1);
q_FDR_permutation(order) = qs;

% Parametric BH-FDR is saved for QC, not the primary conclusion.
[ps0,order0] = sort(p_parametric);
qs0 = ps0*n_tests./(1:n_tests)';
for i = n_tests-1:-1:1
    qs0(i) = min(qs0(i),qs0(i+1));
end
q_FDR_parametric = NaN(n_tests,1);
q_FDR_parametric(order0) = min(qs0,1);

FDR_status = repmat({'q>=0.10 (not retained)'},n_tests,1);
for i = 1:n_tests
    if q_FDR_permutation(i)<0.05
        FDR_status{i} = 'q<0.05 (FDR-retained)';
    elseif q_FDR_permutation(i)<0.10
        FDR_status{i} = '0.05<=q<0.10 (suggestive only)';
    end
end

%% 5. Cross-check against the basic correlation script (if available)
basic_file = fullfile(out_dir,'seasonal_correlation_basic.mat');
if isfile(basic_file)
    B = load(basic_file,'CorrelationTable');
    if ~isfield(B,'CorrelationTable') || ...
            height(B.CorrelationTable)~=12 || ...
            any(abs(B.CorrelationTable.Pearson_r-Pearson_r)>1e-10)
        error('Seasonal robustness disagrees with b_seasonal_correlation.m.');
    end
end

%% 6. Export data and settings
ResultTable = table(Region,Season,N,Pearson_r,p_parametric, ...
    CI95_lower,CI95_upper,p_permutation,q_FDR_permutation, ...
    q_FDR_parametric,LOYO_min_r,LOYO_max_r,LOYO_median_r, ...
    LOYO_same_sign_percent,FDR_status);
LOYOTable = table(LOYO_region,LOYO_season,LOYO_removed_year,LOYO_r, ...
    'VariableNames',{'Region','Season','Removed_year','Pearson_r_after_removal'});
writetable(ResultTable,fullfile(out_dir,'seasonal_robustness_results.csv'));
writetable(LOYOTable,fullfile(out_dir,'seasonal_LOYO_results.csv'));
save(fullfile(out_dir,'seasonal_robustness_results.mat'), ...
    'ResultTable','LOYOTable','Region','Season','N','Pearson_r', ...
    'p_parametric','CI95_lower','CI95_upper','p_permutation', ...
    'q_FDR_permutation','q_FDR_parametric','LOYO_min_r', ...
    'LOYO_max_r','LOYO_median_r','LOYO_same_sign_percent', ...
    'FDR_status','Nperm','seed');

%% 7. QC summary
fprintf('\n===== SEASONAL ROBUSTNESS QC =====\n');
fprintf('10,000 two-sided permutations; rng(2026,''twister'').\n');
fprintf('Primary BH-FDR family: 12 region-season comparisons.\n');
fprintf('Region     Season  N      r       p_perm    q_FDR    LOYO min/max\n');
for k = 1:n_tests
    fprintf('%-9s  %-5s  %2d   %+0.4f    %.4f    %.4f    [%+.3f,%+.3f]\n', ...
        Region{k},Season{k},N(k),Pearson_r(k),p_permutation(k), ...
        q_FDR_permutation(k),LOYO_min_r(k),LOYO_max_r(k));
end
fprintf('FDR-retained q<0.05: %d tests\n',sum(q_FDR_permutation<0.05));
fprintf('Suggestive 0.05<=q<0.10: %d tests\n', ...
    sum(q_FDR_permutation>=0.05 & q_FDR_permutation<0.10));
fprintf('Saved: seasonal_robustness_results.csv/.mat and seasonal_LOYO_results.csv\n');
fprintf('Caution: 9-10 years; year permutations assume exchangeability.\n');
