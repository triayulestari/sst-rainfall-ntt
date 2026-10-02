%% =========================================================
% 03_Seasonal_Partial_Correlation.m
%
% SEASONAL SST-RAINFALL PARTIAL CORRELATION
% CONTROLLING ENSO AND IOD SEPARATELY
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Seasons:
%   DJF 2017-2025   (n = 9)
%   MAM 2016-2025   (n = 10)
%   JJA 2016-2025   (n = 10)
%   SON 2016-2024   (n = 9)
%
% Variables:
%   X = regional SST anomaly
%   Y = regional rainfall anomaly
%
% Climate controls:
%   Z1 = Niño 3.4
%   Z2 = DMI
%
% Analyses:
%
%   1. Original:
%      r(SST, Rainfall)
%
%   2. ENSO-controlled:
%      r(SST, Rainfall | Niño3.4)
%
%   3. IOD-controlled:
%      r(SST, Rainfall | DMI)
%
% IMPORTANT:
%   Niño3.4 and DMI are controlled SEPARATELY.
%   They are NOT entered simultaneously because the
%   seasonal sample size is only n = 9-10.
%
% Inputs:
%   climate_mode_indices_2016_2025.mat
%   ..\3-Timeseries\regional_timeseries_anomaly.mat
%
% Outputs:
%   seasonal_partial_correlation_results.mat
%   seasonal_partial_correlation_results.csv
%   seasonal_partial_correlation_QC.csv
%
% MATLAB R2021a
% No local functions.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD CLIMATE INDICES
%% =========================================================

Climate = load(...
    'climate_mode_indices_2016_2025.mat',...
    'time',...
    'nino34',...
    'dmi');


time_climate = ...
    Climate.time(:);


nino34 = ...
    Climate.nino34(:);


dmi = ...
    Climate.dmi(:);


%% =========================================================
% 2. LOAD REGIONAL SST / RAINFALL ANOMALIES
%% =========================================================

regional_file = fullfile(...
    '..',...
    '3-Timeseries',...
    'regional_timeseries_anomaly.mat');


Regional = load(regional_file);


required_variables = {...
    'time',...
    'anom_sst_flores',...
    'anom_sst_sumba',...
    'anom_sst_timor',...
    'anom_prec_flores',...
    'anom_prec_sumba',...
    'anom_prec_timor'};


for i = 1:length(required_variables)

    if ~isfield(Regional,required_variables{i})

        error(...
            'Variable "%s" not found in %s.',...
            required_variables{i},...
            regional_file);

    end

end


time = ...
    Regional.time(:);


%% =========================================================
% 3. TIME VECTOR QC
%% =========================================================

if length(time) ~= length(time_climate)

    error(...
        'Regional and climate-index time lengths differ.');

end


if ~all(time == time_climate)

    error(...
        'Regional and climate-index time vectors do not match.');

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL PARTIAL CORRELATION\n')
fprintf('=========================================================\n')


fprintf('Time vectors match exactly.\n');


fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));


%% =========================================================
% 4. REGIONAL MONTHLY MATRICES
%
% Columns:
%   1 = Flores
%   2 = Sumba
%   3 = Timor
%% =========================================================

SST = [...
    Regional.anom_sst_flores(:),...
    Regional.anom_sst_sumba(:),...
    Regional.anom_sst_timor(:)];


RAIN = [...
    Regional.anom_prec_flores(:),...
    Regional.anom_prec_sumba(:),...
    Regional.anom_prec_timor(:)];


region_names = {...
    'Flores';...
    'Sumba';...
    'Timor'};


%% =========================================================
% 5. DEFINE SEASONS
%% =========================================================

season_names = {...
    'DJF';...
    'MAM';...
    'JJA';...
    'SON'};


years_DJF = ...
    (2017:2025)';


years_MAM = ...
    (2016:2025)';


years_JJA = ...
    (2016:2025)';


years_SON = ...
    (2016:2024)';


%% =========================================================
% 6. PREALLOCATE SEASONAL MATRICES
%
% Rows:
%   season-year
%
% Columns:
%   Flores, Sumba, Timor
%% =========================================================

SST_DJF = ...
    NaN(length(years_DJF),3);

RAIN_DJF = ...
    NaN(length(years_DJF),3);


SST_MAM = ...
    NaN(length(years_MAM),3);

RAIN_MAM = ...
    NaN(length(years_MAM),3);


SST_JJA = ...
    NaN(length(years_JJA),3);

RAIN_JJA = ...
    NaN(length(years_JJA),3);


SST_SON = ...
    NaN(length(years_SON),3);

RAIN_SON = ...
    NaN(length(years_SON),3);


NINO_DJF = ...
    NaN(length(years_DJF),1);

DMI_DJF = ...
    NaN(length(years_DJF),1);


NINO_MAM = ...
    NaN(length(years_MAM),1);

DMI_MAM = ...
    NaN(length(years_MAM),1);


NINO_JJA = ...
    NaN(length(years_JJA),1);

DMI_JJA = ...
    NaN(length(years_JJA),1);


NINO_SON = ...
    NaN(length(years_SON),1);

DMI_SON = ...
    NaN(length(years_SON),1);


%% =========================================================
% 7. BUILD DJF SEASONAL MEANS
%
% DJF year Y:
%
%   Dec(Y-1)
%   Jan(Y)
%   Feb(Y)
%% =========================================================

for i = 1:length(years_DJF)

    Y = ...
        years_DJF(i);


    idx = ...
        (year(time)==Y-1 & month(time)==12) | ...
        (year(time)==Y   & month(time)==1)  | ...
        (year(time)==Y   & month(time)==2);


    if sum(idx) ~= 3

        error(...
            'DJF %d does not contain exactly 3 months.',...
            Y);

    end


    %% -----------------------------------------------------
    % Regional SST / rainfall
    %% -----------------------------------------------------

    for rgn = 1:3

        if sum(~isnan(SST(idx,rgn))) == 3

            SST_DJF(i,rgn) = ...
                mean(SST(idx,rgn));

        end


        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_DJF(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end

    end


    %% -----------------------------------------------------
    % Climate indices
    %% -----------------------------------------------------

    if sum(~isnan(nino34(idx))) == 3

        NINO_DJF(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        DMI_DJF(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 8. BUILD MAM SEASONAL MEANS
%% =========================================================

for i = 1:length(years_MAM)

    Y = ...
        years_MAM(i);


    idx = ...
        year(time)==Y & ...
        ismember(month(time),[3 4 5]);


    if sum(idx) ~= 3

        error(...
            'MAM %d does not contain exactly 3 months.',...
            Y);

    end


    for rgn = 1:3

        if sum(~isnan(SST(idx,rgn))) == 3

            SST_MAM(i,rgn) = ...
                mean(SST(idx,rgn));

        end


        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_MAM(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end

    end


    if sum(~isnan(nino34(idx))) == 3

        NINO_MAM(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        DMI_MAM(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 9. BUILD JJA SEASONAL MEANS
%% =========================================================

for i = 1:length(years_JJA)

    Y = ...
        years_JJA(i);


    idx = ...
        year(time)==Y & ...
        ismember(month(time),[6 7 8]);


    if sum(idx) ~= 3

        error(...
            'JJA %d does not contain exactly 3 months.',...
            Y);

    end


    for rgn = 1:3

        if sum(~isnan(SST(idx,rgn))) == 3

            SST_JJA(i,rgn) = ...
                mean(SST(idx,rgn));

        end


        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_JJA(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end

    end


    if sum(~isnan(nino34(idx))) == 3

        NINO_JJA(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        DMI_JJA(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 10. BUILD SON SEASONAL MEANS
%
% SON 2025 is intentionally excluded because
% Oct-Nov 2025 SST data are missing.
%% =========================================================

for i = 1:length(years_SON)

    Y = ...
        years_SON(i);


    idx = ...
        year(time)==Y & ...
        ismember(month(time),[9 10 11]);


    if sum(idx) ~= 3

        error(...
            'SON %d does not contain exactly 3 months.',...
            Y);

    end


    for rgn = 1:3

        if sum(~isnan(SST(idx,rgn))) == 3

            SST_SON(i,rgn) = ...
                mean(SST(idx,rgn));

        end


        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_SON(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end

    end


    if sum(~isnan(nino34(idx))) == 3

        NINO_SON(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        DMI_SON(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 11. SEASONAL SAMPLE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL SAMPLE QC\n')
fprintf('=========================================================\n')


for rgn = 1:3

    fprintf('\n%s:\n',...
        region_names{rgn});


    fprintf('DJF SST / Rain = %d / %d\n',...
        sum(~isnan(SST_DJF(:,rgn))),...
        sum(~isnan(RAIN_DJF(:,rgn))));


    fprintf('MAM SST / Rain = %d / %d\n',...
        sum(~isnan(SST_MAM(:,rgn))),...
        sum(~isnan(RAIN_MAM(:,rgn))));


    fprintf('JJA SST / Rain = %d / %d\n',...
        sum(~isnan(SST_JJA(:,rgn))),...
        sum(~isnan(RAIN_JJA(:,rgn))));


    fprintf('SON SST / Rain = %d / %d\n',...
        sum(~isnan(SST_SON(:,rgn))),...
        sum(~isnan(RAIN_SON(:,rgn))));

end


fprintf('\nClimate indices:\n');


fprintf('DJF Niño/DMI = %d / %d\n',...
    sum(~isnan(NINO_DJF)),...
    sum(~isnan(DMI_DJF)));


fprintf('MAM Niño/DMI = %d / %d\n',...
    sum(~isnan(NINO_MAM)),...
    sum(~isnan(DMI_MAM)));


fprintf('JJA Niño/DMI = %d / %d\n',...
    sum(~isnan(NINO_JJA)),...
    sum(~isnan(DMI_JJA)));


fprintf('SON Niño/DMI = %d / %d\n',...
    sum(~isnan(NINO_SON)),...
    sum(~isnan(DMI_SON)));


%% =========================================================
% 12. PREALLOCATE RESULTS
%
% 3 regions x 4 seasons = 12 rows
%% =========================================================

n_tests = ...
    12;


Region = ...
    cell(n_tests,1);


Season = ...
    cell(n_tests,1);


N = ...
    NaN(n_tests,1);


Original_r = ...
    NaN(n_tests,1);


Original_p = ...
    NaN(n_tests,1);


%% Niño diagnostics

SST_Nino_r = ...
    NaN(n_tests,1);


Rain_Nino_r = ...
    NaN(n_tests,1);


Partial_Nino_r = ...
    NaN(n_tests,1);


Partial_Nino_p = ...
    NaN(n_tests,1);


Change_Nino = ...
    NaN(n_tests,1);


%% DMI diagnostics

SST_DMI_r = ...
    NaN(n_tests,1);


Rain_DMI_r = ...
    NaN(n_tests,1);


Partial_DMI_r = ...
    NaN(n_tests,1);


Partial_DMI_p = ...
    NaN(n_tests,1);


Change_DMI = ...
    NaN(n_tests,1);


%% Residual QC

Partial_Nino_residual_r = ...
    NaN(n_tests,1);


Partial_DMI_residual_r = ...
    NaN(n_tests,1);


test_counter = 0;


%% =========================================================
% 13. LOOP THROUGH REGIONS AND SEASONS
%% =========================================================

for rgn = 1:3

    for s = 1:4

        test_counter = ...
            test_counter + 1;


        Region{test_counter} = ...
            region_names{rgn};


        Season{test_counter} = ...
            season_names{s};


        %% -------------------------------------------------
        % Select seasonal vectors
        %% -------------------------------------------------

        if s == 1

            x = ...
                SST_DJF(:,rgn);

            y = ...
                RAIN_DJF(:,rgn);

            z_nino = ...
                NINO_DJF;

            z_dmi = ...
                DMI_DJF;


        elseif s == 2

            x = ...
                SST_MAM(:,rgn);

            y = ...
                RAIN_MAM(:,rgn);

            z_nino = ...
                NINO_MAM;

            z_dmi = ...
                DMI_MAM;


        elseif s == 3

            x = ...
                SST_JJA(:,rgn);

            y = ...
                RAIN_JJA(:,rgn);

            z_nino = ...
                NINO_JJA;

            z_dmi = ...
                DMI_JJA;


        else

            x = ...
                SST_SON(:,rgn);

            y = ...
                RAIN_SON(:,rgn);

            z_nino = ...
                NINO_SON;

            z_dmi = ...
                DMI_SON;

        end


        %% -------------------------------------------------
        % Complete-case mask
        %
        % Climate indices are complete, but using a joint
        % mask guarantees identical sample composition.
        %% -------------------------------------------------

        valid = ...
            ~isnan(x) & ...
            ~isnan(y) & ...
            ~isnan(z_nino) & ...
            ~isnan(z_dmi);


        xv = ...
            x(valid);


        yv = ...
            y(valid);


        zn = ...
            z_nino(valid);


        zd = ...
            z_dmi(valid);


        N(test_counter) = ...
            length(xv);


        %% =================================================
        % 14. ORIGINAL SST-RAINFALL CORRELATION
        %% =================================================

        [Rxy,Pxy] = corrcoef(...
            xv,...
            yv);


        r_xy = ...
            Rxy(1,2);


        Original_r(test_counter) = ...
            r_xy;


        Original_p(test_counter) = ...
            Pxy(1,2);


        %% =================================================
        % 15. NIÑO 3.4 DIAGNOSTIC CORRELATIONS
        %% =================================================

        R_x_nino = corrcoef(...
            xv,...
            zn);


        r_x_nino = ...
            R_x_nino(1,2);


        SST_Nino_r(test_counter) = ...
            r_x_nino;


        R_y_nino = corrcoef(...
            yv,...
            zn);


        r_y_nino = ...
            R_y_nino(1,2);


        Rain_Nino_r(test_counter) = ...
            r_y_nino;


        %% =================================================
        % 16. PARTIAL CORRELATION CONTROLLING NIÑO 3.4
        %
        % r_xy.z =
        %
        % (r_xy - r_xz*r_yz)
        % ----------------------
        % sqrt[(1-r_xz^2)(1-r_yz^2)]
        %% =================================================

        denominator_nino = ...
            sqrt(...
            (1-r_x_nino^2) * ...
            (1-r_y_nino^2));


        if denominator_nino <= 0

            error(...
                'Invalid Niño partial-correlation denominator.');

        end


        r_partial_nino = ...
            (...
            r_xy - ...
            r_x_nino*r_y_nino...
            ) / ...
            denominator_nino;


        Partial_Nino_r(test_counter) = ...
            r_partial_nino;


        %% -------------------------------------------------
        % Parametric p-value
        %
        % For one control variable:
        %
        % df = N - 3
        %% -------------------------------------------------

        df_partial = ...
            N(test_counter)-3;


        t_partial_nino = ...
            r_partial_nino * ...
            sqrt(...
            df_partial / ...
            (1-r_partial_nino^2));


        Partial_Nino_p(test_counter) = ...
            2 * ...
            (1-tcdf(...
            abs(t_partial_nino),...
            df_partial));


        Change_Nino(test_counter) = ...
            r_partial_nino - r_xy;


        %% =================================================
        % 17. RESIDUAL METHOD QC FOR NIÑO
        %
        % Partial correlation can also be calculated as
        % correlation between residuals after removing
        % linear Niño influence from X and Y.
        %% =================================================

        Xdesign_nino = [...
            ones(length(zn),1),...
            zn];


        beta_x_nino = ...
            Xdesign_nino \ xv;


        beta_y_nino = ...
            Xdesign_nino \ yv;


        x_res_nino = ...
            xv - ...
            Xdesign_nino * beta_x_nino;


        y_res_nino = ...
            yv - ...
            Xdesign_nino * beta_y_nino;


        Rres_nino = corrcoef(...
            x_res_nino,...
            y_res_nino);


        Partial_Nino_residual_r(test_counter) = ...
            Rres_nino(1,2);


        %% =================================================
        % 18. DMI DIAGNOSTIC CORRELATIONS
        %% =================================================

        R_x_dmi = corrcoef(...
            xv,...
            zd);


        r_x_dmi = ...
            R_x_dmi(1,2);


        SST_DMI_r(test_counter) = ...
            r_x_dmi;


        R_y_dmi = corrcoef(...
            yv,...
            zd);


        r_y_dmi = ...
            R_y_dmi(1,2);


        Rain_DMI_r(test_counter) = ...
            r_y_dmi;


        %% =================================================
        % 19. PARTIAL CORRELATION CONTROLLING DMI
        %% =================================================

        denominator_dmi = ...
            sqrt(...
            (1-r_x_dmi^2) * ...
            (1-r_y_dmi^2));


        if denominator_dmi <= 0

            error(...
                'Invalid DMI partial-correlation denominator.');

        end


        r_partial_dmi = ...
            (...
            r_xy - ...
            r_x_dmi*r_y_dmi...
            ) / ...
            denominator_dmi;


        Partial_DMI_r(test_counter) = ...
            r_partial_dmi;


        t_partial_dmi = ...
            r_partial_dmi * ...
            sqrt(...
            df_partial / ...
            (1-r_partial_dmi^2));


        Partial_DMI_p(test_counter) = ...
            2 * ...
            (1-tcdf(...
            abs(t_partial_dmi),...
            df_partial));


        Change_DMI(test_counter) = ...
            r_partial_dmi - r_xy;


        %% =================================================
        % 20. RESIDUAL METHOD QC FOR DMI
        %% =================================================

        Xdesign_dmi = [...
            ones(length(zd),1),...
            zd];


        beta_x_dmi = ...
            Xdesign_dmi \ xv;


        beta_y_dmi = ...
            Xdesign_dmi \ yv;


        x_res_dmi = ...
            xv - ...
            Xdesign_dmi * beta_x_dmi;


        y_res_dmi = ...
            yv - ...
            Xdesign_dmi * beta_y_dmi;


        Rres_dmi = corrcoef(...
            x_res_dmi,...
            y_res_dmi);


        Partial_DMI_residual_r(test_counter) = ...
            Rres_dmi(1,2);

    end

end


%% =========================================================
% 21. PARTIAL-CORRELATION QC
%
% Formula method and residual method should be essentially
% identical.
%% =========================================================

difference_nino = ...
    abs(...
    Partial_Nino_r - ...
    Partial_Nino_residual_r);


difference_dmi = ...
    abs(...
    Partial_DMI_r - ...
    Partial_DMI_residual_r);


max_difference_nino = ...
    max(difference_nino);


max_difference_dmi = ...
    max(difference_dmi);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('PARTIAL CORRELATION METHOD QC\n')
fprintf('=========================================================\n')


fprintf(['Maximum formula vs residual difference ',...
         '(Niño3.4) = %.12f\n'],...
    max_difference_nino);


fprintf(['Maximum formula vs residual difference ',...
         '(DMI)     = %.12f\n'],...
    max_difference_dmi);


if max_difference_nino > 1e-10 || ...
   max_difference_dmi > 1e-10

    warning([...
        'Partial-correlation QC difference is larger ',...
        'than expected.']);

else

    fprintf('QC PASSED: formula and residual methods agree.\n');

end


%% =========================================================
% 22. CREATE RESULTS TABLE
%% =========================================================

ResultsTable = table(...
    Region,...
    Season,...
    N,...
    Original_r,...
    Original_p,...
    SST_Nino_r,...
    Rain_Nino_r,...
    Partial_Nino_r,...
    Partial_Nino_p,...
    Change_Nino,...
    SST_DMI_r,...
    Rain_DMI_r,...
    Partial_DMI_r,...
    Partial_DMI_p,...
    Change_DMI);


%% =========================================================
% 23. DISPLAY FULL RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL PARTIAL CORRELATION RESULTS\n')
fprintf('=========================================================\n')


for i = 1:n_tests

    fprintf('\n%s | %s | N=%d\n',...
        Region{i},...
        Season{i},...
        N(i));


    fprintf('Original SST-Rain:\n');

    fprintf('  r = %+.4f | p = %.6f\n',...
        Original_r(i),...
        Original_p(i));


    fprintf('Control Niño3.4:\n');

    fprintf('  SST-Niño      = %+.4f\n',...
        SST_Nino_r(i));

    fprintf('  Rain-Niño     = %+.4f\n',...
        Rain_Nino_r(i));

    fprintf('  Partial r     = %+.4f\n',...
        Partial_Nino_r(i));

    fprintf('  Partial p     = %.6f\n',...
        Partial_Nino_p(i));

    fprintf('  Change in r   = %+.4f\n',...
        Change_Nino(i));


    fprintf('Control DMI:\n');

    fprintf('  SST-DMI       = %+.4f\n',...
        SST_DMI_r(i));

    fprintf('  Rain-DMI      = %+.4f\n',...
        Rain_DMI_r(i));

    fprintf('  Partial r     = %+.4f\n',...
        Partial_DMI_r(i));

    fprintf('  Partial p     = %.6f\n',...
        Partial_DMI_p(i));

    fprintf('  Change in r   = %+.4f\n',...
        Change_DMI(i));

end


%% =========================================================
% 24. COMPACT COMPARISON
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('COMPACT ORIGINAL vs PARTIAL CORRELATION\n')
fprintf('=========================================================\n')


fprintf('\n')
fprintf(['Region     Season      Original     ',...
         'Partial|Nino    Partial|DMI\n']);


fprintf('---------------------------------------------------------\n');


for i = 1:n_tests

    fprintf('%-10s %-5s       %+0.3f         %+0.3f         %+0.3f\n',...
        Region{i},...
        Season{i},...
        Original_r(i),...
        Partial_Nino_r(i),...
        Partial_DMI_r(i));

end


%% =========================================================
% 25. PRINT IMPORTANT PREVIOUSLY ROBUST CASES
%
% Based on the main seasonal SST-rainfall robustness
% analysis:
%
%   Flores JJA
%   Sumba JJA
%   Timor JJA
%   Timor SON
%
% Flores DJF is retained here because it was suggestive
% after FDR and scientifically important for sensitivity.
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('KEY SEASONAL RELATIONSHIPS\n')
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


    fprintf('\n%s %s\n',...
        key_region{k},...
        key_season{k});


    fprintf('Original       = %+.3f\n',...
        Original_r(idx));


    fprintf('Control Niño   = %+.3f\n',...
        Partial_Nino_r(idx));


    fprintf('Control DMI    = %+.3f\n',...
        Partial_DMI_r(idx));

end


%% =========================================================
% 26. CREATE QC TABLE
%% =========================================================

Method = {...
    'Nino_formula_vs_residual';...
    'DMI_formula_vs_residual'};


Maximum_absolute_difference = [...
    max_difference_nino;...
    max_difference_dmi];


QCTable = table(...
    Method,...
    Maximum_absolute_difference);


%% =========================================================
% 27. SAVE RESULTS
%% =========================================================

save(...
    'seasonal_partial_correlation_results.mat',...
    'ResultsTable',...
    'QCTable',...
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


writetable(...
    ResultsTable,...
    'seasonal_partial_correlation_results.csv');


writetable(...
    QCTable,...
    'seasonal_partial_correlation_QC.csv');


%% =========================================================
% 28. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL PARTIAL CORRELATION COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n');

fprintf('1. seasonal_partial_correlation_results.mat\n');

fprintf('2. seasonal_partial_correlation_results.csv\n');

fprintf('3. seasonal_partial_correlation_QC.csv\n');


fprintf('\nImportant methodological note:\n');

fprintf(['Niño3.4 and DMI were controlled separately ',...
         'because seasonal sample sizes are only n=9-10.\n']);


fprintf(['The parametric partial-correlation p-values ',...
         'reported here are preliminary.\n']);


fprintf(['Final statistical robustness will be assessed ',...
         'in Script 04 using permutation tests, confidence ',...
         'intervals, leave-one-year-out analysis, and ',...
         'BH-FDR correction.\n']);