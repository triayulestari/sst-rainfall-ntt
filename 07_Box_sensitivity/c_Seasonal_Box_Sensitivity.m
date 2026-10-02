%% =========================================================
% 03_Seasonal_Box_Sensitivity.m
%
% FINAL VERSION
%
% SEASONAL SST-RAINFALL BOX SENSITIVITY
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% SST box variants:
%   Shrink 0.2
%   Shrink 0.1
%   Baseline
%   Expand 0.1
%   Expand 0.2
%
% Seasons:
%   DJF 2017-2025  n=9
%   MAM 2016-2025  n=10
%   JJA 2016-2025  n=10
%   SON 2016-2024  n=9
%
% Rainfall:
%   The SAME regional rainfall anomaly series used
%   in the main analysis.
%
% Outputs:
%   seasonal_box_sensitivity_results.mat
%   seasonal_box_sensitivity_results.csv
%   seasonal_box_sensitivity_summary.csv
%
% MATLAB R2021a
% No local functions.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD SST BOX-VARIANT ANOMALIES
%% =========================================================

load(...
    'sst_box_variants_anomaly.mat',...
    'time',...
    'Year',...
    'Month',...
    'region_names',...
    'variant_names',...
    'variant_labels',...
    'perturbation',...
    'baseline_index',...
    'sst_anomaly');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL SST BOX SENSITIVITY\n')
fprintf('=========================================================\n')


%% =========================================================
% 2. LOAD MAIN REGIONAL RAINFALL ANOMALIES
%% =========================================================

regional_file = ...
    fullfile(...
    '..',...
    '3-Timeseries',...
    'regional_timeseries_anomaly.mat');


Regional = ...
    load(regional_file);


required_variables = {...
    'time',...
    'anom_prec_flores',...
    'anom_prec_sumba',...
    'anom_prec_timor'};


for i = 1:length(required_variables)

    if ~isfield(...
            Regional,...
            required_variables{i})

        error(...
            'Variable "%s" not found in %s.',...
            required_variables{i},...
            regional_file);

    end

end


time_rain = ...
    Regional.time(:);


%% =========================================================
% 3. TIME VECTOR QC
%% =========================================================

if length(time) ~= length(time_rain)

    error(...
        'SST and rainfall time-vector lengths differ.');

end


if ~all(time(:) == time_rain(:))

    error(...
        'SST and rainfall time vectors do not match.');

end


fprintf('Time vectors match exactly.\n');

fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));


%% =========================================================
% 4. RAINFALL MATRIX
%
% Columns:
%   1 Flores
%   2 Sumba
%   3 Timor
%
% Units:
%   mm/month
%% =========================================================

RAIN = [...
    Regional.anom_prec_flores(:),...
    Regional.anom_prec_sumba(:),...
    Regional.anom_prec_timor(:)];


%% =========================================================
% 5. DIMENSION QC
%% =========================================================

[n_time,n_variants,n_regions] = ...
    size(sst_anomaly);


if n_time ~= 120

    error(...
        'Expected 120 monthly SST positions.');

end


if n_variants ~= 5

    error(...
        'Expected 5 SST box variants.');

end


if n_regions ~= 3

    error(...
        'Expected 3 regions.');

end


%% =========================================================
% 6. DEFINE SEASONS
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


n_seasons = ...
    4;


%% =========================================================
% 7. PREALLOCATE SEASONAL SST
%
% Dimensions:
%
%   season-year x variant x region
%% =========================================================

SST_DJF = ...
    NaN(...
    length(years_DJF),...
    n_variants,...
    n_regions);


SST_MAM = ...
    NaN(...
    length(years_MAM),...
    n_variants,...
    n_regions);


SST_JJA = ...
    NaN(...
    length(years_JJA),...
    n_variants,...
    n_regions);


SST_SON = ...
    NaN(...
    length(years_SON),...
    n_variants,...
    n_regions);


%% =========================================================
% 8. PREALLOCATE SEASONAL RAINFALL
%
% Dimensions:
%
%   season-year x region
%% =========================================================

RAIN_DJF = ...
    NaN(...
    length(years_DJF),...
    n_regions);


RAIN_MAM = ...
    NaN(...
    length(years_MAM),...
    n_regions);


RAIN_JJA = ...
    NaN(...
    length(years_JJA),...
    n_regions);


RAIN_SON = ...
    NaN(...
    length(years_SON),...
    n_regions);


%% =========================================================
% 9. BUILD DJF SEASONAL MEANS
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


    for rgn = 1:n_regions

        %% Rainfall

        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_DJF(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end


        %% SST variants

        for v = 1:n_variants

            tmp = ...
                sst_anomaly(...
                idx,...
                v,...
                rgn);


            if sum(~isnan(tmp)) == 3

                SST_DJF(i,v,rgn) = ...
                    mean(tmp);

            end

        end

    end

end


%% =========================================================
% 10. BUILD MAM SEASONAL MEANS
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


    for rgn = 1:n_regions

        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_MAM(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end


        for v = 1:n_variants

            tmp = ...
                sst_anomaly(...
                idx,...
                v,...
                rgn);


            if sum(~isnan(tmp)) == 3

                SST_MAM(i,v,rgn) = ...
                    mean(tmp);

            end

        end

    end

end


%% =========================================================
% 11. BUILD JJA SEASONAL MEANS
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


    for rgn = 1:n_regions

        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_JJA(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end


        for v = 1:n_variants

            tmp = ...
                sst_anomaly(...
                idx,...
                v,...
                rgn);


            if sum(~isnan(tmp)) == 3

                SST_JJA(i,v,rgn) = ...
                    mean(tmp);

            end

        end

    end

end


%% =========================================================
% 12. BUILD SON SEASONAL MEANS
%
% SON 2025 is excluded because Oct-Nov 2025 SST are
% unavailable.
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


    for rgn = 1:n_regions

        if sum(~isnan(RAIN(idx,rgn))) == 3

            RAIN_SON(i,rgn) = ...
                mean(RAIN(idx,rgn));

        end


        for v = 1:n_variants

            tmp = ...
                sst_anomaly(...
                idx,...
                v,...
                rgn);


            if sum(~isnan(tmp)) == 3

                SST_SON(i,v,rgn) = ...
                    mean(tmp);

            end

        end

    end

end


%% =========================================================
% 13. SEASONAL SAMPLE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL SAMPLE QC\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        n_DJF = ...
            sum(...
            ~isnan(...
            SST_DJF(:,v,rgn)) & ...
            ~isnan(...
            RAIN_DJF(:,rgn)));


        n_MAM = ...
            sum(...
            ~isnan(...
            SST_MAM(:,v,rgn)) & ...
            ~isnan(...
            RAIN_MAM(:,rgn)));


        n_JJA = ...
            sum(...
            ~isnan(...
            SST_JJA(:,v,rgn)) & ...
            ~isnan(...
            RAIN_JJA(:,rgn)));


        n_SON = ...
            sum(...
            ~isnan(...
            SST_SON(:,v,rgn)) & ...
            ~isnan(...
            RAIN_SON(:,rgn)));


        fprintf(...
            ['%-13s DJF=%d MAM=%d ',...
             'JJA=%d SON=%d\n'],...
            variant_labels{v},...
            n_DJF,...
            n_MAM,...
            n_JJA,...
            n_SON);

    end

end


%% =========================================================
% 14. HARD SAMPLE-SIZE QC
%% =========================================================

for rgn = 1:n_regions

    for v = 1:n_variants

        if ...
            sum(~isnan(SST_DJF(:,v,rgn)) & ...
                ~isnan(RAIN_DJF(:,rgn))) ~= 9

            error(...
                'DJF sample QC failed.');

        end


        if ...
            sum(~isnan(SST_MAM(:,v,rgn)) & ...
                ~isnan(RAIN_MAM(:,rgn))) ~= 10

            error(...
                'MAM sample QC failed.');

        end


        if ...
            sum(~isnan(SST_JJA(:,v,rgn)) & ...
                ~isnan(RAIN_JJA(:,rgn))) ~= 10

            error(...
                'JJA sample QC failed.');

        end


        if ...
            sum(~isnan(SST_SON(:,v,rgn)) & ...
                ~isnan(RAIN_SON(:,rgn))) ~= 9

            error(...
                'SON sample QC failed.');

        end

    end

end


fprintf('\n')
fprintf('Seasonal sample-size QC PASSED.\n');


%% =========================================================
% 15. PREALLOCATE CORRELATION RESULTS
%
% Dimensions:
%
%   region x season x variant
%% =========================================================

R = ...
    NaN(...
    n_regions,...
    n_seasons,...
    n_variants);


P = ...
    NaN(...
    n_regions,...
    n_seasons,...
    n_variants);


N = ...
    NaN(...
    n_regions,...
    n_seasons,...
    n_variants);


%% =========================================================
% 16. CALCULATE SEASONAL CORRELATIONS
%% =========================================================

for rgn = 1:n_regions

    for s = 1:n_seasons

        for v = 1:n_variants

            %% ---------------------------------------------
            % Select season
            %% ---------------------------------------------

            if s == 1

                x = ...
                    SST_DJF(:,v,rgn);

                y = ...
                    RAIN_DJF(:,rgn);


            elseif s == 2

                x = ...
                    SST_MAM(:,v,rgn);

                y = ...
                    RAIN_MAM(:,rgn);


            elseif s == 3

                x = ...
                    SST_JJA(:,v,rgn);

                y = ...
                    RAIN_JJA(:,rgn);


            else

                x = ...
                    SST_SON(:,v,rgn);

                y = ...
                    RAIN_SON(:,rgn);

            end


            valid = ...
                ~isnan(x) & ...
                ~isnan(y);


            xv = ...
                x(valid);


            yv = ...
                y(valid);


            N(rgn,s,v) = ...
                length(xv);


            [Rtmp,Ptmp] = ...
                corrcoef(...
                xv,...
                yv);


            R(rgn,s,v) = ...
                Rtmp(1,2);


            P(rgn,s,v) = ...
                Ptmp(1,2);

        end

    end

end


%% =========================================================
% 17. BASELINE CORRELATION REPRODUCTION QC
%
% Previously locked seasonal correlations:
%
%          DJF       MAM       JJA       SON
%
% Flores  -0.71149  +0.06273  +0.85687  +0.68681
% Sumba   -0.54475  -0.26148  +0.83818  +0.46650
% Timor   -0.10260  -0.16510  +0.79169  +0.85506
%% =========================================================

expected_baseline_r = [...
    -0.71149   +0.062728   +0.85687   +0.68681;...
    -0.54475   -0.26148    +0.83818   +0.46650;...
    -0.10260   -0.16510    +0.79169   +0.85506];


actual_baseline_r = ...
    squeeze(...
    R(:,:,baseline_index));


baseline_r_difference = ...
    abs(...
    actual_baseline_r - ...
    expected_baseline_r);


max_baseline_r_difference = ...
    max(...
    baseline_r_difference(:));


fprintf('\n')
fprintf('=========================================================\n')
fprintf('BASELINE CORRELATION REPRODUCTION QC\n')
fprintf('=========================================================\n')


fprintf('\nActual baseline correlations:\n')

disp(actual_baseline_r)


fprintf('Maximum absolute difference = %.8f\n',...
    max_baseline_r_difference);


if max_baseline_r_difference < 1e-4

    fprintf(['QC PASSED: baseline seasonal correlations ',...
             'reproduce the main analysis.\n']);

else

    error([...
        'Baseline seasonal correlation QC FAILED. ',...
        'Do not continue.']);

end


%% =========================================================
% 18. SENSITIVITY SUMMARY METRICS
%% =========================================================

R_min = ...
    NaN(...
    n_regions,...
    n_seasons);


R_max = ...
    NaN(...
    n_regions,...
    n_seasons);


R_mean = ...
    NaN(...
    n_regions,...
    n_seasons);


R_sd = ...
    NaN(...
    n_regions,...
    n_seasons);


R_range = ...
    NaN(...
    n_regions,...
    n_seasons);


Baseline_r = ...
    NaN(...
    n_regions,...
    n_seasons);


Max_abs_change_from_baseline = ...
    NaN(...
    n_regions,...
    n_seasons);


Sign_consistency_percent = ...
    NaN(...
    n_regions,...
    n_seasons);


Baseline_sign_consistency_percent = ...
    NaN(...
    n_regions,...
    n_seasons);


for rgn = 1:n_regions

    for s = 1:n_seasons

        rvals = ...
            squeeze(...
            R(rgn,s,:));


        R_min(rgn,s) = ...
            min(rvals);


        R_max(rgn,s) = ...
            max(rvals);


        R_mean(rgn,s) = ...
            mean(rvals);


        R_sd(rgn,s) = ...
            std(rvals);


        R_range(rgn,s) = ...
            R_max(rgn,s) - ...
            R_min(rgn,s);


        Baseline_r(rgn,s) = ...
            R(rgn,s,baseline_index);


        Max_abs_change_from_baseline(rgn,s) = ...
            max(...
            abs(...
            rvals - ...
            Baseline_r(rgn,s)));


        %% -------------------------------------------------
        % Majority sign consistency
        %% -------------------------------------------------

        n_positive = ...
            sum(rvals > 0);


        n_negative = ...
            sum(rvals < 0);


        Sign_consistency_percent(rgn,s) = ...
            100 * ...
            max(...
            n_positive,...
            n_negative) / ...
            n_variants;


        %% -------------------------------------------------
        % Consistency with BASELINE sign
        %% -------------------------------------------------

        if Baseline_r(rgn,s) > 0

            Baseline_sign_consistency_percent(rgn,s) = ...
                100 * ...
                sum(rvals > 0) / ...
                n_variants;


        elseif Baseline_r(rgn,s) < 0

            Baseline_sign_consistency_percent(rgn,s) = ...
                100 * ...
                sum(rvals < 0) / ...
                n_variants;


        else

            Baseline_sign_consistency_percent(rgn,s) = ...
                NaN;

        end

    end

end


%% =========================================================
% 19. DISPLAY FULL CORRELATION RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL BOX-SENSITIVITY CORRELATIONS\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    fprintf(['Season      Shrink.2   Shrink.1   ',...
             'Baseline   Expand.1   Expand.2\n']);


    fprintf('---------------------------------------------------------------\n');


    for s = 1:n_seasons

        fprintf(...
            '%-5s       %+0.3f      %+0.3f      %+0.3f      %+0.3f      %+0.3f\n',...
            season_names{s},...
            R(rgn,s,1),...
            R(rgn,s,2),...
            R(rgn,s,3),...
            R(rgn,s,4),...
            R(rgn,s,5));

    end

end


%% =========================================================
% 20. DISPLAY SENSITIVITY SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('BOX-SENSITIVITY SUMMARY\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    fprintf(['Season   Baseline    r_min    r_max    SD      ',...
             'Max|Delta r|   Sign%%\n']);


    fprintf('---------------------------------------------------------------\n');


    for s = 1:n_seasons

        fprintf(...
            '%-5s    %+0.3f     %+0.3f   %+0.3f   %.3f      %.3f       %.0f\n',...
            season_names{s},...
            Baseline_r(rgn,s),...
            R_min(rgn,s),...
            R_max(rgn,s),...
            R_sd(rgn,s),...
            Max_abs_change_from_baseline(rgn,s),...
            Baseline_sign_consistency_percent(rgn,s));

    end

end


%% =========================================================
% 21. KEY JJA STABILITY SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('KEY JJA BOX-SENSITIVITY RESULTS\n')
fprintf('=========================================================\n')


jja_index = ...
    3;


for rgn = 1:n_regions

    fprintf('\n%s JJA\n',...
        region_names{rgn});


    fprintf('Baseline r = %+.3f\n',...
        Baseline_r(rgn,jja_index));


    fprintf('Range      = %+.3f to %+.3f\n',...
        R_min(rgn,jja_index),...
        R_max(rgn,jja_index));


    fprintf('SD         = %.3f\n',...
        R_sd(rgn,jja_index));


    fprintf('Max |Delta r| from baseline = %.3f\n',...
        Max_abs_change_from_baseline(...
        rgn,...
        jja_index));


    fprintf('Baseline-sign consistency = %.0f %%\n',...
        Baseline_sign_consistency_percent(...
        rgn,...
        jja_index));

end


%% =========================================================
% 22. CREATE LONG-FORM RESULTS TABLE
%% =========================================================

n_rows = ...
    n_regions * ...
    n_seasons * ...
    n_variants;


Out_Region = ...
    cell(n_rows,1);


Out_Season = ...
    cell(n_rows,1);


Out_Variant = ...
    cell(n_rows,1);


Out_Perturbation_deg = ...
    NaN(n_rows,1);


Out_N = ...
    NaN(n_rows,1);


Out_r = ...
    NaN(n_rows,1);


Out_p = ...
    NaN(n_rows,1);


row_counter = ...
    0;


for rgn = 1:n_regions

    for s = 1:n_seasons

        for v = 1:n_variants

            row_counter = ...
                row_counter + 1;


            Out_Region{row_counter} = ...
                region_names{rgn};


            Out_Season{row_counter} = ...
                season_names{s};


            Out_Variant{row_counter} = ...
                variant_labels{v};


            Out_Perturbation_deg(row_counter) = ...
                perturbation(v);


            Out_N(row_counter) = ...
                N(rgn,s,v);


            Out_r(row_counter) = ...
                R(rgn,s,v);


            Out_p(row_counter) = ...
                P(rgn,s,v);

        end

    end

end


ResultsTable = ...
    table(...
    Out_Region,...
    Out_Season,...
    Out_Variant,...
    Out_Perturbation_deg,...
    Out_N,...
    Out_r,...
    Out_p,...
    'VariableNames',{...
    'Region',...
    'Season',...
    'Variant',...
    'Perturbation_deg',...
    'N',...
    'r',...
    'p_raw'});


%% =========================================================
% 23. CREATE SUMMARY TABLE
%% =========================================================

summary_rows = ...
    n_regions * ...
    n_seasons;


Sum_Region = ...
    cell(summary_rows,1);


Sum_Season = ...
    cell(summary_rows,1);


Sum_Baseline_r = ...
    NaN(summary_rows,1);


Sum_r_min = ...
    NaN(summary_rows,1);


Sum_r_max = ...
    NaN(summary_rows,1);


Sum_r_mean = ...
    NaN(summary_rows,1);


Sum_r_SD = ...
    NaN(summary_rows,1);


Sum_r_range = ...
    NaN(summary_rows,1);


Sum_Max_abs_change = ...
    NaN(summary_rows,1);


Sum_Sign_consistency = ...
    NaN(summary_rows,1);


row_counter = ...
    0;


for rgn = 1:n_regions

    for s = 1:n_seasons

        row_counter = ...
            row_counter + 1;


        Sum_Region{row_counter} = ...
            region_names{rgn};


        Sum_Season{row_counter} = ...
            season_names{s};


        Sum_Baseline_r(row_counter) = ...
            Baseline_r(rgn,s);


        Sum_r_min(row_counter) = ...
            R_min(rgn,s);


        Sum_r_max(row_counter) = ...
            R_max(rgn,s);


        Sum_r_mean(row_counter) = ...
            R_mean(rgn,s);


        Sum_r_SD(row_counter) = ...
            R_sd(rgn,s);


        Sum_r_range(row_counter) = ...
            R_range(rgn,s);


        Sum_Max_abs_change(row_counter) = ...
            Max_abs_change_from_baseline(rgn,s);


        Sum_Sign_consistency(row_counter) = ...
            Baseline_sign_consistency_percent(rgn,s);

    end

end


SummaryTable = ...
    table(...
    Sum_Region,...
    Sum_Season,...
    Sum_Baseline_r,...
    Sum_r_min,...
    Sum_r_max,...
    Sum_r_mean,...
    Sum_r_SD,...
    Sum_r_range,...
    Sum_Max_abs_change,...
    Sum_Sign_consistency,...
    'VariableNames',{...
    'Region',...
    'Season',...
    'Baseline_r',...
    'r_min',...
    'r_max',...
    'r_mean',...
    'r_SD',...
    'r_range',...
    'Max_abs_change_from_baseline',...
    'Baseline_sign_consistency_percent'});


%% =========================================================
% 24. SAVE RESULTS
%% =========================================================

save(...
    'seasonal_box_sensitivity_results.mat',...
    'ResultsTable',...
    'SummaryTable',...
    'R',...
    'P',...
    'N',...
    'R_min',...
    'R_max',...
    'R_mean',...
    'R_sd',...
    'R_range',...
    'Baseline_r',...
    'Max_abs_change_from_baseline',...
    'Sign_consistency_percent',...
    'Baseline_sign_consistency_percent',...
    'SST_DJF',...
    'SST_MAM',...
    'SST_JJA',...
    'SST_SON',...
    'RAIN_DJF',...
    'RAIN_MAM',...
    'RAIN_JJA',...
    'RAIN_SON',...
    'years_DJF',...
    'years_MAM',...
    'years_JJA',...
    'years_SON',...
    'region_names',...
    'season_names',...
    'variant_names',...
    'variant_labels',...
    'perturbation',...
    'baseline_index');


%% =========================================================
% 25. SAVE CSV FILES
%% =========================================================

writetable(...
    ResultsTable,...
    'seasonal_box_sensitivity_results.csv');


writetable(...
    SummaryTable,...
    'seasonal_box_sensitivity_summary.csv');


%% =========================================================
% 26. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL BOX SENSITIVITY COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n');

fprintf('1. seasonal_box_sensitivity_results.mat\n');

fprintf('2. seasonal_box_sensitivity_results.csv\n');

fprintf('3. seasonal_box_sensitivity_summary.csv\n');


fprintf('\nInterpretation principle:\n');

fprintf(['A seasonal relationship is considered spatially ',...
         'stable when reasonable box perturbations preserve ',...
         'its sign and produce only modest changes in r.\n']);


fprintf('\nNext step:\n');

fprintf(['04_Plot_Box_Sensitivity.m will visualize the ',...
         'change in seasonal correlation across the five ',...
         'SST box definitions.\n']);