%% =========================================================
% 03_Seasonal_Correlation.m
%
% SEASONAL SST-RAINFALL CORRELATION
% Using deseasonalized monthly anomalies
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Seasons:
%   DJF = December-January-February
%   MAM = March-April-May
%   JJA = June-July-August
%   SON = September-October-November
%
% Period:
%   2016-2025
%
% IMPORTANT:
%   DJF is assigned to the year of January-February.
%
%   Example:
%   DJF 2017 = Dec 2016 + Jan 2017 + Feb 2017
%
% Expected seasonal samples:
%   DJF : 2017-2025 = 9
%   MAM : 2016-2025 = 10
%   JJA : 2016-2025 = 10
%   SON : 2016-2024 = 9
%
% Input:
%   ..\3-Timeseries\regional_timeseries_anomaly.mat
%
% Outputs:
%   seasonal_mean_anomalies.mat
%   seasonal_mean_anomalies.csv
%   seasonal_correlation_basic.mat
%   seasonal_correlation_basic.csv
%
% NOTE:
%   This is BASIC Pearson correlation only.
%   CI, permutation, LOYO and FDR will be done next.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD MONTHLY DESEASONALIZED ANOMALIES
%% =========================================================

load('..\3-Timeseries\regional_timeseries_anomaly.mat',...
    'time',...
    'anom_sst_flores',...
    'anom_sst_sumba',...
    'anom_sst_timor',...
    'anom_prec_flores',...
    'anom_prec_sumba',...
    'anom_prec_timor');


fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL CORRELATION ANALYSIS\n')
fprintf('=========================================================\n')

fprintf('Monthly period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));

fprintf('Number of monthly positions = %d\n',...
    length(time));


%% =========================================================
% 2. YEAR AND MONTH VECTORS
%% =========================================================

yr = year(time);
mo = month(time);


%% =========================================================
% 3. DEFINE SEASON YEARS
%% =========================================================

years_DJF = (2017:2025)';
years_MAM = (2016:2025)';
years_JJA = (2016:2025)';
years_SON = (2016:2024)';


nDJF = length(years_DJF);
nMAM = length(years_MAM);
nJJA = length(years_JJA);
nSON = length(years_SON);


fprintf('\nExpected seasonal samples:\n')
fprintf('DJF = %d seasons (%d-%d)\n',...
    nDJF,years_DJF(1),years_DJF(end));

fprintf('MAM = %d seasons (%d-%d)\n',...
    nMAM,years_MAM(1),years_MAM(end));

fprintf('JJA = %d seasons (%d-%d)\n',...
    nJJA,years_JJA(1),years_JJA(end));

fprintf('SON = %d seasons (%d-%d)\n',...
    nSON,years_SON(1),years_SON(end));


%% =========================================================
% 4. PREALLOCATE DJF
%% =========================================================

sstF_DJF  = NaN(nDJF,1);
sstS_DJF  = NaN(nDJF,1);
sstT_DJF  = NaN(nDJF,1);

precF_DJF = NaN(nDJF,1);
precS_DJF = NaN(nDJF,1);
precT_DJF = NaN(nDJF,1);


%% =========================================================
% 5. CALCULATE DJF SEASONAL MEANS
%
% DJF year Y =
% Dec of Y-1 + Jan of Y + Feb of Y
%
% All three months must be valid.
%% =========================================================

for i = 1:nDJF

    Y = years_DJF(i);

    idx = ...
        (yr == Y-1 & mo == 12) | ...
        (yr == Y   & mo == 1)  | ...
        (yr == Y   & mo == 2);


    %% Flores

    temp = anom_sst_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstF_DJF(i) = mean(temp);
    end


    temp = anom_prec_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        precF_DJF(i) = mean(temp);
    end


    %% Sumba

    temp = anom_sst_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstS_DJF(i) = mean(temp);
    end


    temp = anom_prec_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        precS_DJF(i) = mean(temp);
    end


    %% Timor

    temp = anom_sst_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstT_DJF(i) = mean(temp);
    end


    temp = anom_prec_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        precT_DJF(i) = mean(temp);
    end

end


%% =========================================================
% 6. PREALLOCATE MAM
%% =========================================================

sstF_MAM  = NaN(nMAM,1);
sstS_MAM  = NaN(nMAM,1);
sstT_MAM  = NaN(nMAM,1);

precF_MAM = NaN(nMAM,1);
precS_MAM = NaN(nMAM,1);
precT_MAM = NaN(nMAM,1);


%% =========================================================
% 7. CALCULATE MAM SEASONAL MEANS
%% =========================================================

for i = 1:nMAM

    Y = years_MAM(i);

    idx = ...
        yr == Y & ...
        ismember(mo,[3 4 5]);


    %% Flores

    temp = anom_sst_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstF_MAM(i) = mean(temp);
    end


    temp = anom_prec_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        precF_MAM(i) = mean(temp);
    end


    %% Sumba

    temp = anom_sst_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstS_MAM(i) = mean(temp);
    end


    temp = anom_prec_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        precS_MAM(i) = mean(temp);
    end


    %% Timor

    temp = anom_sst_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstT_MAM(i) = mean(temp);
    end


    temp = anom_prec_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        precT_MAM(i) = mean(temp);
    end

end


%% =========================================================
% 8. PREALLOCATE JJA
%% =========================================================

sstF_JJA  = NaN(nJJA,1);
sstS_JJA  = NaN(nJJA,1);
sstT_JJA  = NaN(nJJA,1);

precF_JJA = NaN(nJJA,1);
precS_JJA = NaN(nJJA,1);
precT_JJA = NaN(nJJA,1);


%% =========================================================
% 9. CALCULATE JJA SEASONAL MEANS
%% =========================================================

for i = 1:nJJA

    Y = years_JJA(i);

    idx = ...
        yr == Y & ...
        ismember(mo,[6 7 8]);


    %% Flores

    temp = anom_sst_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstF_JJA(i) = mean(temp);
    end


    temp = anom_prec_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        precF_JJA(i) = mean(temp);
    end


    %% Sumba

    temp = anom_sst_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstS_JJA(i) = mean(temp);
    end


    temp = anom_prec_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        precS_JJA(i) = mean(temp);
    end


    %% Timor

    temp = anom_sst_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstT_JJA(i) = mean(temp);
    end


    temp = anom_prec_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        precT_JJA(i) = mean(temp);
    end

end


%% =========================================================
% 10. PREALLOCATE SON
%% =========================================================

sstF_SON  = NaN(nSON,1);
sstS_SON  = NaN(nSON,1);
sstT_SON  = NaN(nSON,1);

precF_SON = NaN(nSON,1);
precS_SON = NaN(nSON,1);
precT_SON = NaN(nSON,1);


%% =========================================================
% 11. CALCULATE SON SEASONAL MEANS
%
% SON 2025 is intentionally excluded because
% Oct-Nov 2025 SST files are missing.
%% =========================================================

for i = 1:nSON

    Y = years_SON(i);

    idx = ...
        yr == Y & ...
        ismember(mo,[9 10 11]);


    %% Flores

    temp = anom_sst_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstF_SON(i) = mean(temp);
    end


    temp = anom_prec_flores(idx);

    if length(temp)==3 && all(~isnan(temp))
        precF_SON(i) = mean(temp);
    end


    %% Sumba

    temp = anom_sst_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstS_SON(i) = mean(temp);
    end


    temp = anom_prec_sumba(idx);

    if length(temp)==3 && all(~isnan(temp))
        precS_SON(i) = mean(temp);
    end


    %% Timor

    temp = anom_sst_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        sstT_SON(i) = mean(temp);
    end


    temp = anom_prec_timor(idx);

    if length(temp)==3 && all(~isnan(temp))
        precT_SON(i) = mean(temp);
    end

end


%% =========================================================
% 12. QC: VALID SEASONAL MEANS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID SEASONAL MEANS\n')
fprintf('=========================================================\n')

fprintf('\nSeason     Flores     Sumba      Timor\n')
fprintf('--------------------------------------\n')

fprintf('DJF SST      %2d         %2d         %2d\n',...
    sum(~isnan(sstF_DJF)),...
    sum(~isnan(sstS_DJF)),...
    sum(~isnan(sstT_DJF)));

fprintf('DJF Rain     %2d         %2d         %2d\n',...
    sum(~isnan(precF_DJF)),...
    sum(~isnan(precS_DJF)),...
    sum(~isnan(precT_DJF)));


fprintf('MAM SST      %2d         %2d         %2d\n',...
    sum(~isnan(sstF_MAM)),...
    sum(~isnan(sstS_MAM)),...
    sum(~isnan(sstT_MAM)));

fprintf('MAM Rain     %2d         %2d         %2d\n',...
    sum(~isnan(precF_MAM)),...
    sum(~isnan(precS_MAM)),...
    sum(~isnan(precT_MAM)));


fprintf('JJA SST      %2d         %2d         %2d\n',...
    sum(~isnan(sstF_JJA)),...
    sum(~isnan(sstS_JJA)),...
    sum(~isnan(sstT_JJA)));

fprintf('JJA Rain     %2d         %2d         %2d\n',...
    sum(~isnan(precF_JJA)),...
    sum(~isnan(precS_JJA)),...
    sum(~isnan(precT_JJA)));


fprintf('SON SST      %2d         %2d         %2d\n',...
    sum(~isnan(sstF_SON)),...
    sum(~isnan(sstS_SON)),...
    sum(~isnan(sstT_SON)));

fprintf('SON Rain     %2d         %2d         %2d\n',...
    sum(~isnan(precF_SON)),...
    sum(~isnan(precS_SON)),...
    sum(~isnan(precT_SON)));


%% =========================================================
% 13. BASIC PEARSON CORRELATIONS
%% =========================================================

% -----------------------
% DJF
% -----------------------

valid = ~isnan(sstF_DJF) & ~isnan(precF_DJF);
n_F_DJF = sum(valid);
[r_F_DJF,p_F_DJF] = corr(...
    sstF_DJF(valid),...
    precF_DJF(valid),...
    'Type','Pearson');


valid = ~isnan(sstS_DJF) & ~isnan(precS_DJF);
n_S_DJF = sum(valid);
[r_S_DJF,p_S_DJF] = corr(...
    sstS_DJF(valid),...
    precS_DJF(valid),...
    'Type','Pearson');


valid = ~isnan(sstT_DJF) & ~isnan(precT_DJF);
n_T_DJF = sum(valid);
[r_T_DJF,p_T_DJF] = corr(...
    sstT_DJF(valid),...
    precT_DJF(valid),...
    'Type','Pearson');


% -----------------------
% MAM
% -----------------------

valid = ~isnan(sstF_MAM) & ~isnan(precF_MAM);
n_F_MAM = sum(valid);
[r_F_MAM,p_F_MAM] = corr(...
    sstF_MAM(valid),...
    precF_MAM(valid),...
    'Type','Pearson');


valid = ~isnan(sstS_MAM) & ~isnan(precS_MAM);
n_S_MAM = sum(valid);
[r_S_MAM,p_S_MAM] = corr(...
    sstS_MAM(valid),...
    precS_MAM(valid),...
    'Type','Pearson');


valid = ~isnan(sstT_MAM) & ~isnan(precT_MAM);
n_T_MAM = sum(valid);
[r_T_MAM,p_T_MAM] = corr(...
    sstT_MAM(valid),...
    precT_MAM(valid),...
    'Type','Pearson');


% -----------------------
% JJA
% -----------------------

valid = ~isnan(sstF_JJA) & ~isnan(precF_JJA);
n_F_JJA = sum(valid);
[r_F_JJA,p_F_JJA] = corr(...
    sstF_JJA(valid),...
    precF_JJA(valid),...
    'Type','Pearson');


valid = ~isnan(sstS_JJA) & ~isnan(precS_JJA);
n_S_JJA = sum(valid);
[r_S_JJA,p_S_JJA] = corr(...
    sstS_JJA(valid),...
    precS_JJA(valid),...
    'Type','Pearson');


valid = ~isnan(sstT_JJA) & ~isnan(precT_JJA);
n_T_JJA = sum(valid);
[r_T_JJA,p_T_JJA] = corr(...
    sstT_JJA(valid),...
    precT_JJA(valid),...
    'Type','Pearson');


% -----------------------
% SON
% -----------------------

valid = ~isnan(sstF_SON) & ~isnan(precF_SON);
n_F_SON = sum(valid);
[r_F_SON,p_F_SON] = corr(...
    sstF_SON(valid),...
    precF_SON(valid),...
    'Type','Pearson');


valid = ~isnan(sstS_SON) & ~isnan(precS_SON);
n_S_SON = sum(valid);
[r_S_SON,p_S_SON] = corr(...
    sstS_SON(valid),...
    precS_SON(valid),...
    'Type','Pearson');


valid = ~isnan(sstT_SON) & ~isnan(precT_SON);
n_T_SON = sum(valid);
[r_T_SON,p_T_SON] = corr(...
    sstT_SON(valid),...
    precT_SON(valid),...
    'Type','Pearson');


%% =========================================================
% 14. DISPLAY SEASONAL CORRELATION RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('BASIC SEASONAL PEARSON CORRELATIONS\n')
fprintf('=========================================================\n')

fprintf('\n')
fprintf('Region     Season       r          p        n\n')
fprintf('------------------------------------------------\n')

fprintf('Flores     DJF       %+0.4f     %.4f      %d\n',...
    r_F_DJF,p_F_DJF,n_F_DJF);

fprintf('Flores     MAM       %+0.4f     %.4f      %d\n',...
    r_F_MAM,p_F_MAM,n_F_MAM);

fprintf('Flores     JJA       %+0.4f     %.4f      %d\n',...
    r_F_JJA,p_F_JJA,n_F_JJA);

fprintf('Flores     SON       %+0.4f     %.4f      %d\n',...
    r_F_SON,p_F_SON,n_F_SON);


fprintf('\n')

fprintf('Sumba      DJF       %+0.4f     %.4f      %d\n',...
    r_S_DJF,p_S_DJF,n_S_DJF);

fprintf('Sumba      MAM       %+0.4f     %.4f      %d\n',...
    r_S_MAM,p_S_MAM,n_S_MAM);

fprintf('Sumba      JJA       %+0.4f     %.4f      %d\n',...
    r_S_JJA,p_S_JJA,n_S_JJA);

fprintf('Sumba      SON       %+0.4f     %.4f      %d\n',...
    r_S_SON,p_S_SON,n_S_SON);


fprintf('\n')

fprintf('Timor      DJF       %+0.4f     %.4f      %d\n',...
    r_T_DJF,p_T_DJF,n_T_DJF);

fprintf('Timor      MAM       %+0.4f     %.4f      %d\n',...
    r_T_MAM,p_T_MAM,n_T_MAM);

fprintf('Timor      JJA       %+0.4f     %.4f      %d\n',...
    r_T_JJA,p_T_JJA,n_T_JJA);

fprintf('Timor      SON       %+0.4f     %.4f      %d\n',...
    r_T_SON,p_T_SON,n_T_SON);


%% =========================================================
% 15. BUILD SEASONAL CORRELATION TABLE
%% =========================================================

Region = {...
    'Flores';'Flores';'Flores';'Flores';...
    'Sumba'; 'Sumba'; 'Sumba'; 'Sumba';...
    'Timor'; 'Timor'; 'Timor'; 'Timor'};


Season = {...
    'DJF';'MAM';'JJA';'SON';...
    'DJF';'MAM';'JJA';'SON';...
    'DJF';'MAM';'JJA';'SON'};


Pearson_r = [...
    r_F_DJF;...
    r_F_MAM;...
    r_F_JJA;...
    r_F_SON;...
    r_S_DJF;...
    r_S_MAM;...
    r_S_JJA;...
    r_S_SON;...
    r_T_DJF;...
    r_T_MAM;...
    r_T_JJA;...
    r_T_SON];


p_value = [...
    p_F_DJF;...
    p_F_MAM;...
    p_F_JJA;...
    p_F_SON;...
    p_S_DJF;...
    p_S_MAM;...
    p_S_JJA;...
    p_S_SON;...
    p_T_DJF;...
    p_T_MAM;...
    p_T_JJA;...
    p_T_SON];


N = [...
    n_F_DJF;...
    n_F_MAM;...
    n_F_JJA;...
    n_F_SON;...
    n_S_DJF;...
    n_S_MAM;...
    n_S_JJA;...
    n_S_SON;...
    n_T_DJF;...
    n_T_MAM;...
    n_T_JJA;...
    n_T_SON];


CorrelationTable = table(...
    Region,...
    Season,...
    Pearson_r,...
    p_value,...
    N);


%% =========================================================
% 16. DISPLAY TABLE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL CORRELATION TABLE\n')
fprintf('=========================================================\n')

disp(CorrelationTable)


%% =========================================================
% 17. CREATE LONG TABLE OF SEASONAL MEANS
%
% Useful for QC and later robustness analysis.
%% =========================================================

SeasonYear = [...
    years_DJF; years_DJF; years_DJF;...
    years_MAM; years_MAM; years_MAM;...
    years_JJA; years_JJA; years_JJA;...
    years_SON; years_SON; years_SON];


RegionSeason = [...
    repmat({'Flores'},nDJF,1);...
    repmat({'Sumba'}, nDJF,1);...
    repmat({'Timor'}, nDJF,1);...
    repmat({'Flores'},nMAM,1);...
    repmat({'Sumba'}, nMAM,1);...
    repmat({'Timor'}, nMAM,1);...
    repmat({'Flores'},nJJA,1);...
    repmat({'Sumba'}, nJJA,1);...
    repmat({'Timor'}, nJJA,1);...
    repmat({'Flores'},nSON,1);...
    repmat({'Sumba'}, nSON,1);...
    repmat({'Timor'}, nSON,1)];


SeasonName = [...
    repmat({'DJF'},3*nDJF,1);...
    repmat({'MAM'},3*nMAM,1);...
    repmat({'JJA'},3*nJJA,1);...
    repmat({'SON'},3*nSON,1)];


SST_Anomaly = [...
    sstF_DJF;...
    sstS_DJF;...
    sstT_DJF;...
    sstF_MAM;...
    sstS_MAM;...
    sstT_MAM;...
    sstF_JJA;...
    sstS_JJA;...
    sstT_JJA;...
    sstF_SON;...
    sstS_SON;...
    sstT_SON];


Rainfall_Anomaly = [...
    precF_DJF;...
    precS_DJF;...
    precT_DJF;...
    precF_MAM;...
    precS_MAM;...
    precT_MAM;...
    precF_JJA;...
    precS_JJA;...
    precT_JJA;...
    precF_SON;...
    precS_SON;...
    precT_SON];


SeasonalMeanTable = table(...
    SeasonYear,...
    SeasonName,...
    RegionSeason,...
    SST_Anomaly,...
    Rainfall_Anomaly,...
    'VariableNames',{...
    'Year',...
    'Season',...
    'Region',...
    'SST_anomaly_C',...
    'Rainfall_anomaly_mm_month'});


%% =========================================================
% 18. SAVE MAT FILES
%% =========================================================

save(...
    'seasonal_mean_anomalies.mat',...
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
    'precF_SON','precS_SON','precT_SON',...
    'SeasonalMeanTable');


save(...
    'seasonal_correlation_basic.mat',...
    'CorrelationTable',...
    'r_F_DJF','p_F_DJF','n_F_DJF',...
    'r_F_MAM','p_F_MAM','n_F_MAM',...
    'r_F_JJA','p_F_JJA','n_F_JJA',...
    'r_F_SON','p_F_SON','n_F_SON',...
    'r_S_DJF','p_S_DJF','n_S_DJF',...
    'r_S_MAM','p_S_MAM','n_S_MAM',...
    'r_S_JJA','p_S_JJA','n_S_JJA',...
    'r_S_SON','p_S_SON','n_S_SON',...
    'r_T_DJF','p_T_DJF','n_T_DJF',...
    'r_T_MAM','p_T_MAM','n_T_MAM',...
    'r_T_JJA','p_T_JJA','n_T_JJA',...
    'r_T_SON','p_T_SON','n_T_SON');


%% =========================================================
% 19. SAVE CSV FILES
%% =========================================================

writetable(...
    SeasonalMeanTable,...
    'seasonal_mean_anomalies.csv');


writetable(...
    CorrelationTable,...
    'seasonal_correlation_basic.csv');


%% =========================================================
% 20. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL CORRELATION ANALYSIS COMPLETED\n')
fprintf('=========================================================\n')

fprintf('\nFiles saved:\n')

fprintf('1. seasonal_mean_anomalies.mat\n')
fprintf('2. seasonal_mean_anomalies.csv\n')
fprintf('3. seasonal_correlation_basic.mat\n')
fprintf('4. seasonal_correlation_basic.csv\n')


fprintf('\nIMPORTANT:\n')

fprintf(['These are basic Pearson correlations using seasonal ',...
         'mean deseasonalized anomalies.\n']);

fprintf(['Because seasonal sample sizes are only 9-10 years, ',...
         'ordinary p-values are NOT sufficient for the final manuscript.\n']);

fprintf(['The next step will evaluate confidence intervals, ',...
         'permutation significance, leave-one-year-out stability, ',...
         'and FDR correction.\n']);