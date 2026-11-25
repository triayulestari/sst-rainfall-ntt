%% ========================================================================
% b_prepare_h09_scenario.m | Controlled Oct-Nov 2022 SST source switch
% MATLAB R2021a+ | Run from any working directory.
%
% Inputs (never modified):
%   ../02_Regional_Timeseries/regional_timeseries_raw.csv/.mat
%   ../02_Regional_Timeseries/regional_grid_check.csv
%   02_Comparison_Outputs/H08_H09_overlap_regional_comparison.csv
%
% New scenario inputs (outside original Stage 02):
%   03_Scenarios/H08_Final/02_Regional_Timeseries/
%   03_Scenarios/H09_Alternative/02_Regional_Timeseries/
%
% H08_Final is the existing 2016-2025 series. H09_Alternative differs ONLY
% in October-November 2022 SST for Flores, Sumba and Timor.
%
% IMPORTANT: This prepares regional inputs; it DOES NOT recreate spatial
% grid-level SST or rerun correlation/FDR scripts. Those stages must use
% isolated scenario outputs and their original statistical implementation.
%% ========================================================================

clear; clc;
thisScript = mfilename('fullpath');
if isempty(thisScript)
    error('Save this script to 09_Transition_Sensitivity before running it.');
end
folder09 = fileparts(thisScript);
folderData = fileparts(folder09);
base02 = fullfile(folderData,'02_Regional_Timeseries');
overlapCSV = fullfile(folder09,'02_Comparison_Outputs', ...
    'H08_H09_overlap_regional_comparison.csv');
outBase = fullfile(folder09,'03_Scenarios');
dirH08 = fullfile(outBase,'H08_Final','02_Regional_Timeseries');
dirH09 = fullfile(outBase,'H09_Alternative','02_Regional_Timeseries');

% Empty scenario directories are permitted. Existing regional outputs are
% checked below and will NEVER be overwritten.

rawCSV = fullfile(base02,'regional_timeseries_raw.csv');
rawMAT = fullfile(base02,'regional_timeseries_raw.mat');
gridCSV = fullfile(base02,'regional_grid_check.csv');
requiredFiles = {rawCSV,rawMAT,gridCSV,overlapCSV};
for i=1:numel(requiredFiles)
    if ~isfile(requiredFiles{i})
        error('Required input is missing: %s',requiredFiles{i});
    end
end

% Refuse to overwrite a previous run, including partial scenario outputs.
targets = {fullfile(dirH08,'regional_timeseries_raw.csv'), ...
    fullfile(dirH09,'regional_timeseries_raw.csv'), ...
    fullfile(dirH08,'regional_timeseries_raw.mat'), ...
    fullfile(dirH09,'regional_timeseries_raw.mat')};
for i=1:numel(targets)
    if isfile(targets{i})
        error(['Scenario output already exists: %s\n' ...
            'Preserve the old run and use a clean scenario folder.'],targets{i});
    end
end

A = readtable(rawCSV);
G = readtable(gridCSV);
O = readtable(overlapCSV);
assert(height(A)==120,'Regional Stage 02 must contain 120 months.');
assert(height(G)==120,'Grid-count QC must contain 120 months.');
assert(height(O)==8,'Overlap comparison must contain 2 months x 4 rows.');

timeA = parse_months(A.Time);
timeG = parse_months(G.Time);
expected = datetime(2016,1,1)+calmonths((0:119)');
assert(isequal(timeA,expected),'Unexpected Stage 02 monthly calendar.');
assert(isequal(timeA,timeG),'Grid-count QC monthly calendar differs.');

% Check the current Stage 02 MAT is the same provenance as the CSV.
S = load(rawMAT);
names = {'Flores','Sumba','Timor'};
for r=1:3
    lowerName = lower(names{r});
    sstField = ['sst_' lowerName];
    rainField = ['prec_' lowerName];
    countField = ['valid_sst_' lowerName];
    assert(isfield(S,sstField) && isfield(S,rainField) && ...
        isfield(S,countField),'Stage 02 MAT misses required %s fields.', ...
        names{r});
    sstFromMat=S.(sstField);
    rainFromMat=S.(rainField);
    countFromMat=S.(countField);
    assert_same_vector(sstFromMat(:),A.(['SST_' names{r} '_C']),1e-8, ...
        [names{r} ' SST MAT versus CSV']);
    assert_same_vector(rainFromMat(:), ...
        A.(['Rain_' names{r} '_mm_month']),1e-8, ...
        [names{r} ' rainfall MAT versus CSV']);
    assert_same_vector(double(countFromMat(:)), ...
        double(G.(['Valid_SST_' names{r}])),0, ...
        [names{r} ' valid SST counts MAT versus CSV']);
end

% Preserve H08 and create a separate H09 alternative.
B = A;
G9 = G;
S9 = S;
monthCodes = {'202210','202211'};
changed = 0;
for m=1:2
    dt = datetime(str2double(monthCodes{m}(1:4)), ...
                  str2double(monthCodes{m}(5:6)),1);
    idx = find(timeA==dt);
    assert(numel(idx)==1,'Missing or duplicate month %s.',monthCodes{m});
    for r=1:3
        match = strcmp(string(O.Month_YYYYMM),monthCodes{m}) & ...
            strcmp(string(O.Region),names{r});
        assert(nnz(match)==1,'Expected one overlap QC row: %s %s.', ...
            monthCodes{m},names{r});
        o = O(match,:);
        colSST = ['SST_' names{r} '_C'];
        colValid = ['Valid_SST_' names{r}];
        matSST = ['sst_' lower(names{r})];
        matValid = ['valid_sst_' lower(names{r})];
        originalSST=A.(colSST);
        originalValid=G.(colValid);
        assert(abs(originalSST(idx)-o.H08_mean_C)<1e-5, ...
            ['Source-product QC does not match FINAL H08 Stage 02: ' ...
             '%s %s. STOP and inspect the data lineage.'], ...
             monthCodes{m},names{r});
        assert(originalValid(idx)==o.N_H08_valid, ...
            'H08 valid-pixel count mismatch: %s %s.', ...
            monthCodes{m},names{r});
        assert(logical(o.Paired_grid_aligned), ...
            'Overlap coordinates are not aligned for %s %s.', ...
            monthCodes{m},names{r});

        revisedSST=B.(colSST);
        revisedSST(idx)=o.H09_mean_C;
        B.(colSST)=revisedSST;
        revisedValid=G9.(colValid);
        revisedValid(idx)=o.N_H09_valid;
        G9.(colValid)=revisedValid;
        matSSTVector=S9.(matSST);
        matSSTVector(idx)=o.H09_mean_C;
        S9.(matSST)=matSSTVector;
        matValidVector=S9.(matValid);
        matValidVector(idx)=o.N_H09_valid;
        S9.(matValid)=matValidVector;
        changed = changed+1;
    end
end
assert(changed==6,'Expected exactly six changed SST regional values.');

% A/B equality outside the explicitly substituted source months.
allowed = ismember(timeA,[datetime(2022,10,1);datetime(2022,11,1)]);
for r=1:3
    sstCol = ['SST_' names{r} '_C'];
    rainCol = ['Rain_' names{r} '_mm_month'];
    rawSST=A.(sstCol);
    altSST=B.(sstCol);
    assert_same_vector(rawSST(~allowed),altSST(~allowed),0, ...
        [names{r} ' all other SST months']);
    assert_same_vector(A.(rainCol),B.(rainCol),0, ...
        [names{r} ' all rainfall months']);
    assert(nnz(isfinite(A.(sstCol)))==118 && ...
        nnz(isfinite(B.(sstCol)))==118, ...
        'Both SST scenarios must retain 118 valid months.');
    assert(all(isnan(rawSST([118 119]))) && ...
        all(isnan(altSST([118 119]))), ...
        'October-November 2025 must remain missing SST.');
end

if ~isfolder(dirH08), mkdir(dirH08); end
if ~isfolder(dirH09), mkdir(dirH09); end
writetable(A,fullfile(dirH08,'regional_timeseries_raw.csv'));
writetable(B,fullfile(dirH09,'regional_timeseries_raw.csv'));
writetable(G,fullfile(dirH08,'regional_grid_check.csv'));
writetable(G9,fullfile(dirH09,'regional_grid_check.csv'));
save(fullfile(dirH08,'regional_timeseries_raw.mat'),'-struct','S');
save(fullfile(dirH09,'regional_timeseries_raw.mat'),'-struct','S9');

% Ancillary Stage 02 inputs are unchanged by the controlled experiment.
unchanged = {'regional_domain_grid_metadata.csv', ...
    'regional_data_availability.csv'};
for i=1:numel(unchanged)
    original = fullfile(base02,unchanged{i});
    if isfile(original)
        copyfile(original,fullfile(dirH08,unchanged{i}));
        copyfile(original,fullfile(dirH09,unchanged{i}));
    end
end

fprintf('\n===== TWO REGIONAL SCENARIOS PREPARED =====\n');
fprintf('H08 baseline  : %s\n',dirH08);
fprintf('H09 alternate : %s\n',dirH09);
fprintf('Changed SST inputs: %d region-months (October-November 2022 only).\n', ...
    changed);
fprintf('Other SST months: identical. CHIRPS: identical.\n');
fprintf(['NEXT: Run the ORIGINAL Stage 03 onward on each scenario in ' ...
    'separate folders. The prepared Stage 02 MAT/CSV is not itself a ' ...
    'new correlation or FDR result.\n']);

function dt = parse_months(raw)
    if isdatetime(raw)
        dt = dateshift(raw(:),'start','month');
        return;
    end
    raw = string(raw(:));
    try
        dt = datetime(raw,'InputFormat','dd-MMM-yyyy','Locale','en_US');
    catch
        dt = datetime(raw);
    end
    dt = dateshift(dt(:),'start','month');
end

function assert_same_vector(x,y,tol,label)
    x = double(x(:)); y = double(y(:));
    assert(numel(x)==numel(y),'Length mismatch: %s.',label);
    sameMissing = isnan(x) & isnan(y);
    bothNumeric = isfinite(x) & isfinite(y) & abs(x-y)<=tol;
    assert(all(sameMissing | bothNumeric), ...
        'Unexpected difference in %s.',label);
end
