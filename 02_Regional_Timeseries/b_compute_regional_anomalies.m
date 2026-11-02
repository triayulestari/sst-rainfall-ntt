%% ========================================================================
% b_compute_regional_anomalies.m
% REGIONAL MONTHLY MEANS, ANOMALIES, AND DETRENDING | NTT 2016-2025
%
% MATLAB R2021a
% Save and run this script from Data/02_Regional_Timeseries/
% Input (in the SAME folder): regional_timeseries_raw.mat
%
% Outputs (in the SAME folder):
%   regional_calendar_month_means.csv       (12 calendar-month means)
%   regional_anomalies.csv                 (all 120 month positions)
%   regional_detrending_summary.csv        (linear trend details)
%   regional_anomalies.mat                 (data for subsequent scripts)
%
% DEFINITIONS:
%  1. Overall-mean anomaly = monthly value - available 2016-2025 mean.
%  2. Deseasonalized anomaly = monthly value - mean for the SAME calendar
%     month during 2016-2025 (Jan from Jan, Feb from Feb, etc.).
%  3. Deseasonalized+detrended anomaly = residual after subtracting a fitted
%     LINEAR trend from the deseasonalized anomaly series.
%
% Missing SST in October and November 2025 remains NaN. Time positions
% are not compressed or interpolated. No unit conversions are performed.
% These 2016-2025 means are study-period means, NOT a 30-year climate normal.
%% ========================================================================

clc;
clear;

%% 1. File paths and input
script_path = mfilename('fullpath');
if isempty(script_path)
    error('Please save this script as b_compute_regional_anomalies.m first.');
end
folder_out = fileparts(script_path);
input_file = fullfile(folder_out,'regional_timeseries_raw.mat');
if ~isfile(input_file)
    error('Missing input file: %s. Run a_extract_regional_timeseries.m first.',input_file);
end
D = load(input_file);

required = {'time','sst_flores','sst_sumba','sst_timor', ...
    'prec_flores','prec_sumba','prec_timor'};
for i = 1:numel(required)
    if ~isfield(D,required{i})
        error('Input MAT is missing the variable: %s',required{i});
    end
end

time = D.time(:);
if ~isdatetime(time)
    error('Expected a MATLAB datetime variable named time.');
end
SST = [D.sst_flores(:),D.sst_sumba(:),D.sst_timor(:)];
RAIN = [D.prec_flores(:),D.prec_sumba(:),D.prec_timor(:)];
regions = {'Flores','Sumba','Timor'};
nMonths = 120;
if ~isequal(size(SST),[nMonths,3]) || ...
        ~isequal(size(RAIN),[nMonths,3]) || numel(time) ~= nMonths
    error('Expected 120 time positions and 3 regions for both variables.');
end
expected_time = datetime(2016,1,1) + calmonths((0:nMonths-1)');
if ~all(time == expected_time)
    error('Time must contain consecutive calendar months from Jan-2016 to Dec-2025.');
end
if any(~isfinite(RAIN(:)))
    error('CHIRPS rainfall contains missing/nonfinite regional monthly values.');
end
expected_missing = (year(time) == 2025) & ...
    ((month(time) == 10) | (month(time) == 11));
if ~all(all(isnan(SST(expected_missing,:)))) || ...
        any(any(~isfinite(SST(~expected_missing,:))))
    error('Unexpected SST missing-value pattern. Check the raw regional series.');
end

%% 2. Allocate analysis products
month_num = month(time);
SST_calendar_mean = NaN(12,3);
RAIN_calendar_mean = NaN(12,3);
N_SST_calendar = zeros(12,3);
N_RAIN_calendar = zeros(12,3);
SST_overall_mean = NaN(1,3);
RAIN_overall_mean = NaN(1,3);
SST_overall_anom = NaN(nMonths,3);
RAIN_overall_anom = NaN(nMonths,3);
SST_deseason = NaN(nMonths,3);
RAIN_deseason = NaN(nMonths,3);
SST_deseason_detrended = NaN(nMonths,3);
RAIN_deseason_detrended = NaN(nMonths,3);
trend_slope_SST_per_year = NaN(3,1);
trend_slope_RAIN_per_year = NaN(3,1);
trend_intercept_SST = NaN(3,1);
trend_intercept_RAIN = NaN(3,1);

%% 3. Study-period means and calendar-month means
for r = 1:3
    a = SST(:,r);
    b = RAIN(:,r);
    SST_overall_mean(r) = mean(a(isfinite(a)));
    RAIN_overall_mean(r) = mean(b(isfinite(b)));
    SST_overall_anom(:,r) = a - SST_overall_mean(r);
    RAIN_overall_anom(:,r) = b - RAIN_overall_mean(r);

    for mo = 1:12
        ix = month_num == mo;
        x = a(ix);
        y = b(ix);
        valid_x = isfinite(x);
        valid_y = isfinite(y);
        N_SST_calendar(mo,r) = sum(valid_x);
        N_RAIN_calendar(mo,r) = sum(valid_y);
        if ~any(valid_x) || ~any(valid_y)
            error('Empty calendar-month sample for %s month %02d.',regions{r},mo);
        end
        SST_calendar_mean(mo,r) = mean(x(valid_x));
        RAIN_calendar_mean(mo,r) = mean(y(valid_y));
        SST_deseason(ix,r) = x - SST_calendar_mean(mo,r);
        RAIN_deseason(ix,r) = y - RAIN_calendar_mean(mo,r);
    end
end

%% 4. Linear detrending with actual time positions (missing months remain gaps)
% Fit y = slope * elapsed_months + intercept to valid deseasonalized data.
% This is different from simply subtracting the overall mean.
t = (0:nMonths-1)';  % real elapsed calendar months, no compression
for r = 1:3
    x = SST_deseason(:,r);
    y = RAIN_deseason(:,r);
    ix_sst = isfinite(x);
    ix_rain = isfinite(y);
    ps = polyfit(t(ix_sst),x(ix_sst),1);
    pr = polyfit(t(ix_rain),y(ix_rain),1);
    SST_deseason_detrended(ix_sst,r) = x(ix_sst) - polyval(ps,t(ix_sst));
    RAIN_deseason_detrended(ix_rain,r) = y(ix_rain) - polyval(pr,t(ix_rain));
    trend_slope_SST_per_year(r) = ps(1)*12;
    trend_slope_RAIN_per_year(r) = pr(1)*12;
    trend_intercept_SST(r) = ps(2);
    trend_intercept_RAIN(r) = pr(2);
end

%% 5. Table of 2016-2025 calendar-month means and observation counts
month_names = {'Jan';'Feb';'Mar';'Apr';'May';'Jun'; ...
    'Jul';'Aug';'Sep';'Oct';'Nov';'Dec'};
Calendar = table((1:12)',month_names,'VariableNames',{'Month','Month_Name'});
for r = 1:3
    region = regions{r};
    Calendar.(['SST_' region '_mean_C']) = SST_calendar_mean(:,r);
    Calendar.(['Rain_' region '_mean_mm_month']) = RAIN_calendar_mean(:,r);
    Calendar.(['N_SST_' region]) = N_SST_calendar(:,r);
    Calendar.(['N_Rain_' region]) = N_RAIN_calendar(:,r);
end
writetable(Calendar,fullfile(folder_out,'regional_calendar_month_means.csv'));

%% 6. A fully labeled CSV with every type of anomaly
Anomalies = table(time,'VariableNames',{'Time'});
for r = 1:3
    region = regions{r};
    Anomalies.(['SST_' region '_overall_anom_C']) = SST_overall_anom(:,r);
    Anomalies.(['Rain_' region '_overall_anom_mm_month']) = RAIN_overall_anom(:,r);
    Anomalies.(['SST_' region '_deseason_C']) = SST_deseason(:,r);
    Anomalies.(['Rain_' region '_deseason_mm_month']) = RAIN_deseason(:,r);
    Anomalies.(['SST_' region '_deseason_detrended_C']) = ...
        SST_deseason_detrended(:,r);
    Anomalies.(['Rain_' region '_deseason_detrended_mm_month']) = ...
        RAIN_deseason_detrended(:,r);
end
writetable(Anomalies,fullfile(folder_out,'regional_anomalies.csv'));

%% 7. Trend settings and diagnostic correlations
Region = regions(:);
Detrend = table(Region,trend_slope_SST_per_year, ...
    trend_slope_RAIN_per_year,trend_intercept_SST,trend_intercept_RAIN, ...
    'VariableNames',{'Region','SST_Slope_C_per_year', ...
    'Rain_Slope_mm_month_per_year','SST_Intercept_C', ...
    'Rain_Intercept_mm_month'});
writetable(Detrend,fullfile(folder_out,'regional_detrending_summary.csv'));

fprintf('\n===== ANOMALY CALCULATION QC =====\n');
fprintf('Period: Jan 2016 to Dec 2025 (120 calendar positions)\n');
for r = 1:3
    ix = isfinite(SST(:,r)) & isfinite(RAIN(:,r));
    r_raw = corr(SST(ix,r),RAIN(ix,r),'Type','Pearson');
    r_overall = corr(SST_overall_anom(ix,r),RAIN_overall_anom(ix,r), ...
        'Type','Pearson');
    r_deseason = corr(SST_deseason(ix,r),RAIN_deseason(ix,r), ...
        'Type','Pearson');
    if abs(r_raw-r_overall) > 1e-10
        error('Overall-mean centering must NOT change Pearson r (%s).',regions{r});
    end
    fprintf('%s: pairs=%d, raw r=%+.4f, overall-anomaly r=%+.4f, deseason r=%+.4f\n', ...
        regions{r},sum(ix),r_raw,r_overall,r_deseason);
end
fprintf('SST Oct/Nov 2025 samples per calendar month: n=9.\n');
fprintf('Other SST calendar months: n=10; all CHIRPS months: n=10.\n');

%% 8. Store reproducible MATLAB variables for subsequent stages
anom_sst_flores = SST_deseason(:,1);
anom_sst_sumba  = SST_deseason(:,2);
anom_sst_timor  = SST_deseason(:,3);
anom_prec_flores = RAIN_deseason(:,1);
anom_prec_sumba  = RAIN_deseason(:,2);
anom_prec_timor  = RAIN_deseason(:,3);
save(fullfile(folder_out,'regional_anomalies.mat'), ...
    'time','regions','SST','RAIN','month_num', ...
    'SST_calendar_mean','RAIN_calendar_mean','N_SST_calendar','N_RAIN_calendar', ...
    'SST_overall_mean','RAIN_overall_mean', ...
    'SST_overall_anom','RAIN_overall_anom', ...
    'SST_deseason','RAIN_deseason', ...
    'SST_deseason_detrended','RAIN_deseason_detrended', ...
    'anom_sst_flores','anom_sst_sumba','anom_sst_timor', ...
    'anom_prec_flores','anom_prec_sumba','anom_prec_timor', ...
    'trend_slope_SST_per_year','trend_slope_RAIN_per_year');

fprintf('\nSaved in: %s\n',folder_out);
fprintf('  regional_calendar_month_means.csv\n');
fprintf('  regional_anomalies.csv\n');
fprintf('  regional_detrending_summary.csv\n');
fprintf('  regional_anomalies.mat\n');
fprintf('DONE. Original raw files were NOT modified.\n');
