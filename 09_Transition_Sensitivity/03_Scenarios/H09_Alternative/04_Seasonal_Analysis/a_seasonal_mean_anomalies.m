%% ========================================================================
% a_seasonal_mean_anomalies.m
% SEASONAL MEANS OF DESEASONALIZED SST AND RAINFALL | NTT 2016-2025
%
% MATLAB R2021a | Run this script from Data/04_Seasonal_Analysis/
% Input : ../02_Regional_Timeseries/regional_anomalies.mat
% Outputs (same folder):
%   seasonal_mean_anomalies.csv
%   seasonal_mean_anomalies.mat
%
% Definitions:
%   Deseasonalized monthly anomaly = value - study-period mean of the
%   SAME CALENDAR MONTH (2016-2025). NOT an overall-mean anomaly.
%   Seasonal value = arithmetic mean of three monthly anomalies.
%   All THREE months must be present; no interpolation or partial seasons.
%
% DJF year Y = December (Y-1) + January (Y) + February (Y).
% DJF: 2017-2025 (n=9); MAM: 2016-2025 (n=10);
% JJA: 2016-2025 (n=10); SON: 2016-2024 (n=9).
% SON 2025 is EXCLUDED because SST Oct-Nov 2025 is missing.
% All regional series are unweighted means of available spatial grids.
% Additional raw seasonal rainfall in mm/month is saved for interpretation.
%% ========================================================================
clc;
clear;

%% 1. Paths and inputs
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save this script as a_seasonal_mean_anomalies.m first.');
end
out_dir = fileparts(script_file);
data_root = fileparts(out_dir);
in_file = fullfile(data_root,'02_Regional_Timeseries','regional_anomalies.mat');
if ~isfile(in_file)
    error('Input missing: %s',in_file);
end
D = load(in_file);
req = {'time','SST','RAIN','SST_deseason','RAIN_deseason'};
for i = 1:numel(req)
    if ~isfield(D,req{i})
        error('Missing variable in input MAT: %s',req{i});
    end
end
if ~isdatetime(D.time) || numel(D.time)~=120 || ...
        ~isequal(size(D.SST),[120,3]) || ~isequal(size(D.RAIN),[120,3]) || ...
        ~isequal(size(D.SST_deseason),[120,3]) || ...
        ~isequal(size(D.RAIN_deseason),[120,3])
    error('Expected datetime time and four [120 x 3] data matrices.');
end
time = D.time(:);
expected_time = datetime(2016,1,1)+calmonths((0:119)');
if ~all(time == expected_time)
    error('Monthly time must span every month Jan-2016 to Dec-2025.');
end
if any(~isfinite(D.RAIN(:))) || any(~isfinite(D.RAIN_deseason(:)))
    error('Unexpected missing rainfall values.');
end
missing_octnov = (year(time)==2025 & ismember(month(time),[10,11]));
if ~all(all(isnan(D.SST(missing_octnov,:)))) || ...
        any(any(~isfinite(D.SST(~missing_octnov,:)))) || ...
        ~all(all(isnan(D.SST_deseason(missing_octnov,:))))
    error('Unexpected SST missing-value pattern.');
end

%% 2. Build complete seasonal means (three months per season)
regions = {'Flores','Sumba','Timor'};
season_names = {'DJF','MAM','JJA','SON'};
season_years = {(2017:2025)',(2016:2025)',(2016:2025)',(2016:2024)'};
YR = year(time);
MO = month(time);

Region = {};
Season = {};
Season_year = [];
N_months_SST = [];
N_months_Rain = [];
SST_mean_anom_C = [];
Rain_mean_anom_mm_month = [];
SST_raw_mean_C = [];
Rain_raw_mean_mm_month = [];
Seasonal = struct();

for is = 1:4
    ss = season_names{is};
    yy = season_years{is};
    nYear = numel(yy);
    sst_an = NaN(nYear,3);
    rain_an = NaN(nYear,3);
    sst_raw = NaN(nYear,3);
    rain_raw = NaN(nYear,3);
    nS = zeros(nYear,3);
    nR = zeros(nYear,3);

    for iy = 1:nYear
        y = yy(iy);
        switch ss
            case 'DJF'
                ix = (YR==y-1 & MO==12) | ...
                     (YR==y & (MO==1 | MO==2));
            case 'MAM'
                ix = YR==y & ismember(MO,[3 4 5]);
            case 'JJA'
                ix = YR==y & ismember(MO,[6 7 8]);
            case 'SON'
                ix = YR==y & ismember(MO,[9 10 11]);
        end
        if sum(ix) ~= 3
            error('Incorrect number of calendar months for %s %d.',ss,y);
        end
        for ir = 1:3
            xa = D.SST_deseason(ix,ir);
            ya = D.RAIN_deseason(ix,ir);
            xr = D.SST(ix,ir);
            yr = D.RAIN(ix,ir);
            nS(iy,ir) = sum(isfinite(xa));
            nR(iy,ir) = sum(isfinite(ya));
            if nS(iy,ir)==3 && all(isfinite(xr))
                sst_an(iy,ir) = mean(xa);
                sst_raw(iy,ir) = mean(xr);
            end
            if nR(iy,ir)==3 && all(isfinite(yr))
                rain_an(iy,ir) = mean(ya);
                rain_raw(iy,ir) = mean(yr);
            end
        end
    end

    if any(nS(:) ~= 3) || any(nR(:) ~= 3)
        error('Incomplete season detected in %s. Check missing months.',ss);
    end
    Seasonal.(ss).Year = yy;
    Seasonal.(ss).SST = sst_an;
    Seasonal.(ss).RAIN = rain_an;
    Seasonal.(ss).SST_raw = sst_raw;
    Seasonal.(ss).RAIN_raw = rain_raw;

    for ir = 1:3
        for iy = 1:nYear
            Region{end+1,1} = regions{ir}; %#ok<SAGROW>
            Season{end+1,1} = ss; %#ok<SAGROW>
            Season_year(end+1,1) = yy(iy); %#ok<SAGROW>
            N_months_SST(end+1,1) = nS(iy,ir); %#ok<SAGROW>
            N_months_Rain(end+1,1) = nR(iy,ir); %#ok<SAGROW>
            SST_mean_anom_C(end+1,1) = sst_an(iy,ir); %#ok<SAGROW>
            Rain_mean_anom_mm_month(end+1,1) = rain_an(iy,ir); %#ok<SAGROW>
            SST_raw_mean_C(end+1,1) = sst_raw(iy,ir); %#ok<SAGROW>
            Rain_raw_mean_mm_month(end+1,1) = rain_raw(iy,ir); %#ok<SAGROW>
        end
    end
end

%% 3. Save table and variables for future scripts
SeasonalTable = table(Region,Season,Season_year,N_months_SST, ...
    N_months_Rain,SST_mean_anom_C,Rain_mean_anom_mm_month, ...
    SST_raw_mean_C,Rain_raw_mean_mm_month);
writetable(SeasonalTable,fullfile(out_dir,'seasonal_mean_anomalies.csv'));

years_DJF = Seasonal.DJF.Year;
years_MAM = Seasonal.MAM.Year;
years_JJA = Seasonal.JJA.Year;
years_SON = Seasonal.SON.Year;
save(fullfile(out_dir,'seasonal_mean_anomalies.mat'), ...
    'Seasonal','SeasonalTable','regions','season_names', ...
    'years_DJF','years_MAM','years_JJA','years_SON');

% Named variables also saved for compatibility with earlier analysis scripts.
Compat = struct();
codes = {'F','S','T'};
for is = 1:4
    ss = season_names{is};
    for ir = 1:3
        Compat.(['sst' codes{ir} '_' ss]) = Seasonal.(ss).SST(:,ir);
        Compat.(['prec' codes{ir} '_' ss]) = Seasonal.(ss).RAIN(:,ir);
    end
end
save(fullfile(out_dir,'seasonal_mean_anomalies.mat'),'-struct','Compat','-append');

fprintf('\n===== SEASONAL MEAN ANOMALIES QC =====\n');
fprintf('Source: %s\n',in_file);
fprintf('Season   Years        Paired seasons (Flores/Sumba/Timor)\n');
for is = 1:4
    ss = season_names{is};
    tmp = Seasonal.(ss);
    valid = isfinite(tmp.SST) & isfinite(tmp.RAIN);
    ns = sum(valid,1);
    fprintf('%-5s    %d-%d       %d / %d / %d\n',ss, ...
        tmp.Year(1),tmp.Year(end),ns(1),ns(2),ns(3));
end
fprintf('SON 2025 excluded; Oct-Nov 2025 SST remains missing.\n');
fprintf('No interpolation; three complete months required per season.\n');
fprintf('Saved: seasonal_mean_anomalies.csv/.mat\n');
