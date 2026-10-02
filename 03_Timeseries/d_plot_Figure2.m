%% =========================================================
% FIGURE 2
% Regional Monthly Climatology and Deseasonalized Variability
% Flores - Sumba - Timor, 2016-2025
%
% Run from:
% Data\3-Timeseries
%
% Output:
% Figure2_Regional_Climatology_Deseasonalized.png
% Figure2_Regional_Climatology_Deseasonalized.pdf
%
% IMPORTANT:
% Rainfall in regional_timeseries_raw is already in mm/month.
% DO NOT multiply rainfall by 1000 again.
%% =========================================================

clear;
clc;
close all;

%% =========================================================
% 1. LOAD FINAL REGIONAL MONTHLY TIME SERIES
%% =========================================================

matfile_name = 'regional_timeseries_raw.mat';
csvfile_name = 'regional_timeseries_raw.csv';

if isfile(matfile_name)

    S = load(matfile_name);

    % Check expected variables
    required_vars = { ...
        'time', ...
        'sst_flores', 'sst_sumba', 'sst_timor', ...
        'prec_flores', 'prec_sumba', 'prec_timor'};

    all_exist = true;

    for i = 1:length(required_vars)
        if ~isfield(S, required_vars{i})
            all_exist = false;
        end
    end

    if all_exist

        time        = S.time;

        sst_flores  = S.sst_flores;
        sst_sumba   = S.sst_sumba;
        sst_timor   = S.sst_timor;

        prec_flores = S.prec_flores;
        prec_sumba  = S.prec_sumba;
        prec_timor  = S.prec_timor;

        fprintf('Loaded: %s\n', matfile_name);

    else
        error(['regional_timeseries_raw.mat was found, but the expected ', ...
               'variables were not found.']);
    end

elseif isfile(csvfile_name)

    T = readtable(csvfile_name);

    time        = T.Time;

    sst_flores  = T.SST_Flores_C;
    sst_sumba   = T.SST_Sumba_C;
    sst_timor   = T.SST_Timor_C;

    prec_flores = T.Rain_Flores_mm_month;
    prec_sumba  = T.Rain_Sumba_mm_month;
    prec_timor  = T.Rain_Timor_mm_month;

    fprintf('Loaded: %s\n', csvfile_name);

else

    error(['Neither regional_timeseries_raw.mat nor ', ...
           'regional_timeseries_raw.csv was found in this folder.']);

end


%% =========================================================
% 2. FORMAT TIME
%% =========================================================

if ~isdatetime(time)

    if isnumeric(time)

        % MATLAB datenum
        if mean(time, 'omitnan') > 1e5
            time = datetime(time, 'ConvertFrom', 'datenum');
        else
            error('Numeric time format was not recognized.');
        end

    elseif iscell(time) || isstring(time) || ischar(time)

        time = datetime(time);

    else
        error('Time format was not recognized.');
    end

end


%% =========================================================
% 3. FORCE COLUMN VECTORS
%% =========================================================

time = time(:);

sst_flores = sst_flores(:);
sst_sumba  = sst_sumba(:);
sst_timor  = sst_timor(:);

prec_flores = prec_flores(:);
prec_sumba  = prec_sumba(:);
prec_timor  = prec_timor(:);


%% =========================================================
% 4. SORT CHRONOLOGICALLY
%% =========================================================

[time, idx_sort] = sort(time);

sst_flores = sst_flores(idx_sort);
sst_sumba  = sst_sumba(idx_sort);
sst_timor  = sst_timor(idx_sort);

prec_flores = prec_flores(idx_sort);
prec_sumba  = prec_sumba(idx_sort);
prec_timor  = prec_timor(idx_sort);


%% =========================================================
% 5. BASIC QC
%% =========================================================

fprintf('\n=========================================\n');
fprintf('TIME SERIES CHECK\n');
fprintf('=========================================\n');

fprintf('Start : %s\n', datestr(time(1), 'mmm yyyy'));
fprintf('End   : %s\n', datestr(time(end), 'mmm yyyy'));
fprintf('N time steps = %d\n', length(time));

fprintf('\nValid SST months:\n');
fprintf('Flores = %d\n', sum(isfinite(sst_flores)));
fprintf('Sumba  = %d\n', sum(isfinite(sst_sumba)));
fprintf('Timor  = %d\n', sum(isfinite(sst_timor)));

fprintf('\nValid rainfall months:\n');
fprintf('Flores = %d\n', sum(isfinite(prec_flores)));
fprintf('Sumba  = %d\n', sum(isfinite(prec_sumba)));
fprintf('Timor  = %d\n', sum(isfinite(prec_timor)));


%% =========================================================
% 6. MONTHLY CLIMATOLOGY
% Mean for each calendar month during 2016-2025
%% =========================================================

month_id = month(time);

clim_sst_flores = nan(12,1);
clim_sst_sumba  = nan(12,1);
clim_sst_timor  = nan(12,1);

clim_prec_flores = nan(12,1);
clim_prec_sumba  = nan(12,1);
clim_prec_timor  = nan(12,1);

for m = 1:12

    idx = (month_id == m);

    clim_sst_flores(m) = mean(sst_flores(idx), 'omitnan');
    clim_sst_sumba(m)  = mean(sst_sumba(idx),  'omitnan');
    clim_sst_timor(m)  = mean(sst_timor(idx),  'omitnan');

    clim_prec_flores(m) = mean(prec_flores(idx), 'omitnan');
    clim_prec_sumba(m)  = mean(prec_sumba(idx),  'omitnan');
    clim_prec_timor(m)  = mean(prec_timor(idx),  'omitnan');

end


%% =========================================================
% 7. DESEASONALIZED MONTHLY ANOMALIES
%
% anomaly(t) =
% monthly value(t) - climatology of corresponding calendar month
%% =========================================================

anom_sst_flores = nan(size(sst_flores));
anom_sst_sumba  = nan(size(sst_sumba));
anom_sst_timor  = nan(size(sst_timor));

anom_prec_flores = nan(size(prec_flores));
anom_prec_sumba  = nan(size(prec_sumba));
anom_prec_timor  = nan(size(prec_timor));

for i = 1:length(time)

    m = month_id(i);

    if isfinite(sst_flores(i))
        anom_sst_flores(i) = ...
            sst_flores(i) - clim_sst_flores(m);
    end

    if isfinite(sst_sumba(i))
        anom_sst_sumba(i) = ...
            sst_sumba(i) - clim_sst_sumba(m);
    end

    if isfinite(sst_timor(i))
        anom_sst_timor(i) = ...
            sst_timor(i) - clim_sst_timor(m);
    end


    if isfinite(prec_flores(i))
        anom_prec_flores(i) = ...
            prec_flores(i) - clim_prec_flores(m);
    end

    if isfinite(prec_sumba(i))
        anom_prec_sumba(i) = ...
            prec_sumba(i) - clim_prec_sumba(m);
    end

    if isfinite(prec_timor(i))
        anom_prec_timor(i) = ...
            prec_timor(i) - clim_prec_timor(m);
    end

end


%% =========================================================
% 8. QC - MONTHLY ANOMALY MEANS SHOULD BE ~ ZERO
%% =========================================================

fprintf('\n=========================================\n');
fprintf('DESEASONALIZATION CHECK\n');
fprintf('Monthly anomaly means should be near 0\n');
fprintf('=========================================\n');

for m = 1:12

    idx = (month_id == m);

    fprintf(['Month %2d | SST F=%7.4f S=%7.4f T=%7.4f | ', ...
             'Rain F=%8.3f S=%8.3f T=%8.3f\n'], ...
        m, ...
        mean(anom_sst_flores(idx),'omitnan'), ...
        mean(anom_sst_sumba(idx),'omitnan'), ...
        mean(anom_sst_timor(idx),'omitnan'), ...
        mean(anom_prec_flores(idx),'omitnan'), ...
        mean(anom_prec_sumba(idx),'omitnan'), ...
        mean(anom_prec_timor(idx),'omitnan'));

end


%% =========================================================
% 9. PLOT SETTINGS
%% =========================================================

% Colors consistent across all panels
cFlores = [0.0000 0.4470 0.7410];
cSumba  = [0.8500 0.3250 0.0980];
cTimor  = [0.9290 0.6940 0.1250];

font_name = 'Arial';
font_size = 10;

line_clim = 1.6;
line_anom = 1.25;

marker_size = 4.5;

month_num = 1:12;

month_label = { ...
    'Jan','Feb','Mar','Apr','May','Jun', ...
    'Jul','Aug','Sep','Oct','Nov','Dec'};


%% =========================================================
% 10. CREATE FIGURE
%
% Left column  = narrower climatology panels
% Right column = wider deseasonalized time-series panels
%
% No (a), (b), (c), (d) labels are added here.
%% =========================================================

fig = figure( ...
    'Color','w', ...
    'Units','pixels', ...
    'Position',[50 50 2000 850]);


% ---------------------------------------------------------
% MANUAL PANEL POSITIONS
% [left bottom width height]
% ---------------------------------------------------------

pos_sst_clim  = [0.055 0.555 0.305 0.390];
pos_rain_clim = [0.055 0.095 0.305 0.390];

pos_sst_anom  = [0.425 0.555 0.540 0.390];
pos_rain_anom = [0.425 0.095 0.540 0.390];

%% =========================================================
% PANEL 1 - MONTHLY SST CLIMATOLOGY
%% =========================================================

ax1 = axes('Position', pos_sst_clim);

hold(ax1,'on');

plot(month_num, clim_sst_flores, ...
    '-o', ...
    'Color',cFlores, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

plot(month_num, clim_sst_sumba, ...
    '-s', ...
    'Color',cSumba, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

plot(month_num, clim_sst_timor, ...
    '-^', ...
    'Color',cTimor, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

xlim([1 12]);
ylim([26 31]);

xticks(1:12);
xticklabels(month_label);

ylabel('SST (°C)');

legend({'Flores','Sumba','Timor'}, ...
    'Location','southwest', ...
    'Box','off');

grid on;
box on;

set(ax1, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(ax1,'off');


%% =========================================================
% PANEL 2 - MONTHLY RAINFALL CLIMATOLOGY
%% =========================================================

ax2 = axes('Position', pos_rain_clim);

hold(ax2,'on');

plot(month_num, clim_prec_flores, ...
    '-o', ...
    'Color',cFlores, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

plot(month_num, clim_prec_sumba, ...
    '-s', ...
    'Color',cSumba, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

plot(month_num, clim_prec_timor, ...
    '-^', ...
    'Color',cTimor, ...
    'LineWidth',line_clim, ...
    'MarkerSize',marker_size, ...
    'MarkerFaceColor','none');

xlim([1 12]);
ylim([0 350]);

xticks(1:12);
xticklabels(month_label);

xlabel('Month');
ylabel('Rainfall (mm month^{-1})');

legend({'Flores','Sumba','Timor'}, ...
    'Location','northeast', ...
    'Box','off');

grid on;
box on;

set(ax2, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(ax2,'off');


%% =========================================================
% PANEL 3 - DESEASONALIZED SST ANOMALY
%% =========================================================

ax3 = axes('Position', pos_sst_anom);

hold(ax3,'on');

plot(time, anom_sst_flores, ...
    '-', ...
    'Color',cFlores, ...
    'LineWidth',line_anom);

plot(time, anom_sst_sumba, ...
    '-', ...
    'Color',cSumba, ...
    'LineWidth',line_anom);

plot(time, anom_sst_timor, ...
    '-', ...
    'Color',cTimor, ...
    'LineWidth',line_anom);

yline(0,'--', ...
    'Color',[0.35 0.35 0.35], ...
    'LineWidth',0.9, ...
    'HandleVisibility','off');

xlim([datetime(2016,1,1) datetime(2025,12,31)]);
ylim([-2 2]);

xticks(datetime(2016:2025,1,1));
xticklabels(string(2016:2025));

ylabel('SST anomaly (°C)');

legend({'Flores','Sumba','Timor'}, ...
    'Location','northeast', ...
    'Box','off');

grid on;
box on;

set(ax3, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(ax3,'off');


%% =========================================================
% PANEL 4 - DESEASONALIZED RAINFALL ANOMALY
%% =========================================================

ax4 = axes('Position', pos_rain_anom);

hold(ax4,'on');

plot(time, anom_prec_flores, ...
    '-', ...
    'Color',cFlores, ...
    'LineWidth',line_anom);

plot(time, anom_prec_sumba, ...
    '-', ...
    'Color',cSumba, ...
    'LineWidth',line_anom);

plot(time, anom_prec_timor, ...
    '-', ...
    'Color',cTimor, ...
    'LineWidth',line_anom);

yline(0,'--', ...
    'Color',[0.35 0.35 0.35], ...
    'LineWidth',0.9, ...
    'HandleVisibility','off');

xlim([datetime(2016,1,1) datetime(2025,12,31)]);
ylim([-220 240]);

xticks(datetime(2016:2025,1,1));
xticklabels(string(2016:2025));

xlabel('Year');
ylabel('Rainfall anomaly (mm month^{-1})');

legend({'Flores','Sumba','Timor'}, ...
    'Location','southeast', ...
    'Box','off');

grid on;
box on;

set(ax4, ...
    'FontName',font_name, ...
    'FontSize',font_size, ...
    'LineWidth',0.8, ...
    'Layer','top');

hold(ax4,'off');


%% =========================================================
% 11. FINAL FIGURE SETTINGS
%% =========================================================

set(gcf,'Color','w');

drawnow;


%% =========================================================
% 12. SAVE FIGURE
%% =========================================================

exportgraphics( ...
    fig, ...
    'Figure2_Regional_Climatology_Deseasonalized.png', ...
    'Resolution',600);

exportgraphics( ...
    fig, ...
    'Figure2_Regional_Climatology_Deseasonalized.pdf', ...
    'ContentType','vector');

fprintf('\n=========================================\n');
fprintf('FIGURE 2 SAVED\n');
fprintf('=========================================\n');

fprintf('PNG : Figure2_Regional_Climatology_Deseasonalized.png\n');
fprintf('PDF : Figure2_Regional_Climatology_Deseasonalized.pdf\n');