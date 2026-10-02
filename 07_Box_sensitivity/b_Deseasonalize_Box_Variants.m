%% =========================================================
% 02_Deseasonalize_Box_Variants.m
%
% FINAL VERSION
%
% DESEASONALIZE SST BOX VARIANTS
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Variants:
%   Shrink 0.2
%   Shrink 0.1
%   Baseline
%   Expand 0.1
%   Expand 0.2
%
% Method:
%
%   SST anomaly(t) =
%       SST(t) - monthly climatology(calendar month)
%
% IMPORTANT:
%
% Each region-box combination has its OWN
% monthly climatology.
%
% Period:
%   January 2016 - December 2025
%
% Expected climatology sample:
%
%   Jan-Sep = 10 years
%   Oct     = 9 years
%   Nov     = 9 years
%   Dec     = 10 years
%
% Inputs:
%
%   sst_box_variants_2016_2025.mat
%
% Optional baseline QC:
%
%   ..\3-Timeseries\regional_timeseries_anomaly.mat
%
% Outputs:
%
%   sst_box_variants_anomaly.mat
%   sst_box_variants_climatology.csv
%   sst_box_variants_anomaly.csv
%   sst_box_variants_anomaly_QC.csv
%
% MATLAB R2021a
% No local functions.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD BOX-VARIANT SST
%% =========================================================

load(...
    'sst_box_variants_2016_2025.mat',...
    'time',...
    'Year',...
    'Month',...
    'region_names',...
    'variant_names',...
    'variant_labels',...
    'perturbation',...
    'baseline_index',...
    'baseline_bounds',...
    'box_bounds',...
    'sst_variant',...
    'valid_month_count');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZE SST BOX VARIANTS\n')
fprintf('=========================================================\n')


%% =========================================================
% 2. DIMENSION QC
%% =========================================================

[n_time,n_variants,n_regions] = ...
    size(sst_variant);


if n_time ~= 120

    error(...
        'Expected 120 monthly positions, found %d.',...
        n_time);

end


if n_variants ~= 5

    error(...
        'Expected 5 box variants, found %d.',...
        n_variants);

end


if n_regions ~= 3

    error(...
        'Expected 3 regions, found %d.',...
        n_regions);

end


fprintf('Time positions = %d\n',...
    n_time);

fprintf('Box variants   = %d\n',...
    n_variants);

fprintf('Regions        = %d\n',...
    n_regions);


%% =========================================================
% 3. CHECK TIME VECTOR
%% =========================================================

if ...
    year(time(1)) ~= 2016 || ...
    month(time(1)) ~= 1

    error(...
        'First time position is not Jan-2016.');

end


if ...
    year(time(end)) ~= 2025 || ...
    month(time(end)) ~= 12

    error(...
        'Last time position is not Dec-2025.');

end


fprintf('Period         = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));


%% =========================================================
% 4. PREALLOCATE MONTHLY CLIMATOLOGY
%
% Dimensions:
%
%   calendar month x variant x region
%% =========================================================

sst_climatology = ...
    NaN(...
    12,...
    n_variants,...
    n_regions);


climatology_n = ...
    NaN(...
    12,...
    n_variants,...
    n_regions);


%% =========================================================
% 5. CALCULATE MONTHLY CLIMATOLOGY
%% =========================================================

for rgn = 1:n_regions

    for v = 1:n_variants

        for m = 1:12

            idx_month = ...
                Month == m;


            tmp = ...
                sst_variant(...
                idx_month,...
                v,...
                rgn);


            valid_tmp = ...
                tmp(...
                ~isnan(tmp));


            climatology_n(m,v,rgn) = ...
                length(valid_tmp);


            if ~isempty(valid_tmp)

                sst_climatology(m,v,rgn) = ...
                    mean(valid_tmp);

            end

        end

    end

end


%% =========================================================
% 6. CLIMATOLOGY SAMPLE-SIZE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY CLIMATOLOGY SAMPLE QC\n')
fprintf('=========================================================\n')


expected_n = [...
    10;...
    10;...
    10;...
    10;...
    10;...
    10;...
    10;...
    10;...
    10;...
     9;...
     9;...
    10];


month_names = {...
    'Jan';...
    'Feb';...
    'Mar';...
    'Apr';...
    'May';...
    'Jun';...
    'Jul';...
    'Aug';...
    'Sep';...
    'Oct';...
    'Nov';...
    'Dec'};


sample_qc_pass = ...
    true;


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        current_n = ...
            squeeze(...
            climatology_n(:,v,rgn));


        if any(current_n ~= expected_n)

            sample_qc_pass = ...
                false;


            fprintf(...
                '%-13s = FAILED\n',...
                variant_labels{v});


        else

            fprintf(...
                '%-13s = PASSED\n',...
                variant_labels{v});

        end

    end

end


if ~sample_qc_pass

    error([...
        'Monthly climatology sample-size QC failed. ',...
        'Expected Oct-Nov n=9 and all other months n=10.']);

end


fprintf('\n')
fprintf(['All climatologies use n=10 except ',...
         'Oct-Nov, where n=9.\n']);


%% =========================================================
% 7. CALCULATE DESEASONALIZED SST ANOMALIES
%
% Dimensions:
%
%   time x variant x region
%% =========================================================

sst_anomaly = ...
    NaN(...
    n_time,...
    n_variants,...
    n_regions);


for rgn = 1:n_regions

    for v = 1:n_variants

        for t = 1:n_time

            if ~isnan(sst_variant(t,v,rgn))

                m = ...
                    Month(t);


                sst_anomaly(t,v,rgn) = ...
                    sst_variant(t,v,rgn) - ...
                    sst_climatology(m,v,rgn);

            end

        end

    end

end


%% =========================================================
% 8. VALID ANOMALY MONTH QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID ANOMALY MONTH QC\n')
fprintf('=========================================================\n')


valid_anomaly_months = ...
    NaN(...
    n_regions,...
    n_variants);


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        valid_anomaly_months(rgn,v) = ...
            sum(...
            ~isnan(...
            sst_anomaly(:,v,rgn)));


        fprintf(...
            '%-13s = %d / 120\n',...
            variant_labels{v},...
            valid_anomaly_months(rgn,v));

    end

end


if any(valid_anomaly_months(:) ~= 118)

    error([...
        'At least one anomaly series does not contain ',...
        '118 valid months.']);

end


fprintf('\n')
fprintf('All anomaly series contain 118 / 120 valid months.\n');


%% =========================================================
% 9. DESEASONALIZATION QC
%
% For every calendar month, the mean anomaly should be
% numerically approximately zero.
%% =========================================================

monthly_anomaly_mean = ...
    NaN(...
    12,...
    n_variants,...
    n_regions);


for rgn = 1:n_regions

    for v = 1:n_variants

        for m = 1:12

            idx_month = ...
                Month == m;


            monthly_anomaly_mean(m,v,rgn) = ...
                mean(...
                sst_anomaly(...
                idx_month,v,rgn),...
                'omitnan');

        end

    end

end


max_abs_monthly_anomaly_mean = ...
    max(...
    abs(monthly_anomaly_mean(:)),...
    [],...
    'omitnan');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZATION QC\n')
fprintf('=========================================================\n')


fprintf(['Maximum absolute calendar-month ',...
         'mean anomaly = %.12e C\n'],...
    max_abs_monthly_anomaly_mean);


if max_abs_monthly_anomaly_mean > 1e-10

    warning([...
        'Monthly anomaly means are larger than ',...
        'expected numerical precision.']);

else

    fprintf(['QC PASSED: all calendar-month ',...
             'anomaly means are approximately zero.\n']);

end


%% =========================================================
% 10. CLIMATOLOGY VALUES
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('BASELINE MONTHLY SST CLIMATOLOGY\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for m = 1:12

        fprintf(...
            '%s = %.3f C | n=%d\n',...
            month_names{m},...
            sst_climatology(...
            m,...
            baseline_index,...
            rgn),...
            climatology_n(...
            m,...
            baseline_index,...
            rgn));

    end

end


%% =========================================================
% 11. ANOMALY RANGE QC
%% =========================================================

anomaly_min = ...
    NaN(...
    n_regions,...
    n_variants);


anomaly_max = ...
    NaN(...
    n_regions,...
    n_variants);


anomaly_mean = ...
    NaN(...
    n_regions,...
    n_variants);


anomaly_std = ...
    NaN(...
    n_regions,...
    n_variants);


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SST ANOMALY RANGE QC\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        tmp = ...
            sst_anomaly(:,v,rgn);


        anomaly_min(rgn,v) = ...
            min(...
            tmp,...
            [],...
            'omitnan');


        anomaly_max(rgn,v) = ...
            max(...
            tmp,...
            [],...
            'omitnan');


        anomaly_mean(rgn,v) = ...
            mean(...
            tmp,...
            'omitnan');


        anomaly_std(rgn,v) = ...
            std(...
            tmp,...
            'omitnan');


        fprintf(...
            ['%-13s = min %+.3f | max %+.3f | ',...
             'mean %+.6f | SD %.3f C\n'],...
            variant_labels{v},...
            anomaly_min(rgn,v),...
            anomaly_max(rgn,v),...
            anomaly_mean(rgn,v),...
            anomaly_std(rgn,v));

    end

end


%% =========================================================
% 12. HARD BASELINE REPRODUCTION QC
%
% Compare baseline anomalies with the locked regional
% anomaly time series from Folder 3.
%% =========================================================

regional_file = ...
    fullfile(...
    '..',...
    '3-Timeseries',...
    'regional_timeseries_anomaly.mat');


baseline_main_qc_available = ...
    false;


baseline_main_maxdiff = ...
    NaN(3,1);


if exist(regional_file,'file') == 2

    Main = ...
        load(regional_file);


    required_main_vars = {...
        'time',...
        'anom_sst_flores',...
        'anom_sst_sumba',...
        'anom_sst_timor'};


    has_all_main_vars = ...
        true;


    for i = 1:length(required_main_vars)

        if ~isfield(...
                Main,...
                required_main_vars{i})

            has_all_main_vars = ...
                false;

        end

    end


    if has_all_main_vars

        if ...
            length(Main.time(:)) == length(time) && ...
            all(Main.time(:) == time(:))

            baseline_main_qc_available = ...
                true;


            main_anomaly = [...
                Main.anom_sst_flores(:),...
                Main.anom_sst_sumba(:),...
                Main.anom_sst_timor(:)];


            fprintf('\n')
            fprintf('=========================================================\n')
            fprintf('BASELINE ANOMALY REPRODUCTION QC\n')
            fprintf('=========================================================\n')


            for rgn = 1:n_regions

                current_baseline = ...
                    sst_anomaly(...
                    :,baseline_index,rgn);


                main_series = ...
                    main_anomaly(:,rgn);


                valid_pair = ...
                    ~isnan(current_baseline) & ...
                    ~isnan(main_series);


                baseline_main_maxdiff(rgn) = ...
                    max(...
                    abs(...
                    current_baseline(valid_pair) - ...
                    main_series(valid_pair)));


                fprintf(...
                    '%-8s max absolute difference = %.12e C\n',...
                    region_names{rgn},...
                    baseline_main_maxdiff(rgn));

            end


            if all(baseline_main_maxdiff < 1e-10)

                fprintf('\n')
                fprintf(['QC PASSED: baseline anomalies exactly ',...
                         'reproduce the main analysis.\n']);


            else

                error([...
                    'Baseline anomaly reproduction QC FAILED. ',...
                    'Do not continue.']);

            end

        end

    end

end


if ~baseline_main_qc_available

    fprintf('\n')
    fprintf(['NOTE: baseline anomaly comparison with Folder 3 ',...
             'could not be performed automatically.\n']);

end


%% =========================================================
% 13. OCT-NOV 2025 MISSING QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MISSING-MONTH ANOMALY QC\n')
fprintf('=========================================================\n')


idx_oct2025 = ...
    year(time)==2025 & ...
    month(time)==10;


idx_nov2025 = ...
    year(time)==2025 & ...
    month(time)==11;


all_oct_nan = ...
    all(...
    isnan(...
    sst_anomaly(idx_oct2025,:,:)),...
    'all');


all_nov_nan = ...
    all(...
    isnan(...
    sst_anomaly(idx_nov2025,:,:)),...
    'all');


fprintf('Oct-2025 all anomaly values NaN = %d\n',...
    all_oct_nan);


fprintf('Nov-2025 all anomaly values NaN = %d\n',...
    all_nov_nan);


if ...
    ~all_oct_nan || ...
    ~all_nov_nan

    error(...
        'Oct-Nov 2025 missing-value QC failed.');

end


fprintf('Missing-month anomaly QC PASSED.\n');


%% =========================================================
% 14. CREATE CLIMATOLOGY OUTPUT TABLE
%% =========================================================

CalendarMonth = ...
    (1:12)';


MonthName = ...
    month_names;


ClimatologyTable = ...
    table(...
    CalendarMonth,...
    MonthName);


for rgn = 1:n_regions

    for v = 1:n_variants

        var_clim = ...
            sprintf(...
            'Clim_%s_%s',...
            region_names{rgn},...
            variant_names{v});


        var_n = ...
            sprintf(...
            'N_%s_%s',...
            region_names{rgn},...
            variant_names{v});


        ClimatologyTable.(var_clim) = ...
            sst_climatology(:,v,rgn);


        ClimatologyTable.(var_n) = ...
            climatology_n(:,v,rgn);

    end

end


%% =========================================================
% 15. CREATE MONTHLY ANOMALY TABLE
%% =========================================================

AnomalyTable = ...
    table(...
    time,...
    Year,...
    Month);


for rgn = 1:n_regions

    for v = 1:n_variants

        variable_name = ...
            sprintf(...
            'SSTanom_%s_%s',...
            region_names{rgn},...
            variant_names{v});


        AnomalyTable.(variable_name) = ...
            sst_anomaly(:,v,rgn);

    end

end


%% =========================================================
% 16. CREATE QC TABLE
%% =========================================================

n_rows = ...
    n_regions * ...
    n_variants;


QC_Region = ...
    cell(n_rows,1);


QC_Variant = ...
    cell(n_rows,1);


Perturbation_deg = ...
    NaN(n_rows,1);


Valid_months = ...
    NaN(n_rows,1);


Anomaly_min = ...
    NaN(n_rows,1);


Anomaly_max = ...
    NaN(n_rows,1);


Anomaly_mean = ...
    NaN(n_rows,1);


Anomaly_SD = ...
    NaN(n_rows,1);


Max_abs_monthly_mean = ...
    NaN(n_rows,1);


row_counter = ...
    0;


for rgn = 1:n_regions

    for v = 1:n_variants

        row_counter = ...
            row_counter + 1;


        QC_Region{row_counter} = ...
            region_names{rgn};


        QC_Variant{row_counter} = ...
            variant_labels{v};


        Perturbation_deg(row_counter) = ...
            perturbation(v);


        Valid_months(row_counter) = ...
            valid_anomaly_months(rgn,v);


        Anomaly_min(row_counter) = ...
            anomaly_min(rgn,v);


        Anomaly_max(row_counter) = ...
            anomaly_max(rgn,v);


        Anomaly_mean(row_counter) = ...
            anomaly_mean(rgn,v);


        Anomaly_SD(row_counter) = ...
            anomaly_std(rgn,v);


        Max_abs_monthly_mean(row_counter) = ...
            max(...
            abs(...
            monthly_anomaly_mean(:,v,rgn)));

    end

end


AnomalyQCTable = ...
    table(...
    QC_Region,...
    QC_Variant,...
    Perturbation_deg,...
    Valid_months,...
    Anomaly_min,...
    Anomaly_max,...
    Anomaly_mean,...
    Anomaly_SD,...
    Max_abs_monthly_mean);


%% =========================================================
% 17. SAVE MAT FILE
%% =========================================================

save(...
    'sst_box_variants_anomaly.mat',...
    'time',...
    'Year',...
    'Month',...
    'region_names',...
    'variant_names',...
    'variant_labels',...
    'perturbation',...
    'baseline_index',...
    'baseline_bounds',...
    'box_bounds',...
    'sst_variant',...
    'sst_climatology',...
    'climatology_n',...
    'sst_anomaly',...
    'monthly_anomaly_mean',...
    'valid_anomaly_months',...
    'anomaly_min',...
    'anomaly_max',...
    'anomaly_mean',...
    'anomaly_std',...
    'baseline_main_qc_available',...
    'baseline_main_maxdiff',...
    'ClimatologyTable',...
    'AnomalyTable',...
    'AnomalyQCTable');


%% =========================================================
% 18. SAVE CSV FILES
%% =========================================================

writetable(...
    ClimatologyTable,...
    'sst_box_variants_climatology.csv');


writetable(...
    AnomalyTable,...
    'sst_box_variants_anomaly.csv');


writetable(...
    AnomalyQCTable,...
    'sst_box_variants_anomaly_QC.csv');


%% =========================================================
% 19. FINAL QC SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL DESEASONALIZATION QC\n')
fprintf('=========================================================\n')


fprintf('\nAll 15 anomaly series:\n');

fprintf('Valid months = 118 / 120\n');


fprintf('\nClimatology sample sizes:\n');

fprintf('Jan-Sep = 10\n');

fprintf('Oct-Nov = 9\n');

fprintf('Dec     = 10\n');


fprintf('\nMaximum absolute calendar-month anomaly mean:\n');

fprintf('%.12e C\n',...
    max_abs_monthly_anomaly_mean);


if baseline_main_qc_available

    fprintf('\nBaseline vs main-analysis max differences:\n');


    for rgn = 1:n_regions

        fprintf('%-8s = %.12e C\n',...
            region_names{rgn},...
            baseline_main_maxdiff(rgn));

    end

end


%% =========================================================
% 20. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('BOX-VARIANT DESEASONALIZATION COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n');

fprintf('1. sst_box_variants_anomaly.mat\n');

fprintf('2. sst_box_variants_climatology.csv\n');

fprintf('3. sst_box_variants_anomaly.csv\n');

fprintf('4. sst_box_variants_anomaly_QC.csv\n');


fprintf('\nMethodological note:\n');

fprintf(['Each region-box variant was deseasonalized ',...
         'using its own 2016-2025 calendar-month ',...
         'climatology.\n']);


fprintf(['No climatology from the Baseline box was ',...
         'reused for Shrink or Expand variants.\n']);


fprintf('\nNext step:\n');

fprintf(['03_Seasonal_Box_Sensitivity.m will correlate ',...
         'each SST-box anomaly variant with the SAME ',...
         'regional rainfall anomalies used in the main ',...
         'analysis.\n']);