%% =========================================================
% 04_Deseasonalized_Anomaly.m
%
% DESEASONALIZED MONTHLY ANOMALY
% Flores - Sumba - Timor
%
% Period : January 2016 - December 2025
%
% Formula:
%
% anomaly(t) =
% raw value(t) - climatological mean of the same calendar month
%
% Example:
% SST anomaly Jan 2018 =
% SST Jan 2018 - mean(all January SST)
%
% Inputs:
%   regional_timeseries_raw.mat
%   regional_monthly_climatology.mat
%
% Units:
%   SST anomaly      = degree C
%   Rainfall anomaly = mm/month
%
% Output:
%   regional_timeseries_anomaly.mat
%   regional_timeseries_anomaly.csv
%
% Run from:
%   Data\3-Timeseries
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD RAW REGIONAL TIME SERIES
%% =========================================================

load('regional_timeseries_raw.mat',...
    'time',...
    'sst_flores',...
    'sst_sumba',...
    'sst_timor',...
    'prec_flores',...
    'prec_sumba',...
    'prec_timor');


%% =========================================================
% 2. LOAD REGIONAL MONTHLY CLIMATOLOGY
%% =========================================================

load('regional_monthly_climatology.mat',...
    'clim_sst_flores',...
    'clim_sst_sumba',...
    'clim_sst_timor',...
    'clim_prec_flores',...
    'clim_prec_sumba',...
    'clim_prec_timor');


%% =========================================================
% 3. CHECK LENGTH
%% =========================================================

Ntime = length(time);

fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZED ANOMALY PROCESSING\n')
fprintf('=========================================================\n')

fprintf('Number of monthly records = %d\n',Ntime);


%% =========================================================
% 4. PREALLOCATE ANOMALY VARIABLES
%% =========================================================

% SST anomaly
anom_sst_flores = NaN(Ntime,1);
anom_sst_sumba  = NaN(Ntime,1);
anom_sst_timor  = NaN(Ntime,1);

% Rainfall anomaly
anom_prec_flores = NaN(Ntime,1);
anom_prec_sumba  = NaN(Ntime,1);
anom_prec_timor  = NaN(Ntime,1);


%% =========================================================
% 5. CALCULATE DESEASONALIZED ANOMALIES
%% =========================================================

for k = 1:Ntime

    % Calendar month number: 1-12
    m = month(time(k));


    %% -----------------------------------------------------
    % SST
    %% -----------------------------------------------------

    if ~isnan(sst_flores(k))

        anom_sst_flores(k) = ...
            sst_flores(k) - clim_sst_flores(m);

    end


    if ~isnan(sst_sumba(k))

        anom_sst_sumba(k) = ...
            sst_sumba(k) - clim_sst_sumba(m);

    end


    if ~isnan(sst_timor(k))

        anom_sst_timor(k) = ...
            sst_timor(k) - clim_sst_timor(m);

    end


    %% -----------------------------------------------------
    % RAINFALL
    %% -----------------------------------------------------

    if ~isnan(prec_flores(k))

        anom_prec_flores(k) = ...
            prec_flores(k) - clim_prec_flores(m);

    end


    if ~isnan(prec_sumba(k))

        anom_prec_sumba(k) = ...
            prec_sumba(k) - clim_prec_sumba(m);

    end


    if ~isnan(prec_timor(k))

        anom_prec_timor(k) = ...
            prec_timor(k) - clim_prec_timor(m);

    end

end


%% =========================================================
% 6. BASIC VALID-DATA CHECK
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID ANOMALY MONTHS\n')
fprintf('=========================================================\n')

fprintf('\nSST anomaly:\n')

fprintf('Flores = %d / %d\n',...
    sum(~isnan(anom_sst_flores)),...
    Ntime);

fprintf('Sumba  = %d / %d\n',...
    sum(~isnan(anom_sst_sumba)),...
    Ntime);

fprintf('Timor  = %d / %d\n',...
    sum(~isnan(anom_sst_timor)),...
    Ntime);


fprintf('\nRainfall anomaly:\n')

fprintf('Flores = %d / %d\n',...
    sum(~isnan(anom_prec_flores)),...
    Ntime);

fprintf('Sumba  = %d / %d\n',...
    sum(~isnan(anom_prec_sumba)),...
    Ntime);

fprintf('Timor  = %d / %d\n',...
    sum(~isnan(anom_prec_timor)),...
    Ntime);


%% =========================================================
% 7. OVERALL ANOMALY SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ANOMALY SUMMARY\n')
fprintf('=========================================================\n')


%% SST

fprintf('\nSST anomaly (degree C)\n')

fprintf('Flores : mean = %+.6f | min = %+.2f | max = %+.2f\n',...
    mean(anom_sst_flores,'omitnan'),...
    min(anom_sst_flores,[],'omitnan'),...
    max(anom_sst_flores,[],'omitnan'));

fprintf('Sumba  : mean = %+.6f | min = %+.2f | max = %+.2f\n',...
    mean(anom_sst_sumba,'omitnan'),...
    min(anom_sst_sumba,[],'omitnan'),...
    max(anom_sst_sumba,[],'omitnan'));

fprintf('Timor  : mean = %+.6f | min = %+.2f | max = %+.2f\n',...
    mean(anom_sst_timor,'omitnan'),...
    min(anom_sst_timor,[],'omitnan'),...
    max(anom_sst_timor,[],'omitnan'));


%% Rainfall

fprintf('\nRainfall anomaly (mm/month)\n')

fprintf('Flores : mean = %+.6f | min = %+.1f | max = %+.1f\n',...
    mean(anom_prec_flores,'omitnan'),...
    min(anom_prec_flores,[],'omitnan'),...
    max(anom_prec_flores,[],'omitnan'));

fprintf('Sumba  : mean = %+.6f | min = %+.1f | max = %+.1f\n',...
    mean(anom_prec_sumba,'omitnan'),...
    min(anom_prec_sumba,[],'omitnan'),...
    max(anom_prec_sumba,[],'omitnan'));

fprintf('Timor  : mean = %+.6f | min = %+.1f | max = %+.1f\n',...
    mean(anom_prec_timor,'omitnan'),...
    min(anom_prec_timor,[],'omitnan'),...
    max(anom_prec_timor,[],'omitnan'));


%% =========================================================
% 8. CRITICAL QUALITY CONTROL
%
% If deseasonalization is correct:
% mean anomaly for EACH calendar month should be ~ 0.
%% =========================================================

mean_month_sst_F = NaN(12,1);
mean_month_sst_S = NaN(12,1);
mean_month_sst_T = NaN(12,1);

mean_month_prec_F = NaN(12,1);
mean_month_prec_S = NaN(12,1);
mean_month_prec_T = NaN(12,1);


for m = 1:12

    idx = month(time) == m;


    %% SST
    mean_month_sst_F(m) = ...
        mean(anom_sst_flores(idx),'omitnan');

    mean_month_sst_S(m) = ...
        mean(anom_sst_sumba(idx),'omitnan');

    mean_month_sst_T(m) = ...
        mean(anom_sst_timor(idx),'omitnan');


    %% Rainfall
    mean_month_prec_F(m) = ...
        mean(anom_prec_flores(idx),'omitnan');

    mean_month_prec_S(m) = ...
        mean(anom_prec_sumba(idx),'omitnan');

    mean_month_prec_T(m) = ...
        mean(anom_prec_timor(idx),'omitnan');

end


%% =========================================================
% 9. DISPLAY MONTHLY QC
%% =========================================================

month_name = {...
    'Jan';'Feb';'Mar';'Apr';...
    'May';'Jun';'Jul';'Aug';...
    'Sep';'Oct';'Nov';'Dec'};


fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY ANOMALY MEAN CHECK - SST\n')
fprintf('All values should be approximately ZERO\n')
fprintf('=========================================================\n')

fprintf('\nMonth       Flores          Sumba          Timor\n')
fprintf('---------------------------------------------------------\n')

for m = 1:12

    fprintf('%-4s     %+12.8f   %+12.8f   %+12.8f\n',...
        month_name{m},...
        mean_month_sst_F(m),...
        mean_month_sst_S(m),...
        mean_month_sst_T(m));

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY ANOMALY MEAN CHECK - RAINFALL\n')
fprintf('All values should be approximately ZERO\n')
fprintf('=========================================================\n')

fprintf('\nMonth       Flores          Sumba          Timor\n')
fprintf('---------------------------------------------------------\n')

for m = 1:12

    fprintf('%-4s     %+12.8f   %+12.8f   %+12.8f\n',...
        month_name{m},...
        mean_month_prec_F(m),...
        mean_month_prec_S(m),...
        mean_month_prec_T(m));

end


%% =========================================================
% 10. MAXIMUM ABSOLUTE MONTHLY-MEAN ERROR
%
% Useful simple QC metric.
%% =========================================================

max_error_sst = max(abs([...
    mean_month_sst_F;...
    mean_month_sst_S;...
    mean_month_sst_T]),...
    [],...
    'omitnan');


max_error_prec = max(abs([...
    mean_month_prec_F;...
    mean_month_prec_S;...
    mean_month_prec_T]),...
    [],...
    'omitnan');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZATION QC SUMMARY\n')
fprintf('=========================================================\n')

fprintf('Maximum |monthly mean anomaly| SST      = %.10f C\n',...
    max_error_sst);

fprintf('Maximum |monthly mean anomaly| Rainfall = %.10f mm/month\n',...
    max_error_prec);


%% =========================================================
% 11. CHECK OCTOBER-NOVEMBER 2025
%% =========================================================

idx_oct2025 = ...
    year(time)==2025 & month(time)==10;

idx_nov2025 = ...
    year(time)==2025 & month(time)==11;


fprintf('\n')
fprintf('=========================================================\n')
fprintf('MISSING SST CHECK\n')
fprintf('=========================================================\n')


fprintf('Oct 2025 SST anomaly:\n')
fprintf('Flores = %g | Sumba = %g | Timor = %g\n',...
    anom_sst_flores(idx_oct2025),...
    anom_sst_sumba(idx_oct2025),...
    anom_sst_timor(idx_oct2025));


fprintf('\nNov 2025 SST anomaly:\n')
fprintf('Flores = %g | Sumba = %g | Timor = %g\n',...
    anom_sst_flores(idx_nov2025),...
    anom_sst_sumba(idx_nov2025),...
    anom_sst_timor(idx_nov2025));


fprintf('\nExpected result: NaN for all SST anomalies.\n');


%% =========================================================
% 12. CREATE OUTPUT TABLE
%% =========================================================

AnomalyTable = table(...
    time,...
    anom_sst_flores,...
    anom_sst_sumba,...
    anom_sst_timor,...
    anom_prec_flores,...
    anom_prec_sumba,...
    anom_prec_timor,...
    'VariableNames',{...
    'Time',...
    'SST_Anomaly_Flores_C',...
    'SST_Anomaly_Sumba_C',...
    'SST_Anomaly_Timor_C',...
    'Rain_Anomaly_Flores_mm_month',...
    'Rain_Anomaly_Sumba_mm_month',...
    'Rain_Anomaly_Timor_mm_month'});


%% =========================================================
% 13. MONTHLY QC TABLE
%% =========================================================

MonthlyQC = table(...
    (1:12)',...
    month_name,...
    mean_month_sst_F,...
    mean_month_sst_S,...
    mean_month_sst_T,...
    mean_month_prec_F,...
    mean_month_prec_S,...
    mean_month_prec_T,...
    'VariableNames',{...
    'MonthNumber',...
    'Month',...
    'Mean_SST_Anomaly_Flores',...
    'Mean_SST_Anomaly_Sumba',...
    'Mean_SST_Anomaly_Timor',...
    'Mean_Rain_Anomaly_Flores',...
    'Mean_Rain_Anomaly_Sumba',...
    'Mean_Rain_Anomaly_Timor'});


%% =========================================================
% 14. DISPLAY FIRST 6 MONTHS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FIRST 6 MONTHS OF DESEASONALIZED ANOMALIES\n')
fprintf('=========================================================\n')

disp(AnomalyTable(1:6,:))


%% =========================================================
% 15. DISPLAY LAST 6 MONTHS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('LAST 6 MONTHS OF DESEASONALIZED ANOMALIES\n')
fprintf('=========================================================\n')

disp(AnomalyTable(end-5:end,:))


%% =========================================================
% 16. SAVE MAT FILE
%% =========================================================

save('regional_timeseries_anomaly.mat',...
    'time',...
    'anom_sst_flores',...
    'anom_sst_sumba',...
    'anom_sst_timor',...
    'anom_prec_flores',...
    'anom_prec_sumba',...
    'anom_prec_timor',...
    'mean_month_sst_F',...
    'mean_month_sst_S',...
    'mean_month_sst_T',...
    'mean_month_prec_F',...
    'mean_month_prec_S',...
    'mean_month_prec_T');


%% =========================================================
% 17. SAVE CSV FILES
%% =========================================================

writetable(...
    AnomalyTable,...
    'regional_timeseries_anomaly.csv');


writetable(...
    MonthlyQC,...
    'deseasonalization_monthly_QC.csv');


%% =========================================================
% 18. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('DESEASONALIZATION COMPLETED\n')
fprintf('=========================================================\n')

fprintf('\nFiles saved:\n')
fprintf('1. regional_timeseries_anomaly.mat\n')
fprintf('2. regional_timeseries_anomaly.csv\n')
fprintf('3. deseasonalization_monthly_QC.csv\n')

fprintf('\nUnits:\n')
fprintf('SST anomaly      = degree C\n')
fprintf('Rainfall anomaly = mm/month\n')

fprintf('\nNext step:\n')
fprintf('Plot deseasonalized SST and rainfall anomalies.\n')