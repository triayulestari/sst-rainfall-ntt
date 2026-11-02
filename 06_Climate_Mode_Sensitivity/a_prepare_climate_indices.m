%% ========================================================================
% a_prepare_climate_indices.m
% NINO 3.4 AND DMI MONTHLY / SEASONAL INPUTS | 2016-2025
% MATLAB R2021a
%
% INPUT OPTIONS (choose ONE; use the provided CSV by default):
%   snapshot_csv : climate_indices_input_2016_2025.csv
%   annual_txt   : nina34.anom.data.txt and dmi.had.long.data.txt
%                  (NOAA PSL annual rows: year, Jan, ..., Dec)
%
% OUTPUTS (saved beside this script):
%   climate_indices_2016_2025.mat
%   climate_indices_monthly.csv
%   climate_indices_seasonal.csv
%   climate_indices_QC.csv
%
% Index values are already climate anomalies/indices. DO NOT subtract
% calendar-month means or convert units again.
% 3 complete months required for seasonal means. No interpolation.
% DJF 2017 = Dec 2016 + Jan 2017 + Feb 2017.
% SON 2025 excluded to match SST sample availability.
%% ========================================================================
clc;
clear;

%% 1. Settings and paths
script_file = mfilename('fullpath');
if isempty(script_file)
    error('Save the script as a_prepare_climate_indices.m before running.');
end
out_dir = fileparts(script_file);

% Keep 'snapshot_csv' to reproduce the exact previous analysis input.
% Set to 'annual_txt' to parse the NOAA PSL original annual text files.
input_mode = 'snapshot_csv';

csv_file = fullfile(out_dir,'climate_indices_input_2016_2025.csv');
raw_nino_file = fullfile(out_dir,'nina34.anom.data.txt');
raw_dmi_file  = fullfile(out_dir,'dmi.had.long.data.txt');

time = (datetime(2016,1,1)+calmonths((0:119)'));
Year = year(time);
Month = month(time);
nino34 = NaN(120,1);
dmi = NaN(120,1);

%% 2. Read the chosen input
switch lower(input_mode)
    case 'snapshot_csv'
        if ~isfile(csv_file)
            error('Input CSV missing: %s',csv_file);
        end
        T = readtable(csv_file);
        expected = {'Year','Month','Nino34','DMI'};
        if ~all(ismember(expected,T.Properties.VariableNames))
            error('Input CSV must contain Year, Month, Nino34, DMI.');
        end
        if height(T) ~= 120 || ...
                ~isequal(double(T.Year(:)),double(Year)) || ...
                ~isequal(double(T.Month(:)),double(Month))
            error('CSV must have exactly 120 chronological months (Jan 2016-Dec 2025).');
        end
        nino34 = double(T.Nino34(:));
        dmi = double(T.DMI(:));
        input_description = 'Previously prepared NOAA PSL indices; included monthly input CSV';
    case 'annual_txt'
        if ~isfile(raw_nino_file) || ~isfile(raw_dmi_file)
            error(['Both NOAA annual text inputs required in script folder: ' ...
                'nina34.anom.data.txt and dmi.had.long.data.txt']);
        end
        nino34 = read_noaa_annual(raw_nino_file,Year,Month);
        dmi = read_noaa_annual(raw_dmi_file,Year,Month);
        input_description = 'NOAA PSL annual index text files';
    otherwise
        error('input_mode must be snapshot_csv or annual_txt.');
end

if any(~isfinite(nino34)) || any(~isfinite(dmi))
    error('Missing or nonfinite climate index values: check input source.');
end

%% 3. Build time-aligned seasonal series
names = {'DJF','MAM','JJA','SON'};
years_by_season = {(2017:2025)',(2016:2025)', ...
                   (2016:2025)',(2016:2024)'};
ClimateSeasonal = struct();
season_col = cell(0,1); year_col = zeros(0,1);
nino_col = zeros(0,1); dmi_col = zeros(0,1);

for is = 1:4
    ss = names{is};
    ys = years_by_season{is};
    zz1 = NaN(numel(ys),1);
    zz2 = NaN(numel(ys),1);
    for iy = 1:numel(ys)
        yy = ys(iy);
        if strcmp(ss,'DJF')
            idx = (Year==yy-1 & Month==12) | ...
                  (Year==yy & ismember(Month,[1 2]));
        elseif strcmp(ss,'MAM')
            idx = Year==yy & ismember(Month,[3 4 5]);
        elseif strcmp(ss,'JJA')
            idx = Year==yy & ismember(Month,[6 7 8]);
        else
            idx = Year==yy & ismember(Month,[9 10 11]);
        end
        if sum(idx)~=3 || any(~isfinite(nino34(idx))) || ...
                          any(~isfinite(dmi(idx)))
            error('Incomplete climate indices for %s %d.',ss,yy);
        end
        zz1(iy) = mean(nino34(idx));
        zz2(iy) = mean(dmi(idx));
        season_col{end+1,1} = ss; %#ok<SAGROW>
        year_col(end+1,1) = yy; %#ok<SAGROW>
        nino_col(end+1,1) = zz1(iy); %#ok<SAGROW>
        dmi_col(end+1,1) = zz2(iy); %#ok<SAGROW>
    end
    ClimateSeasonal.(ss).Year = ys;
    ClimateSeasonal.(ss).Nino34 = zz1;
    ClimateSeasonal.(ss).DMI = zz2;
end

%% 4. Output files
MonthlyTable = table(time,Year,Month,nino34,dmi, ...
    'VariableNames',{'Time','Year','Month','Nino34','DMI'});
SeasonalTable = table(season_col,year_col,nino_col,dmi_col, ...
    'VariableNames',{'Season','SeasonYear','Nino34_seasonal','DMI_seasonal'});

Index = {'Nino34';'DMI'};
Valid_months = [sum(isfinite(nino34));sum(isfinite(dmi))];
Missing_months = 120-Valid_months;
Minimum = [min(nino34);min(dmi)];
Maximum = [max(nino34);max(dmi)];
Mean = [mean(nino34);mean(dmi)];
Std = [std(nino34);std(dmi)];
QCTable = table(Index,Valid_months,Missing_months,Minimum,Maximum,Mean,Std);

writetable(MonthlyTable,fullfile(out_dir,'climate_indices_monthly.csv'));
writetable(SeasonalTable,fullfile(out_dir,'climate_indices_seasonal.csv'));
writetable(QCTable,fullfile(out_dir,'climate_indices_QC.csv'));
save(fullfile(out_dir,'climate_indices_2016_2025.mat'), ...
    'time','nino34','dmi','ClimateSeasonal','MonthlyTable', ...
    'SeasonalTable','QCTable','input_mode','input_description');

%% 5. QC
fprintf('\n===== CLIMATE INDICES QC =====\n');
fprintf('Input mode = %s\n',input_mode);
fprintf('Niño 3.4 valid = %d/120; DMI valid = %d/120\n', ...
    sum(isfinite(nino34)),sum(isfinite(dmi)));
fprintf('Jan 2016: Nino34=%+.3f; DMI=%+.3f\n',nino34(1),dmi(1));
fprintf('Dec 2025: Nino34=%+.3f; DMI=%+.3f\n',nino34(end),dmi(end));
fprintf('Season count: DJF=9, MAM=10, JJA=10, SON=9\n');
fprintf('Saved: climate_indices_2016_2025.mat and 3 CSVs\n');

%% Local function: NOAA PSL annual txt -> chronological monthly vector
function series = read_noaa_annual(filename,years,months)
    fid = fopen(filename,'r');
    if fid<0, error('Cannot open %s',filename); end
    cleanup = onCleanup(@() fclose(fid));
    series = NaN(numel(years),1);
    seen = false(numel(years),1);
    while ~feof(fid)
        line = fgetl(fid);
        if ~ischar(line), continue; end
        nums = sscanf(line,'%f');
        if numel(nums)<13, continue; end
        y = nums(1);
        if y~=round(y) || y<2016 || y>2025, continue; end
        idx = years==y;
        if any(seen(idx))
            error('Duplicate annual row for %d in %s.',y,filename);
        end
        v = double(nums(2:13));
        v(v<=-90) = NaN;
        for mm=1:12
            series(idx & months==mm) = v(mm);
        end
        seen(idx) = true;
    end
    if any(~seen)
        error('Missing years in original NOAA text file: %s.',filename);
    end
end
