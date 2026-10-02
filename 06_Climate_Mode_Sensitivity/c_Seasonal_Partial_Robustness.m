%% =========================================================
% 04_Seasonal_Partial_Robustness.m
%
% ROBUSTNESS OF SEASONAL PARTIAL SST-RAINFALL CORRELATIONS
%
% Controls:
%   1. Niño 3.4
%   2. DMI
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Seasons:
%   DJF 2017-2025  n=9
%   MAM 2016-2025  n=10
%   JJA 2016-2025  n=10
%   SON 2016-2024  n=9
%
% Robustness procedures:
%   - 10,000 permutation tests
%   - Fisher-z 95% confidence interval
%   - Leave-One-Year-Out (LOYO)
%   - LOYO sign stability
%   - Benjamini-Hochberg FDR
%
% IMPORTANT:
%   Niño3.4 and DMI are treated as separate
%   sensitivity-analysis families.
%
% Input:
%   seasonal_partial_correlation_results.mat
%
% Outputs:
%   seasonal_partial_robustness_results.mat
%   seasonal_partial_robustness_results.csv
%
% MATLAB R2021a
% No local functions.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. SETTINGS
%% =========================================================

n_perm = 10000;

rng_seed = 2026;

rng(rng_seed,'twister');


%% =========================================================
% 2. LOAD SCRIPT 03 RESULTS
%% =========================================================

load(...
    'seasonal_partial_correlation_results.mat',...
    'ResultsTable',...
    'SST_DJF',...
    'RAIN_DJF',...
    'SST_MAM',...
    'RAIN_MAM',...
    'SST_JJA',...
    'RAIN_JJA',...
    'SST_SON',...
    'RAIN_SON',...
    'NINO_DJF',...
    'NINO_MAM',...
    'NINO_JJA',...
    'NINO_SON',...
    'DMI_DJF',...
    'DMI_MAM',...
    'DMI_JJA',...
    'DMI_SON',...
    'years_DJF',...
    'years_MAM',...
    'years_JJA',...
    'years_SON');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL PARTIAL CORRELATION ROBUSTNESS\n')
fprintf('=========================================================\n')


fprintf('Permutation iterations = %d\n',n_perm);

fprintf('Random seed            = %d\n',rng_seed);


%% =========================================================
% 3. REGION / SEASON DEFINITIONS
%% =========================================================

region_names = {...
    'Flores';...
    'Sumba';...
    'Timor'};


season_names = {...
    'DJF';...
    'MAM';...
    'JJA';...
    'SON'};


n_tests = 12;


%% =========================================================
% 4. PREALLOCATE OUTPUT ARRAYS
%% =========================================================

Region = cell(n_tests,1);

Season = cell(n_tests,1);

N = NaN(n_tests,1);

Original_r = NaN(n_tests,1);


%% ---------------------------------------------------------
% Niño3.4 robustness
%% ---------------------------------------------------------

Partial_Nino_r = NaN(n_tests,1);

Nino_CI_low = NaN(n_tests,1);

Nino_CI_high = NaN(n_tests,1);

Nino_p_perm = NaN(n_tests,1);

Nino_q_FDR = NaN(n_tests,1);

Nino_LOYO_min = NaN(n_tests,1);

Nino_LOYO_max = NaN(n_tests,1);

Nino_LOYO_mean = NaN(n_tests,1);

Nino_LOYO_sign_percent = NaN(n_tests,1);


%% ---------------------------------------------------------
% DMI robustness
%% ---------------------------------------------------------

Partial_DMI_r = NaN(n_tests,1);

DMI_CI_low = NaN(n_tests,1);

DMI_CI_high = NaN(n_tests,1);

DMI_p_perm = NaN(n_tests,1);

DMI_q_FDR = NaN(n_tests,1);

DMI_LOYO_min = NaN(n_tests,1);

DMI_LOYO_max = NaN(n_tests,1);

DMI_LOYO_mean = NaN(n_tests,1);

DMI_LOYO_sign_percent = NaN(n_tests,1);


%% =========================================================
% 5. LOOP THROUGH REGIONS AND SEASONS
%% =========================================================

test_counter = 0;


for rgn = 1:3

    for s = 1:4

        test_counter = test_counter + 1;


        Region{test_counter} = ...
            region_names{rgn};


        Season{test_counter} = ...
            season_names{s};


        %% -------------------------------------------------
        % Select seasonal vectors
        %% -------------------------------------------------

        if s == 1

            x = SST_DJF(:,rgn);

            y = RAIN_DJF(:,rgn);

            z_nino = NINO_DJF;

            z_dmi = DMI_DJF;


        elseif s == 2

            x = SST_MAM(:,rgn);

            y = RAIN_MAM(:,rgn);

            z_nino = NINO_MAM;

            z_dmi = DMI_MAM;


        elseif s == 3

            x = SST_JJA(:,rgn);

            y = RAIN_JJA(:,rgn);

            z_nino = NINO_JJA;

            z_dmi = DMI_JJA;


        else

            x = SST_SON(:,rgn);

            y = RAIN_SON(:,rgn);

            z_nino = NINO_SON;

            z_dmi = DMI_SON;

        end


        %% -------------------------------------------------
        % Complete-case mask
        %% -------------------------------------------------

        valid = ...
            ~isnan(x) & ...
            ~isnan(y) & ...
            ~isnan(z_nino) & ...
            ~isnan(z_dmi);


        xv = x(valid);

        yv = y(valid);

        zn = z_nino(valid);

        zd = z_dmi(valid);


        N(test_counter) = length(xv);


        %% =================================================
        % 6. ORIGINAL SST-RAINFALL CORRELATION
        %% =================================================

        Rxy = corrcoef(xv,yv);

        Original_r(test_counter) = ...
            Rxy(1,2);


        %% =================================================
        % 7. PARTIAL CORRELATION | NIÑO3.4
        %
        % Residual method:
        %
        % SST = a + b*Niño + residual
        % Rain = a + b*Niño + residual
        %
        % partial r = correlation of residuals
        %% =================================================

        Xdesign_nino = [...
            ones(length(zn),1),...
            zn];


        beta_x_nino = ...
            Xdesign_nino \ xv;


        beta_y_nino = ...
            Xdesign_nino \ yv;


        x_res_nino = ...
            xv - Xdesign_nino*beta_x_nino;


        y_res_nino = ...
            yv - Xdesign_nino*beta_y_nino;


        Rnino = corrcoef(...
            x_res_nino,...
            y_res_nino);


        r_nino = ...
            Rnino(1,2);


        Partial_Nino_r(test_counter) = ...
            r_nino;


        %% =================================================
        % 8. 95% FISHER-Z CI | NIÑO
        %
        % For partial correlation controlling k=1 variable:
        %
        % SE = 1/sqrt(N-k-3)
        %    = 1/sqrt(N-4)
        %% =================================================

        r_safe = ...
            max(...
            min(r_nino,0.999999),...
            -0.999999);


        fisher_z = ...
            atanh(r_safe);


        fisher_se = ...
            1 / sqrt(N(test_counter)-4);


        z_low = ...
            fisher_z - 1.96*fisher_se;


        z_high = ...
            fisher_z + 1.96*fisher_se;


        Nino_CI_low(test_counter) = ...
            tanh(z_low);


        Nino_CI_high(test_counter) = ...
            tanh(z_high);


        %% =================================================
        % 9. PERMUTATION TEST | NIÑO
        %
        % Residual permutation:
        %
        % x residual remains fixed.
        % y residual is randomly permuted.
        %
        % This tests association after removing the
        % linear effect of Niño3.4.
        %% =================================================

        perm_r_nino = ...
            NaN(n_perm,1);


        for ip = 1:n_perm

            random_order = ...
                randperm(N(test_counter));


            y_perm = ...
                y_res_nino(random_order);


            Rperm = corrcoef(...
                x_res_nino,...
                y_perm);


            perm_r_nino(ip) = ...
                Rperm(1,2);

        end


        Nino_p_perm(test_counter) = ...
            (...
            sum(abs(perm_r_nino) >= abs(r_nino)) + 1 ...
            ) / ...
            (n_perm + 1);


        %% =================================================
        % 10. LOYO | NIÑO
        %% =================================================

        loyo_nino = ...
            NaN(N(test_counter),1);


        for omit = 1:N(test_counter)

            keep = ...
                true(N(test_counter),1);


            keep(omit) = false;


            x_loyo = xv(keep);

            y_loyo = yv(keep);

            z_loyo = zn(keep);


            Xdesign_loyo = [...
                ones(length(z_loyo),1),...
                z_loyo];


            bx = ...
                Xdesign_loyo \ x_loyo;


            by = ...
                Xdesign_loyo \ y_loyo;


            xr = ...
                x_loyo - ...
                Xdesign_loyo*bx;


            yr = ...
                y_loyo - ...
                Xdesign_loyo*by;


            Rloyo = corrcoef(xr,yr);


            loyo_nino(omit) = ...
                Rloyo(1,2);

        end


        Nino_LOYO_min(test_counter) = ...
            min(loyo_nino);


        Nino_LOYO_max(test_counter) = ...
            max(loyo_nino);


        Nino_LOYO_mean(test_counter) = ...
            mean(loyo_nino);


        if r_nino > 0

            Nino_LOYO_sign_percent(test_counter) = ...
                100 * ...
                sum(loyo_nino > 0) / ...
                length(loyo_nino);


        elseif r_nino < 0

            Nino_LOYO_sign_percent(test_counter) = ...
                100 * ...
                sum(loyo_nino < 0) / ...
                length(loyo_nino);


        else

            Nino_LOYO_sign_percent(test_counter) = ...
                NaN;

        end


        %% =================================================
        % 11. PARTIAL CORRELATION | DMI
        %% =================================================

        Xdesign_dmi = [...
            ones(length(zd),1),...
            zd];


        beta_x_dmi = ...
            Xdesign_dmi \ xv;


        beta_y_dmi = ...
            Xdesign_dmi \ yv;


        x_res_dmi = ...
            xv - Xdesign_dmi*beta_x_dmi;


        y_res_dmi = ...
            yv - Xdesign_dmi*beta_y_dmi;


        Rdmi = corrcoef(...
            x_res_dmi,...
            y_res_dmi);


        r_dmi = ...
            Rdmi(1,2);


        Partial_DMI_r(test_counter) = ...
            r_dmi;


        %% =================================================
        % 12. 95% FISHER-Z CI | DMI
        %% =================================================

        r_safe = ...
            max(...
            min(r_dmi,0.999999),...
            -0.999999);


        fisher_z = ...
            atanh(r_safe);


        fisher_se = ...
            1 / sqrt(N(test_counter)-4);


        z_low = ...
            fisher_z - 1.96*fisher_se;


        z_high = ...
            fisher_z + 1.96*fisher_se;


        DMI_CI_low(test_counter) = ...
            tanh(z_low);


        DMI_CI_high(test_counter) = ...
            tanh(z_high);


        %% =================================================
        % 13. PERMUTATION TEST | DMI
        %% =================================================

        perm_r_dmi = ...
            NaN(n_perm,1);


        for ip = 1:n_perm

            random_order = ...
                randperm(N(test_counter));


            y_perm = ...
                y_res_dmi(random_order);


            Rperm = corrcoef(...
                x_res_dmi,...
                y_perm);


            perm_r_dmi(ip) = ...
                Rperm(1,2);

        end


        DMI_p_perm(test_counter) = ...
            (...
            sum(abs(perm_r_dmi) >= abs(r_dmi)) + 1 ...
            ) / ...
            (n_perm + 1);


        %% =================================================
        % 14. LOYO | DMI
        %% =================================================

        loyo_dmi = ...
            NaN(N(test_counter),1);


        for omit = 1:N(test_counter)

            keep = ...
                true(N(test_counter),1);


            keep(omit) = false;


            x_loyo = xv(keep);

            y_loyo = yv(keep);

            z_loyo = zd(keep);


            Xdesign_loyo = [...
                ones(length(z_loyo),1),...
                z_loyo];


            bx = ...
                Xdesign_loyo \ x_loyo;


            by = ...
                Xdesign_loyo \ y_loyo;


            xr = ...
                x_loyo - ...
                Xdesign_loyo*bx;


            yr = ...
                y_loyo - ...
                Xdesign_loyo*by;


            Rloyo = ...
                corrcoef(xr,yr);


            loyo_dmi(omit) = ...
                Rloyo(1,2);

        end


        DMI_LOYO_min(test_counter) = ...
            min(loyo_dmi);


        DMI_LOYO_max(test_counter) = ...
            max(loyo_dmi);


        DMI_LOYO_mean(test_counter) = ...
            mean(loyo_dmi);


        if r_dmi > 0

            DMI_LOYO_sign_percent(test_counter) = ...
                100 * ...
                sum(loyo_dmi > 0) / ...
                length(loyo_dmi);


        elseif r_dmi < 0

            DMI_LOYO_sign_percent(test_counter) = ...
                100 * ...
                sum(loyo_dmi < 0) / ...
                length(loyo_dmi);


        else

            DMI_LOYO_sign_percent(test_counter) = ...
                NaN;

        end

    end

end


%% =========================================================
% 15. BH-FDR FOR NIÑO PARTIAL CORRELATIONS
%
% Family:
%   3 regions x 4 seasons = 12 tests
%% =========================================================

[p_sorted,sort_idx] = ...
    sort(Nino_p_perm);


m = ...
    length(p_sorted);


q_sorted = ...
    NaN(m,1);


for i = 1:m

    q_sorted(i) = ...
        p_sorted(i) * m / i;

end


%% Enforce monotonic BH adjusted q-values

for i = m-1:-1:1

    q_sorted(i) = ...
        min(...
        q_sorted(i),...
        q_sorted(i+1));

end


q_sorted(q_sorted > 1) = 1;


for i = 1:m

    Nino_q_FDR(sort_idx(i)) = ...
        q_sorted(i);

end


%% =========================================================
% 16. BH-FDR FOR DMI PARTIAL CORRELATIONS
%% =========================================================

[p_sorted,sort_idx] = ...
    sort(DMI_p_perm);


m = ...
    length(p_sorted);


q_sorted = ...
    NaN(m,1);


for i = 1:m

    q_sorted(i) = ...
        p_sorted(i) * m / i;

end


for i = m-1:-1:1

    q_sorted(i) = ...
        min(...
        q_sorted(i),...
        q_sorted(i+1));

end


q_sorted(q_sorted > 1) = 1;


for i = 1:m

    DMI_q_FDR(sort_idx(i)) = ...
        q_sorted(i);

end


%% =========================================================
% 17. CREATE FINAL RESULTS TABLE
%% =========================================================

RobustnessTable = table(...
    Region,...
    Season,...
    N,...
    Original_r,...
    Partial_Nino_r,...
    Nino_CI_low,...
    Nino_CI_high,...
    Nino_p_perm,...
    Nino_q_FDR,...
    Nino_LOYO_min,...
    Nino_LOYO_max,...
    Nino_LOYO_mean,...
    Nino_LOYO_sign_percent,...
    Partial_DMI_r,...
    DMI_CI_low,...
    DMI_CI_high,...
    DMI_p_perm,...
    DMI_q_FDR,...
    DMI_LOYO_min,...
    DMI_LOYO_max,...
    DMI_LOYO_mean,...
    DMI_LOYO_sign_percent);


%% =========================================================
% 18. DISPLAY FULL NIÑO RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('PARTIAL CORRELATION CONTROLLING NIÑO3.4\n')
fprintf('=========================================================\n')


for i = 1:n_tests

    fprintf('\n%s | %s | N=%d\n',...
        Region{i},...
        Season{i},...
        N(i));


    fprintf('Original r  = %+.4f\n',...
        Original_r(i));


    fprintf('Partial r   = %+.4f\n',...
        Partial_Nino_r(i));


    fprintf('95%% CI       = [%+.4f, %+.4f]\n',...
        Nino_CI_low(i),...
        Nino_CI_high(i));


    fprintf('Permutation p = %.6f\n',...
        Nino_p_perm(i));


    fprintf('FDR q         = %.6f\n',...
        Nino_q_FDR(i));


    fprintf('LOYO range    = [%+.4f, %+.4f]\n',...
        Nino_LOYO_min(i),...
        Nino_LOYO_max(i));


    fprintf('LOYO mean     = %+.4f\n',...
        Nino_LOYO_mean(i));


    fprintf('Sign stability = %.1f %%\n',...
        Nino_LOYO_sign_percent(i));

end


%% =========================================================
% 19. DISPLAY FULL DMI RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('PARTIAL CORRELATION CONTROLLING DMI\n')
fprintf('=========================================================\n')


for i = 1:n_tests

    fprintf('\n%s | %s | N=%d\n',...
        Region{i},...
        Season{i},...
        N(i));


    fprintf('Original r  = %+.4f\n',...
        Original_r(i));


    fprintf('Partial r   = %+.4f\n',...
        Partial_DMI_r(i));


    fprintf('95%% CI       = [%+.4f, %+.4f]\n',...
        DMI_CI_low(i),...
        DMI_CI_high(i));


    fprintf('Permutation p = %.6f\n',...
        DMI_p_perm(i));


    fprintf('FDR q         = %.6f\n',...
        DMI_q_FDR(i));


    fprintf('LOYO range    = [%+.4f, %+.4f]\n',...
        DMI_LOYO_min(i),...
        DMI_LOYO_max(i));


    fprintf('LOYO mean     = %+.4f\n',...
        DMI_LOYO_mean(i));


    fprintf('Sign stability = %.1f %%\n',...
        DMI_LOYO_sign_percent(i));

end


%% =========================================================
% 20. COMPACT NIÑO SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('COMPACT NIÑO3.4 ROBUSTNESS SUMMARY\n')
fprintf('=========================================================\n')


fprintf('\n')
fprintf(['Region     Season   Original   Partial    ',...
         'p_perm      q_FDR     Sign%%\n']);

fprintf('---------------------------------------------------------------\n');


for i = 1:n_tests

    fprintf('%-10s %-5s    %+0.3f     %+0.3f     %.4f     %.4f     %5.1f\n',...
        Region{i},...
        Season{i},...
        Original_r(i),...
        Partial_Nino_r(i),...
        Nino_p_perm(i),...
        Nino_q_FDR(i),...
        Nino_LOYO_sign_percent(i));

end


%% =========================================================
% 21. COMPACT DMI SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('COMPACT DMI ROBUSTNESS SUMMARY\n')
fprintf('=========================================================\n')


fprintf('\n')
fprintf(['Region     Season   Original   Partial    ',...
         'p_perm      q_FDR     Sign%%\n']);

fprintf('---------------------------------------------------------------\n');


for i = 1:n_tests

    fprintf('%-10s %-5s    %+0.3f     %+0.3f     %.4f     %.4f     %5.1f\n',...
        Region{i},...
        Season{i},...
        Original_r(i),...
        Partial_DMI_r(i),...
        DMI_p_perm(i),...
        DMI_q_FDR(i),...
        DMI_LOYO_sign_percent(i));

end


%% =========================================================
% 22. ROBUST NIÑO RESULTS q < 0.05
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ROBUST NIÑO-CONTROLLED RELATIONSHIPS: q < 0.05\n')
fprintf('=========================================================\n')


n_robust_nino = 0;


for i = 1:n_tests

    if Nino_q_FDR(i) < 0.05

        n_robust_nino = ...
            n_robust_nino + 1;


        fprintf(...
            '%s | %s | r=%+.3f | p_perm=%.4f | q=%.4f | sign=%.1f%%\n',...
            Region{i},...
            Season{i},...
            Partial_Nino_r(i),...
            Nino_p_perm(i),...
            Nino_q_FDR(i),...
            Nino_LOYO_sign_percent(i));

    end

end


if n_robust_nino == 0

    fprintf('None.\n');

end


%% =========================================================
% 23. SUGGESTIVE NIÑO RESULTS
%% =========================================================

fprintf('\n')
fprintf('Suggestive Niño-controlled relationships:\n')
fprintf('0.05 <= q < 0.10\n')


n_suggest_nino = 0;


for i = 1:n_tests

    if ...
        Nino_q_FDR(i) >= 0.05 && ...
        Nino_q_FDR(i) < 0.10

        n_suggest_nino = ...
            n_suggest_nino + 1;


        fprintf(...
            '%s | %s | r=%+.3f | p_perm=%.4f | q=%.4f | sign=%.1f%%\n',...
            Region{i},...
            Season{i},...
            Partial_Nino_r(i),...
            Nino_p_perm(i),...
            Nino_q_FDR(i),...
            Nino_LOYO_sign_percent(i));

    end

end


if n_suggest_nino == 0

    fprintf('None.\n');

end


%% =========================================================
% 24. ROBUST DMI RESULTS q < 0.05
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ROBUST DMI-CONTROLLED RELATIONSHIPS: q < 0.05\n')
fprintf('=========================================================\n')


n_robust_dmi = 0;


for i = 1:n_tests

    if DMI_q_FDR(i) < 0.05

        n_robust_dmi = ...
            n_robust_dmi + 1;


        fprintf(...
            '%s | %s | r=%+.3f | p_perm=%.4f | q=%.4f | sign=%.1f%%\n',...
            Region{i},...
            Season{i},...
            Partial_DMI_r(i),...
            DMI_p_perm(i),...
            DMI_q_FDR(i),...
            DMI_LOYO_sign_percent(i));

    end

end


if n_robust_dmi == 0

    fprintf('None.\n');

end


%% =========================================================
% 25. SUGGESTIVE DMI RESULTS
%% =========================================================

fprintf('\n')
fprintf('Suggestive DMI-controlled relationships:\n')
fprintf('0.05 <= q < 0.10\n')


n_suggest_dmi = 0;


for i = 1:n_tests

    if ...
        DMI_q_FDR(i) >= 0.05 && ...
        DMI_q_FDR(i) < 0.10

        n_suggest_dmi = ...
            n_suggest_dmi + 1;


        fprintf(...
            '%s | %s | r=%+.3f | p_perm=%.4f | q=%.4f | sign=%.1f%%\n',...
            Region{i},...
            Season{i},...
            Partial_DMI_r(i),...
            DMI_p_perm(i),...
            DMI_q_FDR(i),...
            DMI_LOYO_sign_percent(i));

    end

end


if n_suggest_dmi == 0

    fprintf('None.\n');

end


%% =========================================================
% 26. KEY RELATIONSHIPS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('KEY CLIMATE-MODE SENSITIVITY RESULTS\n')
fprintf('=========================================================\n')


key_region = {...
    'Flores';...
    'Flores';...
    'Sumba';...
    'Timor';...
    'Timor'};


key_season = {...
    'DJF';...
    'JJA';...
    'JJA';...
    'JJA';...
    'SON'};


for k = 1:length(key_region)

    idx = ...
        strcmp(Region,key_region{k}) & ...
        strcmp(Season,key_season{k});


    fprintf('\n%s | %s\n',...
        key_region{k},...
        key_season{k});


    fprintf('Original SST-Rain r = %+.3f\n',...
        Original_r(idx));


    fprintf(['Niño controlled     = %+.3f ',...
             '| q=%.4f | sign=%.1f%%\n'],...
        Partial_Nino_r(idx),...
        Nino_q_FDR(idx),...
        Nino_LOYO_sign_percent(idx));


    fprintf(['DMI controlled      = %+.3f ',...
             '| q=%.4f | sign=%.1f%%\n'],...
        Partial_DMI_r(idx),...
        DMI_q_FDR(idx),...
        DMI_LOYO_sign_percent(idx));

end

%% =========================================================
% 27. SAVE RESULTS
%% =========================================================

save(...
    'seasonal_partial_robustness_results.mat',...
    'RobustnessTable',...
    'n_perm',...
    'rng_seed');


writetable(...
    RobustnessTable,...
    'seasonal_partial_robustness_results.csv');


%% =========================================================
% 28. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL PARTIAL ROBUSTNESS COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n');

fprintf('1. seasonal_partial_robustness_results.mat\n');

fprintf('2. seasonal_partial_robustness_results.csv\n');


fprintf('\nInference convention:\n');

fprintf('* q < 0.05       = robust after BH-FDR\n');

fprintf('  0.05<=q<0.10   = suggestive only\n');

fprintf('  q >= 0.10      = not retained after FDR\n');


fprintf('\nNext step:\n');

fprintf(['05_Plot_ClimateMode_Sensitivity.m will compare ',...
         'Original, Niño-controlled, and DMI-controlled ',...
         'seasonal SST-rainfall correlations.\n']);