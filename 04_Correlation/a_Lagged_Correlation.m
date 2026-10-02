%% =========================================================
% 06_Lagged_Correlation.m
%
% LAGGED MONTHLY SST-RAINFALL CORRELATION
% Using deseasonalized monthly anomalies
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% Lags:
%   -6 to +6 months
%
% CONVENTION:
%
%   Lag  0 :
%       SST(t) vs Rain(t)
%
%   Lag +k :
%       SST(t) vs Rain(t+k)
%       SST leads rainfall by k months
%
%   Lag -k :
%       SST(t+k) vs Rain(t)
%       rainfall leads SST by k months
%
% Analyses:
%   1. Pearson correlation
%   2. Raw p-value
%   3. Lag-1 autocorrelation
%   4. Effective sample size (Neff)
%   5. Autocorrelation-adjusted p-value
%   6. BH-FDR across ALL 39 tests
%      (3 regions x 13 lags)
%   7. Secondary BH-FDR across lag 0:+6 only
%      (3 regions x 7 lags = 21 tests)
%
% Input:
%   ..\3-Timeseries\regional_timeseries_anomaly.mat
%
% Output:
%   lagged_correlation_results.mat
%   lagged_correlation_results.csv
%
% IMPORTANT:
%   Missing SST data are retained as NaN.
%   No interpolation is performed.
%
%   Lagged correlation describes temporal association,
%   NOT causality.
%
% No local functions are used.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. LOAD DESEASONALIZED MONTHLY ANOMALIES
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
fprintf('LAGGED MONTHLY SST-RAINFALL CORRELATION\n')
fprintf('=========================================================\n')

fprintf('Period = %s to %s\n',...
    datestr(time(1),'mmm-yyyy'),...
    datestr(time(end),'mmm-yyyy'));

fprintf('Total monthly positions = %d\n',...
    length(time));


%% =========================================================
% 2. DEFINE LAGS
%% =========================================================

lags = (-6:6)';

nLag = length(lags);

fprintf('\nLag range = %d to %+d months\n',...
    lags(1),...
    lags(end));

fprintf('Number of lags = %d\n',...
    nLag);


%% =========================================================
% 3. DEFINE REGIONS
%% =========================================================

regions = {...
    'Flores';...
    'Sumba';...
    'Timor'};


sst_all = {...
    anom_sst_flores;...
    anom_sst_sumba;...
    anom_sst_timor};


rain_all = {...
    anom_prec_flores;...
    anom_prec_sumba;...
    anom_prec_timor};


nRegion = length(regions);


%% =========================================================
% 4. PREALLOCATE RESULTS
%
% Total tests:
% 3 regions x 13 lags = 39
%% =========================================================

Ntest = nRegion * nLag;


Region = cell(Ntest,1);

Lag_month = NaN(Ntest,1);

Direction = cell(Ntest,1);

N = NaN(Ntest,1);

Pearson_r = NaN(Ntest,1);

p_raw = NaN(Ntest,1);

SST_lag1 = NaN(Ntest,1);

Rain_lag1 = NaN(Ntest,1);

N_effective = NaN(Ntest,1);

p_autocorr = NaN(Ntest,1);


%% =========================================================
% 5. LOOP THROUGH REGIONS AND LAGS
%% =========================================================

row = 0;


for iRegion = 1:nRegion

    sst = sst_all{iRegion};
    rain = rain_all{iRegion};


    % Ensure column vectors
    sst = sst(:);
    rain = rain(:);


    for iLag = 1:nLag

        row = row + 1;

        L = lags(iLag);


        %% -------------------------------------------------
        % Store identifiers
        %% -------------------------------------------------

        Region{row} = regions{iRegion};

        Lag_month(row) = L;


        if L > 0

            Direction{row} = 'SST leads rainfall';

        elseif L < 0

            Direction{row} = 'Rainfall leads SST';

        else

            Direction{row} = 'Concurrent';

        end


        %% =================================================
        % 5A. ALIGN SST AND RAINFALL
        %% =================================================

        if L > 0

            % ---------------------------------------------
            % Positive lag:
            %
            % SST(t) vs Rain(t+L)
            %
            % Example L = +3:
            % SST Jan vs Rain Apr
            % ---------------------------------------------

            x_raw = sst(1:end-L);

            y_raw = rain(1+L:end);


        elseif L < 0

            % ---------------------------------------------
            % Negative lag:
            %
            % Rainfall leads SST
            %
            % Example L = -3:
            % SST Apr vs Rain Jan
            % ---------------------------------------------

            K = abs(L);

            x_raw = sst(1+K:end);

            y_raw = rain(1:end-K);


        else

            % ---------------------------------------------
            % Zero lag
            % ---------------------------------------------

            x_raw = sst;

            y_raw = rain;

        end


        %% =================================================
        % 5B. PAIRWISE VALID DATA
        %% =================================================

        valid_pair = ...
            ~isnan(x_raw) & ...
            ~isnan(y_raw);


        x = x_raw(valid_pair);

        y = y_raw(valid_pair);


        n = length(x);

        N(row) = n;


        %% =================================================
        % 5C. PEARSON CORRELATION
        %% =================================================

        [r_obs,p_obs] = corr(...
            x,...
            y,...
            'Type','Pearson');


        Pearson_r(row) = r_obs;

        p_raw(row) = p_obs;


        %% =================================================
        % 5D. LAG-1 AUTOCORRELATION OF ALIGNED SST
        %
        % IMPORTANT:
        % Use the uncompressed aligned vector x_raw.
        %
        % This prevents bridging across missing months.
        %% =================================================

        x1 = x_raw(1:end-1);
        x2 = x_raw(2:end);


        valid_x1 = ...
            ~isnan(x1) & ...
            ~isnan(x2);


        if sum(valid_x1) >= 3

            r1_x = corr(...
                x1(valid_x1),...
                x2(valid_x1),...
                'Type','Pearson');

        else

            r1_x = NaN;

        end


        SST_lag1(row) = r1_x;


        %% =================================================
        % 5E. LAG-1 AUTOCORRELATION OF ALIGNED RAINFALL
        %% =================================================

        y1 = y_raw(1:end-1);
        y2 = y_raw(2:end);


        valid_y1 = ...
            ~isnan(y1) & ...
            ~isnan(y2);


        if sum(valid_y1) >= 3

            r1_y = corr(...
                y1(valid_y1),...
                y2(valid_y1),...
                'Type','Pearson');

        else

            r1_y = NaN;

        end


        Rain_lag1(row) = r1_y;


        %% =================================================
        % 5F. EFFECTIVE SAMPLE SIZE
        %
        % Neff =
        %
        % N * (1-r1x*r1y)/(1+r1x*r1y)
        %% =================================================

        if ~isnan(r1_x) && ~isnan(r1_y)

            Neff = ...
                n * ...
                (1-r1_x*r1_y) / ...
                (1+r1_x*r1_y);

        else

            Neff = n;

        end


        % Conservative limits

        Neff = min(Neff,n);

        Neff = max(Neff,3);


        N_effective(row) = Neff;


        %% =================================================
        % 5G. AUTOCORRELATION-ADJUSTED P-VALUE
        %% =================================================

        df = Neff - 2;


        t_stat = ...
            r_obs * ...
            sqrt(df / (1-r_obs^2));


        p_adj = ...
            2 * ...
            (1 - tcdf(abs(t_stat),df));


        p_autocorr(row) = p_adj;


    end

end


%% =========================================================
% 6. BH-FDR ACROSS ALL 39 TESTS
%
% PRIMARY multiple-testing family
%% =========================================================

m_all = Ntest;


[p_sort,idx_sort] = ...
    sort(p_autocorr);


q_sort = ...
    p_sort .* m_all ./ (1:m_all)';


% Enforce monotonicity

for i = m_all-1:-1:1

    q_sort(i) = ...
        min(q_sort(i),q_sort(i+1));

end


q_sort = min(q_sort,1);


q_FDR_all = NaN(Ntest,1);

q_FDR_all(idx_sort) = q_sort;


%% =========================================================
% 7. SECONDARY BH-FDR FOR NON-NEGATIVE LAGS
%
% Lag 0:+6 only
%
% This is saved separately and should be interpreted as
% a directional SST-leading-rainfall sensitivity analysis.
%% =========================================================

idx_nonnegative = ...
    Lag_month >= 0;


p_nonnegative = ...
    p_autocorr(idx_nonnegative);


m_pos = length(p_nonnegative);


[p_sort_pos,idx_sort_pos] = ...
    sort(p_nonnegative);


q_sort_pos = ...
    p_sort_pos .* m_pos ./ (1:m_pos)';


for i = m_pos-1:-1:1

    q_sort_pos(i) = ...
        min(q_sort_pos(i),q_sort_pos(i+1));

end


q_sort_pos = ...
    min(q_sort_pos,1);


q_pos_temp = NaN(m_pos,1);

q_pos_temp(idx_sort_pos) = ...
    q_sort_pos;


q_FDR_nonnegative = ...
    NaN(Ntest,1);


q_FDR_nonnegative(idx_nonnegative) = ...
    q_pos_temp;


%% =========================================================
% 8. FDR STATUS
%
% Based on PRIMARY all-39 correction
%% =========================================================

FDR_status = cell(Ntest,1);


for k = 1:Ntest

    if q_FDR_all(k) < 0.05

        FDR_status{k} = 'q<0.05';

    elseif q_FDR_all(k) < 0.10

        FDR_status{k} = '0.05<=q<0.10';

    else

        FDR_status{k} = 'q>=0.10';

    end

end


%% =========================================================
% 9. CREATE RESULT TABLE
%% =========================================================

ResultTable = table(...
    Region,...
    Lag_month,...
    Direction,...
    N,...
    Pearson_r,...
    SST_lag1,...
    Rain_lag1,...
    N_effective,...
    p_raw,...
    p_autocorr,...
    q_FDR_all,...
    q_FDR_nonnegative,...
    FDR_status,...
    'VariableNames',{...
    'Region',...
    'Lag_month',...
    'Direction',...
    'N',...
    'Pearson_r',...
    'SST_lag1',...
    'Rain_lag1',...
    'N_effective',...
    'p_raw',...
    'p_autocorr_adjusted',...
    'q_FDR_all39',...
    'q_FDR_lag0_to_plus6',...
    'FDR_status_all39'});


%% =========================================================
% 10. DISPLAY ALL RESULTS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('LAGGED CORRELATION RESULTS\n')
fprintf('PRIMARY FDR FAMILY = ALL 39 TESTS\n')
fprintf('=========================================================\n')


for iRegion = 1:nRegion

    fprintf('\n%s\n',regions{iRegion});

    fprintf(['Lag       r        N       Neff      ',...
             'p_adj      q_all39\n']);

    fprintf('-------------------------------------------------------\n');


    idx_region = ...
        strcmp(Region,regions{iRegion});


    rows = find(idx_region);


    for j = 1:length(rows)

        k = rows(j);

        fprintf('%+3d    %+0.4f    %3d     %6.1f     %.4f     %.4f\n',...
            Lag_month(k),...
            Pearson_r(k),...
            N(k),...
            N_effective(k),...
            p_autocorr(k),...
            q_FDR_all(k));

    end

end


%% =========================================================
% 11. RESULTS RETAINED AT q < 0.05
%
% PRIMARY all-39 FDR
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('PRIMARY RESULTS RETAINED AFTER FDR (q < 0.05)\n')
fprintf('ALL 39 LAG TESTS\n')
fprintf('=========================================================\n')


idx_sig = ...
    q_FDR_all < 0.05;


if any(idx_sig)

    for k = 1:Ntest

        if idx_sig(k)

            fprintf(['%s lag %+d : r = %+0.4f | ',...
                     'p_adj = %.4f | q = %.4f\n'],...
                Region{k},...
                Lag_month(k),...
                Pearson_r(k),...
                p_autocorr(k),...
                q_FDR_all(k));

        end

    end

else

    fprintf('No lagged correlations retained at q < 0.05.\n');

end


%% =========================================================
% 12. RESULTS WITH 0.05 <= q < 0.10
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('PRIMARY RESULTS WITH 0.05 <= q < 0.10\n')
fprintf('ALL 39 LAG TESTS\n')
fprintf('=========================================================\n')


idx_q10 = ...
    q_FDR_all >= 0.05 & ...
    q_FDR_all < 0.10;


if any(idx_q10)

    for k = 1:Ntest

        if idx_q10(k)

            fprintf(['%s lag %+d : r = %+0.4f | ',...
                     'p_adj = %.4f | q = %.4f\n'],...
                Region{k},...
                Lag_month(k),...
                Pearson_r(k),...
                p_autocorr(k),...
                q_FDR_all(k));

        end

    end

else

    fprintf('No results in this q-value range.\n');

end


%% =========================================================
% 13. SECONDARY POSITIVE-LAG SUMMARY
%
% Lag 0:+6
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SECONDARY SST-LEADING-RAINFALL ANALYSIS\n')
fprintf('LAGS 0 TO +6 ONLY\n')
fprintf('=========================================================\n')


for iRegion = 1:nRegion

    fprintf('\n%s\n',regions{iRegion});

    fprintf('Lag       r       p_adj     q_0to+6\n');
    fprintf('-----------------------------------------\n');


    idx_region = ...
        strcmp(Region,regions{iRegion}) & ...
        Lag_month >= 0;


    rows = find(idx_region);


    for j = 1:length(rows)

        k = rows(j);

        fprintf('%+3d    %+0.4f    %.4f     %.4f\n',...
            Lag_month(k),...
            Pearson_r(k),...
            p_autocorr(k),...
            q_FDR_nonnegative(k));

    end

end


%% =========================================================
% 14. SAVE RESULTS
%% =========================================================

save(...
    'lagged_correlation_results.mat',...
    'ResultTable',...
    'lags',...
    'Region',...
    'Lag_month',...
    'Direction',...
    'N',...
    'Pearson_r',...
    'SST_lag1',...
    'Rain_lag1',...
    'N_effective',...
    'p_raw',...
    'p_autocorr',...
    'q_FDR_all',...
    'q_FDR_nonnegative',...
    'FDR_status');


writetable(...
    ResultTable,...
    'lagged_correlation_results.csv');


%% =========================================================
% 15. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('LAGGED CORRELATION ANALYSIS COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n')
fprintf('1. lagged_correlation_results.mat\n')
fprintf('2. lagged_correlation_results.csv\n')


fprintf('\nLag convention:\n')
fprintf('Positive lag = SST leads rainfall.\n')
fprintf('Negative lag = rainfall leads SST.\n')


fprintf('\nStatistical interpretation:\n')
fprintf(['Primary inference uses BH-FDR correction across ',...
         'all 39 tests (-6:+6 months x 3 regions).\n']);

fprintf(['The lag 0:+6 FDR is saved separately as a secondary ',...
         'directional SST-leading-rainfall analysis.\n']);


fprintf('\nIMPORTANT:\n')
fprintf(['Lagged correlation indicates temporal association ',...
         'and does NOT demonstrate causality.\n']);