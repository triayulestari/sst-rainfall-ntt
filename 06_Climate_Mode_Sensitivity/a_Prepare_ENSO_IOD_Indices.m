% DATA SOURCES:
%
% Niño 3.4:
% NOAA Physical Sciences Laboratory
% https://psl.noaa.gov/data/timeseries/month/Nino34/
%
% Dipole Mode Index (DMI):
% NOAA Physical Sciences Laboratory
% https://psl.noaa.gov/data/timeseries/month/DMI/
%% =========================================================
% 01_Prepare_ENSO_IOD_Indices.m
%
% PREPARE ENSO AND IOD INDICES
%
% Climate indices:
%   1. Niño 3.4 SST anomaly
%   2. Dipole Mode Index (DMI)
%
% Target period:
%   January 2016 - December 2025
%
% IMPORTANT:
%   These input series are already anomaly/index products.
%   DO NOT deseasonalize them again.
%
% Seasonal definitions used to match the SST-rainfall
% analysis:
%
%   DJF 2017-2025:
%       Dec(Y-1) + Jan(Y) + Feb(Y)
%
%   MAM 2016-2025
%   JJA 2016-2025
%   SON 2016-2024
%
% SON 2025 is intentionally excluded because SST data
% for Oct-Nov 2025 are missing in the main analysis.
%
% Outputs:
%   climate_mode_indices_2016_2025.mat
%   climate_mode_monthly_2016_2025.csv
%   climate_mode_seasonal_2016_2025.csv
%   climate_mode_QC.csv
%
% MATLAB R2021a
% No local functions are used.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. SETTINGS
%% =========================================================

target_years = ...
    (2016:2025)';


n_years = ...
    length(target_years);


n_months_total = ...
    n_years * 12;


%% =========================================================
% 2. FIND NIÑO 3.4 FILE
%
% Allows filenames such as:
%
%   nina34.anom.data.txt
%   nina34.anom.data(1).txt
%% =========================================================

files_nino = ...
    dir('nina34*.txt');


if isempty(files_nino)

    error(['Niño 3.4 file not found. ',...
           'Place a file beginning with "nina34" ',...
           'inside this folder.']);

end


if length(files_nino) > 1

    fprintf('\nMultiple Niño 3.4 files found:\n')

    for i = 1:length(files_nino)

        fprintf('%d. %s\n',...
            i,...
            files_nino(i).name);

    end

    fprintf('\nUsing first file:\n')

end


file_nino = ...
    files_nino(1).name;


fprintf('\nNiño 3.4 file:\n')
fprintf('%s\n',file_nino);


%% =========================================================
% 3. FIND DMI FILE
%% =========================================================

files_dmi = ...
    dir('dmi*.txt');


if isempty(files_dmi)

    error(['DMI file not found. ',...
           'Place a file beginning with "dmi" ',...
           'inside this folder.']);

end


if length(files_dmi) > 1

    fprintf('\nMultiple DMI files found:\n')

    for i = 1:length(files_dmi)

        fprintf('%d. %s\n',...
            i,...
            files_dmi(i).name);

    end

    fprintf('\nUsing first file:\n')

end


file_dmi = ...
    files_dmi(1).name;


fprintf('\nDMI file:\n')
fprintf('%s\n',file_dmi);


%% =========================================================
% 4. PREALLOCATE ANNUAL x MONTH MATRICES
%% =========================================================

nino_matrix = ...
    NaN(n_years,12);


dmi_matrix = ...
    NaN(n_years,12);


%% =========================================================
% 5. READ NIÑO 3.4 FILE
%
% Expected annual format:
%
% Year Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
%
% Non-data header/footer lines are ignored.
%% =========================================================

fid = ...
    fopen(file_nino,'r');


if fid == -1

    error('Could not open %s.',file_nino);

end


while ~feof(fid)

    line_text = ...
        fgetl(fid);


    if ~ischar(line_text)

        continue

    end


    values = ...
        sscanf(line_text,'%f');


    %% -----------------------------------------------------
    % A valid annual row contains:
    %
    % year + 12 monthly values = 13 numbers
    %% -----------------------------------------------------

    if length(values) >= 13

        Y = ...
            round(values(1));


        idx_year = ...
            find(target_years == Y);


        if ~isempty(idx_year)

            monthly_values = ...
                values(2:13);


            %% Missing-data protection
            %
            % Niño file uses -99.99 as missing code.
            %% ---------------------------------------------

            monthly_values(...
                monthly_values <= -90) = NaN;


            nino_matrix(idx_year,:) = ...
                monthly_values(:)';

        end

    end

end


fclose(fid);


%% =========================================================
% 6. READ DMI FILE
%
% Same annual x 12-month structure.
%% =========================================================

fid = ...
    fopen(file_dmi,'r');


if fid == -1

    error('Could not open %s.',file_dmi);

end


while ~feof(fid)

    line_text = ...
        fgetl(fid);


    if ~ischar(line_text)

        continue

    end


    values = ...
        sscanf(line_text,'%f');


    if length(values) >= 13

        Y = ...
            round(values(1));


        idx_year = ...
            find(target_years == Y);


        if ~isempty(idx_year)

            monthly_values = ...
                values(2:13);


            %% Missing-data protection
            %
            % DMI file uses -9999 as missing code.
            %% ---------------------------------------------

            monthly_values(...
                monthly_values <= -90) = NaN;


            dmi_matrix(idx_year,:) = ...
                monthly_values(:)';

        end

    end

end


fclose(fid);


%% =========================================================
% 7. ANNUAL DATA QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ANNUAL INPUT DATA QC\n')
fprintf('=========================================================\n')


fprintf('\nNiño 3.4 valid values by year:\n')

for i = 1:n_years

    fprintf('%d = %d / 12\n',...
        target_years(i),...
        sum(~isnan(nino_matrix(i,:))));

end


fprintf('\nDMI valid values by year:\n')

for i = 1:n_years

    fprintf('%d = %d / 12\n',...
        target_years(i),...
        sum(~isnan(dmi_matrix(i,:))));

end


%% =========================================================
% 8. CHECK ALL TARGET YEARS WERE READ
%% =========================================================

for i = 1:n_years

    if all(isnan(nino_matrix(i,:)))

        error(...
            'No Niño 3.4 values were read for %d.',...
            target_years(i));

    end


    if all(isnan(dmi_matrix(i,:)))

        error(...
            'No DMI values were read for %d.',...
            target_years(i));

    end

end


%% =========================================================
% 9. CREATE MONTHLY TIME VECTOR
%% =========================================================

time = ...
    NaT(n_months_total,1);


counter = 0;


for Y = 2016:2025

    for M = 1:12

        counter = ...
            counter + 1;


        time(counter) = ...
            datetime(Y,M,1);

    end

end


%% =========================================================
% 10. CONVERT YEAR x MONTH MATRICES TO 120-MONTH SERIES
%
% Matrix transpose ensures order:
%
% Jan 2016
% Feb 2016
% ...
% Dec 2016
% Jan 2017
% ...
%% =========================================================

nino34 = ...
    reshape(...
    nino_matrix',...
    [],...
    1);


dmi = ...
    reshape(...
    dmi_matrix',...
    [],...
    1);


%% =========================================================
% 11. MONTHLY SERIES QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY CLIMATE INDEX QC\n')
fprintf('=========================================================\n')


fprintf('Total monthly positions = %d\n',...
    length(time));


fprintf('Niño 3.4 valid months = %d / %d\n',...
    sum(~isnan(nino34)),...
    n_months_total);


fprintf('DMI valid months = %d / %d\n',...
    sum(~isnan(dmi)),...
    n_months_total);


fprintf('\nFirst month:\n')

fprintf('%s | Niño3.4 = %.3f | DMI = %.3f\n',...
    datestr(time(1),'mmm-yyyy'),...
    nino34(1),...
    dmi(1));


fprintf('\nLast month:\n')

fprintf('%s | Niño3.4 = %.3f | DMI = %.3f\n',...
    datestr(time(end),'mmm-yyyy'),...
    nino34(end),...
    dmi(end));


%% =========================================================
% 12. EXPECTED ENDPOINT QC
%
% Based directly on input files:
%
% Jan 2016:
% Niño3.4 = 2.13
% DMI     = 0.265
%
% Dec 2025:
% Niño3.4 = -0.39
% DMI     = -0.017
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ENDPOINT VALUE QC\n')
fprintf('=========================================================\n')


fprintf('Jan 2016 Niño3.4 = %.3f\n',...
    nino34(1));

fprintf('Expected approximately +2.130\n');


fprintf('Jan 2016 DMI = %.3f\n',...
    dmi(1));

fprintf('Expected approximately +0.265\n');


fprintf('\nDec 2025 Niño3.4 = %.3f\n',...
    nino34(end));

fprintf('Expected approximately -0.390\n');


fprintf('Dec 2025 DMI = %.3f\n',...
    dmi(end));

fprintf('Expected approximately -0.017\n');


%% =========================================================
% 13. RANGE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY INDEX RANGES\n')
fprintf('=========================================================\n')


fprintf('Niño3.4 range = %.3f to %.3f C\n',...
    min(nino34,[],'omitnan'),...
    max(nino34,[],'omitnan'));


fprintf('DMI range = %.3f to %.3f\n',...
    min(dmi,[],'omitnan'),...
    max(dmi,[],'omitnan'));


%% =========================================================
% 14. MONTHLY TABLE
%% =========================================================

Year = ...
    year(time);


Month = ...
    month(time);


Nino34 = ...
    nino34;


DMI = ...
    dmi;


MonthlyTable = table(...
    time,...
    Year,...
    Month,...
    Nino34,...
    DMI,...
    'VariableNames',{...
    'Time',...
    'Year',...
    'Month',...
    'Nino34',...
    'DMI'});


%% =========================================================
% 15. DEFINE SEASON YEARS
%% =========================================================

years_DJF = ...
    (2017:2025)';


years_MAM = ...
    (2016:2025)';


years_JJA = ...
    (2016:2025)';


years_SON = ...
    (2016:2024)';


%% =========================================================
% 16. PREALLOCATE SEASONAL VALUES
%% =========================================================

nino_DJF = ...
    NaN(length(years_DJF),1);

dmi_DJF = ...
    NaN(length(years_DJF),1);


nino_MAM = ...
    NaN(length(years_MAM),1);

dmi_MAM = ...
    NaN(length(years_MAM),1);


nino_JJA = ...
    NaN(length(years_JJA),1);

dmi_JJA = ...
    NaN(length(years_JJA),1);


nino_SON = ...
    NaN(length(years_SON),1);

dmi_SON = ...
    NaN(length(years_SON),1);


%% =========================================================
% 17. DJF SEASONAL MEANS
%
% DJF season year Y:
%
% Dec(Y-1), Jan(Y), Feb(Y)
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


    if sum(~isnan(nino34(idx))) == 3

        nino_DJF(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        dmi_DJF(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 18. MAM SEASONAL MEANS
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


    if sum(~isnan(nino34(idx))) == 3

        nino_MAM(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        dmi_MAM(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 19. JJA SEASONAL MEANS
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


    if sum(~isnan(nino34(idx))) == 3

        nino_JJA(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        dmi_JJA(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 20. SON SEASONAL MEANS
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


    if sum(~isnan(nino34(idx))) == 3

        nino_SON(i) = ...
            mean(nino34(idx));

    end


    if sum(~isnan(dmi(idx))) == 3

        dmi_SON(i) = ...
            mean(dmi(idx));

    end

end


%% =========================================================
% 21. SEASONAL SAMPLE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SEASONAL CLIMATE INDEX QC\n')
fprintf('=========================================================\n')


fprintf('\nDJF 2017-2025:\n')

fprintf('Niño3.4 = %d / 9\n',...
    sum(~isnan(nino_DJF)));

fprintf('DMI     = %d / 9\n',...
    sum(~isnan(dmi_DJF)));


fprintf('\nMAM 2016-2025:\n')

fprintf('Niño3.4 = %d / 10\n',...
    sum(~isnan(nino_MAM)));

fprintf('DMI     = %d / 10\n',...
    sum(~isnan(dmi_MAM)));


fprintf('\nJJA 2016-2025:\n')

fprintf('Niño3.4 = %d / 10\n',...
    sum(~isnan(nino_JJA)));

fprintf('DMI     = %d / 10\n',...
    sum(~isnan(dmi_JJA)));


fprintf('\nSON 2016-2024:\n')

fprintf('Niño3.4 = %d / 9\n',...
    sum(~isnan(nino_SON)));

fprintf('DMI     = %d / 9\n',...
    sum(~isnan(dmi_SON)));


%% =========================================================
% 22. CREATE LONG-FORM SEASONAL TABLE
%% =========================================================

Season = {};
SeasonYear = [];
Nino34_seasonal = [];
DMI_seasonal = [];


%% DJF

for i = 1:length(years_DJF)

    Season{end+1,1} = ...
        'DJF';

    SeasonYear(end+1,1) = ...
        years_DJF(i);

    Nino34_seasonal(end+1,1) = ...
        nino_DJF(i);

    DMI_seasonal(end+1,1) = ...
        dmi_DJF(i);

end


%% MAM

for i = 1:length(years_MAM)

    Season{end+1,1} = ...
        'MAM';

    SeasonYear(end+1,1) = ...
        years_MAM(i);

    Nino34_seasonal(end+1,1) = ...
        nino_MAM(i);

    DMI_seasonal(end+1,1) = ...
        dmi_MAM(i);

end


%% JJA

for i = 1:length(years_JJA)

    Season{end+1,1} = ...
        'JJA';

    SeasonYear(end+1,1) = ...
        years_JJA(i);

    Nino34_seasonal(end+1,1) = ...
        nino_JJA(i);

    DMI_seasonal(end+1,1) = ...
        dmi_JJA(i);

end


%% SON

for i = 1:length(years_SON)

    Season{end+1,1} = ...
        'SON';

    SeasonYear(end+1,1) = ...
        years_SON(i);

    Nino34_seasonal(end+1,1) = ...
        nino_SON(i);

    DMI_seasonal(end+1,1) = ...
        dmi_SON(i);

end


SeasonalTable = table(...
    Season,...
    SeasonYear,...
    Nino34_seasonal,...
    DMI_seasonal);


%% =========================================================
% 23. CREATE QC TABLE
%% =========================================================

Index = {...
    'Nino34';...
    'DMI'};


Valid_months = [...
    sum(~isnan(nino34));...
    sum(~isnan(dmi))];


Missing_months = [...
    sum(isnan(nino34));...
    sum(isnan(dmi))];


Minimum = [...
    min(nino34,[],'omitnan');...
    min(dmi,[],'omitnan')];


Maximum = [...
    max(nino34,[],'omitnan');...
    max(dmi,[],'omitnan')];


Mean = [...
    mean(nino34,'omitnan');...
    mean(dmi,'omitnan')];


Std = [...
    std(nino34,'omitnan');...
    std(dmi,'omitnan')];


QCTable = table(...
    Index,...
    Valid_months,...
    Missing_months,...
    Minimum,...
    Maximum,...
    Mean,...
    Std);


%% =========================================================
% 24. DISPLAY QC TABLE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL CLIMATE INDEX QC TABLE\n')
fprintf('=========================================================\n')


disp(QCTable)


%% =========================================================
% 25. SAVE MAT FILE
%% =========================================================

save(...
    'climate_mode_indices_2016_2025.mat',...
    'time',...
    'nino34',...
    'dmi',...
    'nino_matrix',...
    'dmi_matrix',...
    'years_DJF',...
    'years_MAM',...
    'years_JJA',...
    'years_SON',...
    'nino_DJF',...
    'nino_MAM',...
    'nino_JJA',...
    'nino_SON',...
    'dmi_DJF',...
    'dmi_MAM',...
    'dmi_JJA',...
    'dmi_SON',...
    'MonthlyTable',...
    'SeasonalTable',...
    'QCTable');


%% =========================================================
% 26. SAVE CSV FILES
%% =========================================================

writetable(...
    MonthlyTable,...
    'climate_mode_monthly_2016_2025.csv');


writetable(...
    SeasonalTable,...
    'climate_mode_seasonal_2016_2025.csv');


writetable(...
    QCTable,...
    'climate_mode_QC.csv');


%% =========================================================
% 27. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('ENSO / IOD INDEX PREPARATION COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n')

fprintf('1. climate_mode_indices_2016_2025.mat\n');

fprintf('2. climate_mode_monthly_2016_2025.csv\n');

fprintf('3. climate_mode_seasonal_2016_2025.csv\n');

fprintf('4. climate_mode_QC.csv\n');


fprintf('\nImportant methodological note:\n')

fprintf(['Niño 3.4 and DMI were used as supplied ',...
         'anomaly/index products and were NOT ',...
         'deseasonalized again.\n']);


fprintf('\nNext step:\n')

fprintf(['02_ClimateMode_Basic_Relationships.m will ',...
         'evaluate the basic relationships of Niño 3.4 ',...
         'and DMI with regional SST and rainfall anomalies.\n']);