%% =========================================================
% 03_Regional_Monthly_Climatology.m
%
% REGIONAL MONTHLY CLIMATOLOGY
% Flores - Sumba - Timor
%
% Period : 2016-2025
%
% Input:
%   regional_timeseries_raw.mat
%
% Units:
%   SST      = degree C
%   Rainfall = mm/month
%
% Output:
%   regional_monthly_climatology.mat
%   regional_monthly_climatology.csv
%   Regional_Monthly_Climatology.png
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
% 2. MONTH INFORMATION
%% =========================================================

month_num = (1:12)';

month_name = {...
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


%% =========================================================
% 3. PREALLOCATE MONTHLY CLIMATOLOGY
%% =========================================================

% SST
clim_sst_flores = NaN(12,1);
clim_sst_sumba  = NaN(12,1);
clim_sst_timor  = NaN(12,1);

% Rainfall
clim_prec_flores = NaN(12,1);
clim_prec_sumba  = NaN(12,1);
clim_prec_timor  = NaN(12,1);


%% =========================================================
% 4. NUMBER OF VALID YEARS PER MONTH
%% =========================================================

n_sst_flores = NaN(12,1);
n_sst_sumba  = NaN(12,1);
n_sst_timor  = NaN(12,1);

n_prec_flores = NaN(12,1);
n_prec_sumba  = NaN(12,1);
n_prec_timor  = NaN(12,1);


%% =========================================================
% 5. CALCULATE MONTHLY CLIMATOLOGY
%
% Example:
%
% January climatology =
% mean(all January values from 2016-2025)
%
% February climatology =
% mean(all February values from 2016-2025)
%
% etc.
%% =========================================================

for m = 1:12

    idx = month(time) == m;


    %% -----------------------------------------------------
    % SST
    %% -----------------------------------------------------

    data = sst_flores(idx);

    clim_sst_flores(m) = ...
        mean(data,'omitnan');

    n_sst_flores(m) = ...
        sum(~isnan(data));


    data = sst_sumba(idx);

    clim_sst_sumba(m) = ...
        mean(data,'omitnan');

    n_sst_sumba(m) = ...
        sum(~isnan(data));


    data = sst_timor(idx);

    clim_sst_timor(m) = ...
        mean(data,'omitnan');

    n_sst_timor(m) = ...
        sum(~isnan(data));


    %% -----------------------------------------------------
    % RAINFALL
    %% -----------------------------------------------------

    data = prec_flores(idx);

    clim_prec_flores(m) = ...
        mean(data,'omitnan');

    n_prec_flores(m) = ...
        sum(~isnan(data));


    data = prec_sumba(idx);

    clim_prec_sumba(m) = ...
        mean(data,'omitnan');

    n_prec_sumba(m) = ...
        sum(~isnan(data));


    data = prec_timor(idx);

    clim_prec_timor(m) = ...
        mean(data,'omitnan');

    n_prec_timor(m) = ...
        sum(~isnan(data));

end


%% =========================================================
% 6. DISPLAY SST MONTHLY CLIMATOLOGY
%% =========================================================

fprintf('\n')
fprintf('============================================================\n')
fprintf('REGIONAL MONTHLY SST CLIMATOLOGY\n')
fprintf('Unit = degree C\n')
fprintf('============================================================\n')

fprintf('\n')
fprintf('Month     Flores     Sumba      Timor     n(F/S/T)\n')
fprintf('------------------------------------------------------------\n')

for m = 1:12

    fprintf('%-4s      %6.2f     %6.2f     %6.2f     %d/%d/%d\n',...
        month_name{m},...
        clim_sst_flores(m),...
        clim_sst_sumba(m),...
        clim_sst_timor(m),...
        n_sst_flores(m),...
        n_sst_sumba(m),...
        n_sst_timor(m));

end


%% =========================================================
% 7. DISPLAY RAINFALL MONTHLY CLIMATOLOGY
%% =========================================================

fprintf('\n')
fprintf('============================================================\n')
fprintf('REGIONAL MONTHLY RAINFALL CLIMATOLOGY\n')
fprintf('Unit = mm/month\n')
fprintf('============================================================\n')

fprintf('\n')
fprintf('Month     Flores     Sumba      Timor     n(F/S/T)\n')
fprintf('------------------------------------------------------------\n')

for m = 1:12

    fprintf('%-4s      %7.1f    %7.1f    %7.1f     %d/%d/%d\n',...
        month_name{m},...
        clim_prec_flores(m),...
        clim_prec_sumba(m),...
        clim_prec_timor(m),...
        n_prec_flores(m),...
        n_prec_sumba(m),...
        n_prec_timor(m));

end


%% =========================================================
% 8. CHECK OCTOBER-NOVEMBER SST SAMPLE SIZE
%% =========================================================

fprintf('\n')
fprintf('============================================================\n')
fprintf('MISSING SST CHECK\n')
fprintf('============================================================\n')

fprintf('October SST valid years  : %d / 10\n',...
    n_sst_flores(10));

fprintf('November SST valid years : %d / 10\n',...
    n_sst_flores(11));

fprintf('\nExpected: 9 / 10 because Oct-Nov 2025 are missing.\n');


%% =========================================================
% 9. CREATE TABLE
%% =========================================================

ClimatologyTable = table(...
    month_num,...
    month_name,...
    clim_sst_flores,...
    clim_sst_sumba,...
    clim_sst_timor,...
    clim_prec_flores,...
    clim_prec_sumba,...
    clim_prec_timor,...
    n_sst_flores,...
    n_sst_sumba,...
    n_sst_timor,...
    n_prec_flores,...
    n_prec_sumba,...
    n_prec_timor,...
    'VariableNames',{...
    'MonthNumber',...
    'Month',...
    'SST_Flores_C',...
    'SST_Sumba_C',...
    'SST_Timor_C',...
    'Rain_Flores_mm_month',...
    'Rain_Sumba_mm_month',...
    'Rain_Timor_mm_month',...
    'N_SST_Flores',...
    'N_SST_Sumba',...
    'N_SST_Timor',...
    'N_Rain_Flores',...
    'N_Rain_Sumba',...
    'N_Rain_Timor'});


%% =========================================================
% 10. SAVE DATA
%% =========================================================

save('regional_monthly_climatology.mat',...
    'month_num',...
    'month_name',...
    'clim_sst_flores',...
    'clim_sst_sumba',...
    'clim_sst_timor',...
    'clim_prec_flores',...
    'clim_prec_sumba',...
    'clim_prec_timor',...
    'n_sst_flores',...
    'n_sst_sumba',...
    'n_sst_timor',...
    'n_prec_flores',...
    'n_prec_sumba',...
    'n_prec_timor');


writetable(...
    ClimatologyTable,...
    'regional_monthly_climatology.csv');


%% =========================================================
% 11. PLOT
%% =========================================================

figure(1)

set(gcf,...
    'Color','w',...
    'Position',[100 80 1100 750]);


tiledlayout(2,1,...
    'TileSpacing','compact',...
    'Padding','compact');


%% =========================================================
% PANEL A - SST MONTHLY CLIMATOLOGY
%% =========================================================

nexttile

plot(month_num,...
    clim_sst_flores,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);

hold on

plot(month_num,...
    clim_sst_sumba,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);

plot(month_num,...
    clim_sst_timor,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);


xlim([1 12])

xticks(1:12)
xticklabels(month_name)

ylabel('SST (^{\circ}C)')

grid on
box on

legend(...
    {'Flores','Sumba','Timor'},...
    'Location','best',...
    'Box','off');

set(gca,...
    'FontSize',11,...
    'LineWidth',1);


text(0.01,0.94,'(a)',...
    'Units','normalized',...
    'FontSize',13,...
    'FontWeight','bold');


%% =========================================================
% PANEL B - RAINFALL MONTHLY CLIMATOLOGY
%% =========================================================

nexttile

plot(month_num,...
    clim_prec_flores,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);

hold on

plot(month_num,...
    clim_prec_sumba,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);

plot(month_num,...
    clim_prec_timor,...
    '-o',...
    'LineWidth',1.8,...
    'MarkerSize',5);


xlim([1 12])

xticks(1:12)
xticklabels(month_name)

ylabel('Rainfall (mm month^{-1})')
xlabel('Month')

ylim([0 inf])

grid on
box on

legend(...
    {'Flores','Sumba','Timor'},...
    'Location','best',...
    'Box','off');

set(gca,...
    'FontSize',11,...
    'LineWidth',1);


text(0.01,0.94,'(b)',...
    'Units','normalized',...
    'FontSize',13,...
    'FontWeight','bold');


%% =========================================================
% 12. SAVE FIGURE
%% =========================================================

drawnow

exportgraphics(...
    gcf,...
    'Regional_Monthly_Climatology.png',...
    'Resolution',300);


%% =========================================================
% 13. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('============================================================\n')
fprintf('REGIONAL MONTHLY CLIMATOLOGY COMPLETED\n')
fprintf('============================================================\n')

fprintf('\nFiles saved:\n')
fprintf('1. regional_monthly_climatology.mat\n')
fprintf('2. regional_monthly_climatology.csv\n')
fprintf('3. Regional_Monthly_Climatology.png\n')

fprintf('\nUnits:\n')
fprintf('SST      = degree C\n')
fprintf('Rainfall = mm/month\n')