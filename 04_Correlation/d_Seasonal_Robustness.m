%% =========================================================
% 04_Seasonal_Robustness.m
%
% ROBUSTNESS ANALYSIS OF SEASONAL SST-RAINFALL CORRELATION
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Seasons:
%   DJF
%   MAM
%   JJA
%   SON
%
% Analyses:
%   1. Pearson correlation (r)
%   2. Ordinary parametric p-value
%   3. 95% Fisher-z confidence interval
%   4. Two-sided permutation test (10,000 permutations)
%   5. Leave-One-Year-Out (LOYO) stability
%   6. Benjamini-Hochberg FDR correction
%
% FDR family:
%   12 seasonal correlation tests
%   = 3 regions x 4 seasons
%
% Input:
%   seasonal_mean_anomalies.mat
%
% Outputs:
%   seasonal_robustness_results.mat
%   seasonal_robustness_results.csv
%   seasonal_LOYO_results.csv
%
% IMPORTANT:
%   FDR correction in the main robustness result is applied
%   to permutation p-values across all 12 tests.
%
% No local functions are used.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. SETTINGS
%% =========================================================

Nperm = 10000;

% Fixed random seed for reproducibility
rng(2026,'twister');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL CORRELATION ROBUSTNESS ANALYSIS\n')
fprintf('=========================================================\n')

fprintf('Number of permutations = %d\n',Nperm);
fprintf('Random seed            = 2026\n');


%% =========================================================
% 2. LOAD SEASONAL MEAN ANOMALIES
%% =========================================================

load('seasonal_mean_anomalies.mat',...
    'years_DJF',...
    'years_MAM',...
    'years_JJA',...
    'years_SON',...
    'sstF_DJF','sstS_DJF','sstT_DJF',...
    'precF_DJF','precS_DJF','precT_DJF',...
    'sstF_MAM','sstS_MAM','sstT_MAM',...
    'precF_MAM','precS_MAM','precT_MAM',...
    'sstF_JJA','sstS_JJA','sstT_JJA',...
    'precF_JJA','precS_JJA','precT_JJA',...
    'sstF_SON','sstS_SON','sstT_SON',...
    'precF_SON','precS_SON','precT_SON');


%% =========================================================
% 3. ORGANIZE ALL 12 TESTS
%
% Order:
%   Flores DJF MAM JJA SON
%   Sumba  DJF MAM JJA SON
%   Timor  DJF MAM JJA SON
%% =========================================================

Region = {...
    'Flores';...
    'Flores';...
    'Flores';...
    'Flores';...
    'Sumba';...
    'Sumba';...
    'Sumba';...
    'Sumba';...
    'Timor';...
    'Timor';...
    'Timor';...
    'Timor'};


Season = {...
    'DJF';...
    'MAM';...
    'JJA';...
    'SON';...
    'DJF';...
    'MAM';...
    'JJA';...
    'SON';...
    'DJF';...
    'MAM';...
    'JJA';...
    'SON'};


SST = {...
    sstF_DJF;...
    sstF_MAM;...
    sstF_JJA;...
    sstF_SON;...
    sstS_DJF;...
    sstS_MAM;...
    sstS_JJA;...
    sstS_SON;...
    sstT_DJF;...
    sstT_MAM;...
    sstT_JJA;...
    sstT_SON};


RAIN = {...
    precF_DJF;...
    precF_MAM;...
    precF_JJA;...
    precF_SON;...
    precS_DJF;...
    precS_MAM;...
    precS_JJA;...
    precS_SON;...
    precT_DJF;...
    precT_MAM;...
    precT_JJA;...
    precT_SON};


YEARS = {...
    years_DJF;...
    years_MAM;...
    years_JJA;...
    years_SON;...
    years_DJF;...
    years_MAM;...
    years_JJA;...
    years_SON;...
    years_DJF;...
    years_MAM;...
    years_JJA;...
    years_SON};


Ntest = length(Region);


%% =========================================================
% 4. PREALLOCATE MAIN RESULT ARRAYS
%% =========================================================

N = NaN(Ntest,1);

Pearson_r = NaN(Ntest,1);

p_parametric = NaN(Ntest,1);

CI95_lower = NaN(Ntest,1);
CI95_upper = NaN(Ntest,1);

p_permutation = NaN(Ntest,1);

LOYO_min_r = NaN(Ntest,1);
LOYO_max_r = NaN(Ntest,1);
LOYO_median_r = NaN(Ntest,1);

LOYO_same_sign_percent = NaN(Ntest,1);


%% =========================================================
% 5. PREALLOCATE LONG LOYO TABLE
%% =========================================================

LOYO_region = {};
LOYO_season = {};
LOYO_removed_year = [];
LOYO_r = [];


%% =========================================================
% 6. LOOP THROUGH ALL 12 REGION-SEASON TESTS
%% =========================================================

for k = 1:Ntest

    x = SST{k};
    y = RAIN{k};
    yy = YEARS{k};


    % Make sure vectors are columns
    x = x(:);
    y = y(:);
    yy = yy(:);


    % -----------------------------------------------------
    % Pairwise valid observations
    % -----------------------------------------------------

    valid = ...
        ~isnan(x) & ...
        ~isnan(y);

    x = x(valid);
    y = y(valid);
    yy = yy(valid);


    n = length(x);

    N(k) = n;


    %% =====================================================
    % 6A. OBSERVED PEARSON CORRELATION
    %% =====================================================

    [r_obs,p_obs] = corr(...
        x,...
        y,...
        'Type','Pearson');


    Pearson_r(k) = r_obs;
    p_parametric(k) = p_obs;


    %% =====================================================
    % 6B. 95% FISHER-Z CONFIDENCE INTERVAL
    %
    % Fisher transformation:
    %
    % z = atanh(r)
    %
    % SE = 1/sqrt(n-3)
    %
    % 95% CI = z +/- 1.96*SE
    %% =====================================================

    if n > 3

        % Prevent numerical problem if r is exactly +/-1
        r_safe = max(min(r_obs,0.999999),-0.999999);

        z_r = atanh(r_safe);

        SE_z = 1 / sqrt(n-3);

        z_lower = z_r - 1.96*SE_z;
        z_upper = z_r + 1.96*SE_z;

        CI95_lower(k) = tanh(z_lower);
        CI95_upper(k) = tanh(z_upper);

    end


    %% =====================================================
    % 6C. TWO-SIDED PERMUTATION TEST
    %
    % Null hypothesis:
    % SST and rainfall are not associated.
    %
    % Rainfall years are randomly shuffled relative to SST.
    %% =====================================================

    r_perm = NaN(Nperm,1);


    % Center variables once
    xc = x - mean(x);
    yc = y - mean(y);


    denominator = ...
        sqrt(sum(xc.^2) * sum(yc.^2));


    for b = 1:Nperm

        idx_perm = randperm(n);

        yc_perm = yc(idx_perm);

        r_perm(b) = ...
            sum(xc .* yc_perm) / denominator;

    end


    % Two-sided test
    %
    % +1 correction prevents p = 0

    p_permutation(k) = ...
        (1 + sum(abs(r_perm) >= abs(r_obs))) / ...
        (Nperm + 1);


    %% =====================================================
    % 6D. LEAVE-ONE-YEAR-OUT ANALYSIS
    %
    % One seasonal year is removed at a time.
    %% =====================================================

    r_loyo = NaN(n,1);


    for j = 1:n

        keep = true(n,1);

        keep(j) = false;


        x_temp = x(keep);
        y_temp = y(keep);


        r_temp = corr(...
            x_temp,...
            y_temp,...
            'Type','Pearson');


        r_loyo(j) = r_temp;


        % Save into long LOYO table

        LOYO_region{end+1,1} = Region{k};

        LOYO_season{end+1,1} = Season{k};

        LOYO_removed_year(end+1,1) = yy(j);

        LOYO_r(end+1,1) = r_temp;

    end


    %% =====================================================
    % 6E. LOYO SUMMARY
    %% =====================================================

    LOYO_min_r(k) = min(r_loyo);

    LOYO_max_r(k) = max(r_loyo);

    LOYO_median_r(k) = median(r_loyo);


    % Percentage of LOYO correlations retaining
    % the same sign as the full-sample correlation

    if r_obs > 0

        same_sign = sum(r_loyo > 0);

    elseif r_obs < 0

        same_sign = sum(r_loyo < 0);

    else

        same_sign = sum(r_loyo == 0);

    end


    LOYO_same_sign_percent(k) = ...
        100 * same_sign / n;


    %% =====================================================
    % 6F. PROGRESS DISPLAY
    %% =====================================================

    fprintf('\n')

    fprintf('%s %s\n',...
        Region{k},...
        Season{k});

    fprintf('n             = %d\n',n);

    fprintf('r             = %+0.4f\n',r_obs);

    fprintf('p parametric  = %.4f\n',p_obs);

    fprintf('95%% CI         = [%+0.4f, %+0.4f]\n',...
        CI95_lower(k),...
        CI95_upper(k));

    fprintf('p permutation = %.4f\n',...
        p_permutation(k));

    fprintf('LOYO range    = [%+0.4f, %+0.4f]\n',...
        LOYO_min_r(k),...
        LOYO_max_r(k));

    fprintf('Same sign     = %.1f %%\n',...
        LOYO_same_sign_percent(k));

end


%% =========================================================
% 7. BENJAMINI-HOCHBERG FDR
%
% Main FDR correction is applied to the 12
% permutation p-values.
%% =========================================================

m = Ntest;


[p_sorted,sort_index] = sort(p_permutation);


q_sorted = ...
    p_sorted .* m ./ (1:m)';


% Enforce monotonicity from largest rank backwards

for i = m-1:-1:1

    q_sorted(i) = ...
        min(q_sorted(i),q_sorted(i+1));

end


q_sorted = min(q_sorted,1);


q_FDR_permutation = NaN(m,1);

q_FDR_permutation(sort_index) = q_sorted;


%% =========================================================
% 8. ALSO CALCULATE BH-FDR FROM PARAMETRIC P
%
% Saved for comparison/QC only.
%% =========================================================

[p_sorted_param,sort_index_param] = ...
    sort(p_parametric);


q_sorted_param = ...
    p_sorted_param .* m ./ (1:m)';


for i = m-1:-1:1

    q_sorted_param(i) = ...
        min(q_sorted_param(i),...
            q_sorted_param(i+1));

end


q_sorted_param = ...
    min(q_sorted_param,1);


q_FDR_parametric = NaN(m,1);

q_FDR_parametric(sort_index_param) = ...
    q_sorted_param;


%% =========================================================
% 9. FDR STATUS
%% =========================================================

FDR_status = cell(Ntest,1);


for k = 1:Ntest

    if q_FDR_permutation(k) < 0.05

        FDR_status{k} = 'q<0.05';

    elseif q_FDR_permutation(k) < 0.10

        FDR_status{k} = '0.05<=q<0.10';

    else

        FDR_status{k} = 'q>=0.10';

    end

end


%% =========================================================
% 10. CREATE MAIN RESULT TABLE
%% =========================================================

ResultTable = table(...
    Region,...
    Season,...
    N,...
    Pearson_r,...
    p_parametric,...
    CI95_lower,...
    CI95_upper,...
    p_permutation,...
    q_FDR_permutation,...
    q_FDR_parametric,...
    LOYO_min_r,...
    LOYO_max_r,...
    LOYO_median_r,...
    LOYO_same_sign_percent,...
    FDR_status,...
    'VariableNames',{...
    'Region',...
    'Season',...
    'N',...
    'Pearson_r',...
    'p_parametric',...
    'CI95_lower',...
    'CI95_upper',...
    'p_permutation',...
    'q_FDR_permutation',...
    'q_FDR_parametric',...
    'LOYO_min_r',...
    'LOYO_max_r',...
    'LOYO_median_r',...
    'LOYO_same_sign_percent',...
    'FDR_status'});


%% =========================================================
% 11. CREATE LONG LOYO RESULT TABLE
%% =========================================================

LOYOTable = table(...
    LOYO_region,...
    LOYO_season,...
    LOYO_removed_year,...
    LOYO_r,...
    'VariableNames',{...
    'Region',...
    'Season',...
    'Removed_year',...
    'Pearson_r_after_removal'});


%% =========================================================
% 12. DISPLAY FINAL ROBUSTNESS TABLE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL SEASONAL ROBUSTNESS RESULTS\n')
fprintf('=========================================================\n')

fprintf('\n')
fprintf(['Region    Season    n       r       ',...
         'p_perm     q_FDR      LOYO range       SameSign\n'])

fprintf(['---------------------------------------------------------',...
         '------------------\n'])


for k = 1:Ntest

    fprintf('%-9s %-6s   %2d   %+0.4f    %.4f     %.4f   ',...
        Region{k},...
        Season{k},...
        N(k),...
        Pearson_r(k),...
        p_permutation(k),...
        q_FDR_permutation(k));

    fprintf('[%+0.3f,%+0.3f]    %5.1f%%\n',...
        LOYO_min_r(k),...
        LOYO_max_r(k),...
        LOYO_same_sign_percent(k));

end


%% =========================================================
% 13. DISPLAY 95% CONFIDENCE INTERVAL
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('95%% FISHER CONFIDENCE INTERVAL\n')
fprintf('=========================================================\n')

fprintf('\n')
fprintf('Region      Season       r          95%% CI\n')
fprintf('-------------------------------------------------\n')


for k = 1:Ntest

    fprintf('%-10s  %-5s    %+0.4f    [%+0.4f, %+0.4f]\n',...
        Region{k},...
        Season{k},...
        Pearson_r(k),...
        CI95_lower(k),...
        CI95_upper(k));

end


%% =========================================================
% 14. DISPLAY RESULTS RETAINED AT FDR q < 0.05
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('RESULTS RETAINED AFTER BH-FDR (q < 0.05)\n')
fprintf('=========================================================\n')


idx_sig = ...
    q_FDR_permutation < 0.05;


if any(idx_sig)

    for k = 1:Ntest

        if idx_sig(k)

            fprintf('%s %s : r = %+0.4f | p_perm = %.4f | q = %.4f\n',...
                Region{k},...
                Season{k},...
                Pearson_r(k),...
                p_permutation(k),...
                q_FDR_permutation(k));

        end

    end

else

    fprintf('No seasonal correlations retained at q < 0.05.\n');

end


%% =========================================================
% 15. DISPLAY q BETWEEN 0.05 AND 0.10
%
% These should NOT be called significant at q < 0.05.
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('RESULTS WITH 0.05 <= q < 0.10\n')
fprintf('=========================================================\n')


idx_q10 = ...
    q_FDR_permutation >= 0.05 & ...
    q_FDR_permutation < 0.10;


if any(idx_q10)

    for k = 1:Ntest

        if idx_q10(k)

            fprintf('%s %s : r = %+0.4f | p_perm = %.4f | q = %.4f\n',...
                Region{k},...
                Season{k},...
                Pearson_r(k),...
                p_permutation(k),...
                q_FDR_permutation(k));

        end

    end

else

    fprintf('No results in this q-value range.\n');

end


%% =========================================================
% 16. SAVE CSV FILES
%% =========================================================

writetable(...
    ResultTable,...
    'seasonal_robustness_results.csv');


writetable(...
    LOYOTable,...
    'seasonal_LOYO_results.csv');


%% =========================================================
% 17. SAVE MAT FILE
%% =========================================================

save(...
    'seasonal_robustness_results.mat',...
    'ResultTable',...
    'LOYOTable',...
    'Region',...
    'Season',...
    'N',...
    'Pearson_r',...
    'p_parametric',...
    'CI95_lower',...
    'CI95_upper',...
    'p_permutation',...
    'q_FDR_permutation',...
    'q_FDR_parametric',...
    'LOYO_min_r',...
    'LOYO_max_r',...
    'LOYO_median_r',...
    'LOYO_same_sign_percent',...
    'FDR_status',...
    'Nperm');


%% =========================================================
% 18. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL ROBUSTNESS ANALYSIS COMPLETED\n')
fprintf('=========================================================\n')

fprintf('\nFiles saved:\n')

fprintf('1. seasonal_robustness_results.mat\n')
fprintf('2. seasonal_robustness_results.csv\n')
fprintf('3. seasonal_LOYO_results.csv\n')


fprintf('\nInterpretation guide:\n')

fprintf(['1. Pearson r describes the strength and direction ',...
         'of the seasonal association.\n']);

fprintf(['2. 95%% CI describes uncertainty around r.\n']);

fprintf(['3. Permutation p tests whether |r| is unusually large ',...
         'under random SST-rainfall pairing.\n']);

fprintf(['4. LOYO tests whether the result depends strongly ',...
         'on a single year.\n']);

fprintf(['5. q_FDR controls multiple testing across all ',...
         '12 region-season correlations.\n']);

fprintf('\n')
fprintf(['For the final manuscript, do not use p < 0.05 alone ',...
         'to identify robust seasonal relationships.\n']);

fprintf(['Interpret permutation p, FDR q, confidence interval, ',...
         'and LOYO stability together.\n']);