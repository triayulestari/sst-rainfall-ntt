%% ========================================================================
% a_compare_h08_h09_overlap.m
% H08 v2.00 versus H09 v2.01 SST | October-November 2022
%
% MATLAB R2021a or newer. No Mapping Toolbox/M_Map required.
% Run from any working directory; paths are relative to THIS script.
%
% This is a SOURCE-PRODUCT comparison. It does not infer which platform is
% intrinsically more accurate, nor does it recompute downstream correlations.
%
% Original full-disk NetCDF inputs: 01_SST_H08_H09_Overlap_202210_202211/
% Outputs:                         02_Comparison_Outputs/
%
% Critical distinction:
%   Delta regional mean = mean(all available H09) - mean(all available H08)
%   Delta paired mean   = mean(H09-H08 on jointly valid, co-located pixels)
% These are NOT interchangeable when valid-pixel coverage differs.
% ========================================================================

clear; clc;

scriptFullPath = mfilename('fullpath');
if isempty(scriptFullPath)
    error('Save this .m file before running it.');
end
rootDir = fileparts(scriptFullPath);
inputDir = fullfile(rootDir,'01_SST_H08_H09_Overlap_202210_202211');
outputDir = fullfile(rootDir,'02_Comparison_Outputs');
if ~isfolder(inputDir)
    error('Missing input directory: %s',inputDir);
end
if ~isfolder(outputDir)
    mkdir(outputDir);
end

months = {'202210','202211'};
platforms = {'H08','H09'};
regions = {'Flores','Sumba','Timor','NTT_study_domain'};
% [minimum longitude, maximum longitude, minimum latitude, maximum latitude]
% Exact SST boxes from the regional time-series extraction script.
boxes = [ ...
    119.0  123.5  -9.2  -7.9;  ... % Flores
    118.8  121.2 -10.5  -9.2;  ... % Sumba
    123.3  126.0 -10.6  -8.6;  ... % Timor
    118.0  127.5 -11.5  -7.0];     % Broad NTT analysis domain

tileWidth = 96;                 % Keep full-disk memory usage moderate.
coordinateTolerance = 1e-4;   % Degrees; only co-located pixels are paired.
nRegions = numel(regions);
nMonths = numel(months);

fprintf('\n===== SST H08 / H09 OVERLAP COMPARISON =====\n');
fprintf('Months: 202210 and 202211 | Difference convention: H09 - H08\n');

P = cell(nMonths,2);
InventoryMonth = cell(nMonths*2,1);
InventorySatellite = cell(nMonths*2,1);
InventoryFile = cell(nMonths*2,1);
InventorySSTVariable = cell(nMonths*2,1);
InventoryLonVariable = cell(nMonths*2,1);
InventoryLatVariable = cell(nMonths*2,1);
InventoryOriginalUnits = cell(nMonths*2,1);
InventoryRasterShape = cell(nMonths*2,1);
InventoryVersion = cell(nMonths*2,1);
InventoryFileBytes = zeros(nMonths*2,1);

%% 1. Resolve exact monthly source inputs; inspect their NetCDF dimensions.
for m = 1:nMonths
    for s = 1:2
        pattern = sprintf('%s_%s01_0000_1MSST*.nc', ...
            platforms{s},months{m});
        match = dir(fullfile(inputDir,pattern));
        if numel(match) ~= 1
            error(['Expected exactly ONE input matching %s; found %d. ' ...
                'Check the four original NetCDF files in: %s'], ...
                pattern,numel(match),inputDir);
        end

        path = fullfile(inputDir,match(1).name);
        P{m,s} = inspect_product(path);
        k = (m-1)*2+s;
        InventoryMonth{k} = months{m};
        InventorySatellite{k} = platforms{s};
        InventoryFile{k} = match(1).name;
        InventorySSTVariable{k} = P{m,s}.sstVar;
        InventoryLonVariable{k} = P{m,s}.lonVar;
        InventoryLatVariable{k} = P{m,s}.latVar;
        InventoryOriginalUnits{k} = P{m,s}.units;
        InventoryRasterShape{k} = sprintf('%d x %d',P{m,s}.sz(1),P{m,s}.sz(2));
        InventoryFileBytes(k) = match(1).bytes;
        ver = regexp(match(1).name,'1MSST(\d+)','tokens','once');
        if isempty(ver)
            InventoryVersion{k} = 'unknown';
        else
            InventoryVersion{k} = ver{1};
        end

        fprintf('%s %s | %s | SST=%s | %s | input units=%s\n', ...
            months{m},platforms{s},match(1).name,P{m,s}.sstVar, ...
            InventoryRasterShape{k},P{m,s}.units);
    end
end

Inventory = table(InventoryMonth,InventorySatellite,InventoryVersion, ...
    InventoryFile,InventorySSTVariable,InventoryLonVariable, ...
    InventoryLatVariable,InventoryOriginalUnits,InventoryRasterShape, ...
    InventoryFileBytes, ...
    'VariableNames',{'Month_YYYYMM','Platform','Product_tag', ...
    'Filename','SST_variable','Longitude_variable','Latitude_variable', ...
    'Original_SST_units','SST_spatial_size','File_size_bytes'});
writetable(Inventory,fullfile(outputDir,'H08_H09_overlap_source_inventory.csv'));

%% 2. Independent regional means; retain missing-pixel effects.
sumSST = zeros(nMonths,nRegions,2);
nValid = zeros(nMonths,nRegions,2);
nGeographicCells = zeros(nMonths,nRegions,2);

for m = 1:nMonths
    for s = 1:2
        p = P{m,s};
        for j = 1:tileWidth:p.sz(2)
            width = min(tileWidth,p.sz(2)-j+1);
            A = read_sst_celsius(p,j,width);
            [lon,lat] = read_geolocation(p,j,width);
            for r = 1:nRegions
                inRegion = inside_rectangle(lon,lat,boxes(r,:));
                nGeographicCells(m,r,s) = nGeographicCells(m,r,s) + ...
                    nnz(inRegion);
                valid = inRegion & isfinite(A);
                nValid(m,r,s) = nValid(m,r,s) + nnz(valid);
                sumSST(m,r,s) = sumSST(m,r,s) + sum(A(valid));
            end
        end
    end
end

%% 3. Paired SST differences, ONLY on matching native coordinate grids.
nPaired = zeros(nMonths,nRegions);
sumDelta = zeros(nMonths,nRegions);
sumAbsDelta = zeros(nMonths,nRegions);
sumDeltaSquared = zeros(nMonths,nRegions);
maxAbsDelta = zeros(nMonths,nRegions);
gridAligned = false(nMonths,1);
maxCoordinateDifferenceDeg = NaN(nMonths,1);

for m = 1:nMonths
    p8 = P{m,1};
    p9 = P{m,2};
    if ~isequal(p8.sz,p9.sz)
        warning('%s: grid dimensions differ; paired metrics remain NaN.', ...
            months{m});
        continue;
    end

    aligned = true;
    maxCoordDiff = 0;
    nCoordinatePairs = 0;
    for j = 1:tileWidth:p8.sz(2)
        width = min(tileWidth,p8.sz(2)-j+1);
        [lon8,lat8] = read_geolocation(p8,j,width);
        [lon9,lat9] = read_geolocation(p9,j,width);

        domainMask = inside_rectangle(lon8,lat8,boxes(4,:)) | ...
                     inside_rectangle(lon9,lat9,boxes(4,:));
        comparable = domainMask & isfinite(lon8) & isfinite(lat8) & ...
            isfinite(lon9) & isfinite(lat9);
        nCoordinatePairs = nCoordinatePairs + nnz(comparable);
        if any(comparable(:))
            c1 = max(abs(lon8(comparable)-lon9(comparable)));
            c2 = max(abs(lat8(comparable)-lat9(comparable)));
            maxCoordDiff = max([maxCoordDiff,c1,c2]);
            if maxCoordDiff > coordinateTolerance
                aligned = false;
                break;
            end
        end

        A8 = read_sst_celsius(p8,j,width);
        A9 = read_sst_celsius(p9,j,width);
        pairedValid = comparable & isfinite(A8) & isfinite(A9);
        delta = A9-A8;
        for r = 1:nRegions
            pairedInRegion = pairedValid & ...
                inside_rectangle(lon8,lat8,boxes(r,:)) & ...
                inside_rectangle(lon9,lat9,boxes(r,:));
            vals = delta(pairedInRegion);
            nPaired(m,r) = nPaired(m,r) + numel(vals);
            sumDelta(m,r) = sumDelta(m,r) + sum(vals);
            sumAbsDelta(m,r) = sumAbsDelta(m,r) + sum(abs(vals));
            sumDeltaSquared(m,r) = sumDeltaSquared(m,r) + sum(vals.^2);
            if ~isempty(vals)
                maxAbsDelta(m,r) = max(maxAbsDelta(m,r),max(abs(vals)));
            end
        end
    end

    maxCoordinateDifferenceDeg(m) = maxCoordDiff;
    gridAligned(m) = aligned && nCoordinatePairs > 0;
    if ~gridAligned(m)
        % Do not report partial tile results after discovering a mismatch.
        nPaired(m,:) = 0;
        sumDelta(m,:) = 0;
        sumAbsDelta(m,:) = 0;
        sumDeltaSquared(m,:) = 0;
        maxAbsDelta(m,:) = 0;
        warning(['%s: H08 and H09 grids are not co-located within %.4g ' ...
            'degrees. Paired metrics are suppressed.'], ...
            months{m},coordinateTolerance);
    end
    fprintf('%s | co-located grid=%d | maximum coordinate delta=%.6g deg\n', ...
        months{m},gridAligned(m),maxCoordDiff);
end

%% 4. Results table: two months x three regions + study domain.
nRows = nMonths*nRegions;
Month_YYYYMM = cell(nRows,1);
Region = cell(nRows,1);
N_H08_grid_centres = zeros(nRows,1);
N_H09_grid_centres = zeros(nRows,1);
N_H08_valid = zeros(nRows,1);
N_H09_valid = zeros(nRows,1);
H08_mean_C = NaN(nRows,1);
H09_mean_C = NaN(nRows,1);
Delta_regional_mean_H09_minus_H08_C = NaN(nRows,1);
Paired_grid_aligned = false(nRows,1);
N_paired = zeros(nRows,1);
Mean_paired_H09_minus_H08_C = NaN(nRows,1);
MAE_paired_C = NaN(nRows,1);
RMSE_paired_C = NaN(nRows,1);
Maximum_absolute_paired_difference_C = NaN(nRows,1);
Max_coordinate_difference_deg = NaN(nRows,1);

for m = 1:nMonths
    for r = 1:nRegions
        k = (m-1)*nRegions+r;
        Month_YYYYMM{k} = months{m};
        Region{k} = regions{r};
        N_H08_grid_centres(k) = nGeographicCells(m,r,1);
        N_H09_grid_centres(k) = nGeographicCells(m,r,2);
        N_H08_valid(k) = nValid(m,r,1);
        N_H09_valid(k) = nValid(m,r,2);
        if N_H08_valid(k)>0
            H08_mean_C(k) = sumSST(m,r,1)/N_H08_valid(k);
        end
        if N_H09_valid(k)>0
            H09_mean_C(k) = sumSST(m,r,2)/N_H09_valid(k);
        end
        Delta_regional_mean_H09_minus_H08_C(k) = ...
            H09_mean_C(k)-H08_mean_C(k);
        Paired_grid_aligned(k) = gridAligned(m);
        Max_coordinate_difference_deg(k) = maxCoordinateDifferenceDeg(m);
        if gridAligned(m)
            N_paired(k) = nPaired(m,r);
            if N_paired(k)>0
                Mean_paired_H09_minus_H08_C(k) = ...
                    sumDelta(m,r)/N_paired(k);
                MAE_paired_C(k) = sumAbsDelta(m,r)/N_paired(k);
                RMSE_paired_C(k) = sqrt(sumDeltaSquared(m,r)/N_paired(k));
                Maximum_absolute_paired_difference_C(k) = maxAbsDelta(m,r);
            end
        end
    end
end

Result = table(Month_YYYYMM,Region,N_H08_grid_centres, ...
    N_H09_grid_centres,N_H08_valid,N_H09_valid,H08_mean_C, ...
    H09_mean_C,Delta_regional_mean_H09_minus_H08_C, ...
    Paired_grid_aligned,N_paired,Mean_paired_H09_minus_H08_C, ...
    MAE_paired_C,RMSE_paired_C, ...
    Maximum_absolute_paired_difference_C,Max_coordinate_difference_deg);

outCSV = fullfile(outputDir,'H08_H09_overlap_regional_comparison.csv');
writetable(Result,outCSV);
fprintf('\n===== REGIONAL COMPARISON (H09 MINUS H08, CELSIUS) =====\n');
disp(Result(:,{'Month_YYYYMM','Region','N_H08_valid','N_H09_valid', ...
    'H08_mean_C','H09_mean_C', ...
    'Delta_regional_mean_H09_minus_H08_C', ...
    'Paired_grid_aligned','N_paired', ...
    'Mean_paired_H09_minus_H08_C'}));

%% 5. Plot: independent means versus matched-pixel differences.
regionalDelta = NaN(3,2);
pairedDelta = NaN(3,2);
for r = 1:3
    for m = 1:2
        k = (m-1)*nRegions+r;
        regionalDelta(r,m) = Delta_regional_mean_H09_minus_H08_C(k);
        pairedDelta(r,m) = Mean_paired_H09_minus_H08_C(k);
    end
end

fig = figure('Visible','off','Color','w','Position',[100 100 1200 490]);
subplot(1,2,1);
bar(regionalDelta,'grouped');
set(gca,'XTick',1:3,'XTickLabel',regions(1:3));
ylabel('SST difference (deg C)');
title('(a) Difference of regional means');
legend({'Oct 2022','Nov 2022'}, ...
    'Location','best','AutoUpdate','off');

subplot(1,2,2);
bar(pairedDelta,'grouped');
set(gca,'XTick',1:3,'XTickLabel',regions(1:3));
ylabel('SST difference (deg C)');
title('(b) Mean difference at paired valid pixels');
legend({'Oct 2022','Nov 2022'},'Location','best');
grid on; yline(0,'k-');
if ~any(isfinite(pairedDelta(:)))
    text(0.5,0.5,'Coordinate grids do not align: paired result not available', ...
        'Units','normalized','HorizontalAlignment','center', ...
        'FontSize',9,'Interpreter','none');
end
sgtitle('Source-product sensitivity: H09 minus H08 SST, Oct-Nov 2022');
outPNG = fullfile(outputDir,'H08_H09_overlap_comparison.png');
exportgraphics(fig,outPNG,'Resolution',300);
close(fig);

%% 6. Reproducibility note (derived dynamically; no hard-coded outcomes).
outMeta = fullfile(outputDir,'H08_H09_overlap_methods.txt');
fid = fopen(outMeta,'w');
if fid < 0
    error('Cannot write metadata file: %s',outMeta);
end
fprintf(fid,'H08/H09 SST SOURCE-PRODUCT OVERLAP COMPARISON\n');
fprintf(fid,'Months: October and November 2022. Delta convention: H09-H08.\n');
fprintf(fid,'For adoption of H08 instead of old H09, reverse the delta sign.\n');
fprintf(fid,'Input files: see H08_H09_overlap_source_inventory.csv.\n');
fprintf(fid,'Products: H08 1MSST200 vs H09 1MSST201.\n');
fprintf(fid,'Source products differ in platform AND processing version.\n');
fprintf(fid,'Rectangular SST boxes exactly as regional Stage 02 extraction.\n');
fprintf(fid,'Finite SST only, arithmetic means, no interpolation or weighting.\n');
fprintf(fid,'Invalid/fill SST removed; Kelvin converted to Celsius if needed.\n');
fprintf(fid,'Delta regional mean includes differences in valid-pixel coverage.\n');
fprintf(fid,'Paired differences use only jointly valid, co-located native pixels.\n');
fprintf(fid,'Maximum tolerated geographic discrepancy: %.6g degrees.\n', ...
    coordinateTolerance);
for m = 1:nMonths
    fprintf(fid,'%s: paired grid aligned=%d; max coordinate difference=%.9g deg.\n', ...
        months{m},gridAligned(m),maxCoordinateDifferenceDeg(m));
end
fprintf(fid,'These results do NOT recalculate anomalies, lag, season or FDR.\n');
fprintf(fid,'Two months alone are not suitable for general bias significance.\n');
fclose(fid);

fprintf('\n===== OVERLAP SENSITIVITY COMPLETE =====\n');
fprintf('CSV: %s\nPNG: %s\nTXT: %s\n',outCSV,outPNG,outMeta);
fprintf('Review pixel counts, coordinate check, and sign H09-H08.\n');

%% ========================================================================
% Local helper functions. Strict metadata checks prevent invalid comparisons.
% ========================================================================

function p = inspect_product(filePath)
    info = ncinfo(filePath);
    names = {info.Variables.Name};
    p.file = filePath;
    p.sstVar = find_named_variable(names, ...
        {'sea_surface_temperature','analysed_sst','sst','SST'});
    p.lonVar = find_named_variable(names,{'lon','longitude'});
    p.latVar = find_named_variable(names,{'lat','latitude'});
    if isempty(p.sstVar) || isempty(p.lonVar) || isempty(p.latVar)
        error(['Unrecognized NetCDF fields in %s. Run ncdisp on this file. ' ...
            'Detected variables: %s'],filePath,strjoin(names,', '));
    end

    si = ncinfo(filePath,p.sstVar);
    dimensions = si.Dimensions;
    significant = find([dimensions.Length]>1);
    if numel(significant)~=2
        error(['Expected two SST spatial dimensions (plus optional ' ...
            'singleton time); got %d non-singleton dimensions in %s.'], ...
            numel(significant),filePath);
    end
    p.axes = {dimensions(significant).Name};
    p.sz = [dimensions(significant).Length];
    p.units = get_attribute(si,'units');
    normalizedUnits = lower(strtrim(p.units));
    p.isKelvin = strcmp(normalizedUnits,'k') || ...
        contains(normalizedUnits,'kelvin');
    p.isCelsius = strcmp(normalizedUnits,'c') || ...
        contains(normalizedUnits,'celsius') || ...
        contains(normalizedUnits,'degree_c');
    if ~p.isKelvin && ~p.isCelsius
        error('SST units not recognized (%s) in %s.',p.units,filePath);
    end

    % Validate dimension mapping now, before scanning an entire full disk.
    validate_coordinate(info,p.lonVar,p.axes,filePath);
    validate_coordinate(info,p.latVar,p.axes,filePath);
end

function outName = find_named_variable(actual,candidates)
    outName = '';
    for k=1:numel(candidates)
        index = find(strcmpi(actual,candidates{k}),1,'first');
        if ~isempty(index)
            outName = actual{index};
            return;
        end
    end
end

function value = get_attribute(info,name)
    idx = find(strcmpi({info.Attributes.Name},name),1,'first');
    if isempty(idx)
        error('Missing required %s attribute in variable %s.',name,info.Name);
    end
    value = char(string(info.Attributes(idx).Value));
end

function validate_coordinate(ncInfo,varName,axes,filePath)
    vi = ncInfo.Variables(strcmp({ncInfo.Variables.Name},varName));
    dims = vi.Dimensions;
    active = {dims([dims.Length]>1).Name};
    if numel(active)==1
        okay = ismember(active{1},axes);
    elseif numel(active)==2
        okay = all(ismember(axes,active));
    else
        okay = false;
    end
    if ~okay
        error(['Coordinate field %s in %s has incompatible dimensions. ' ...
            'Inspect ncdisp before modifying the script.'],varName,filePath);
    end
end

function A = read_sst_celsius(p,firstColumn,width)
    A = read_spatial_tile(p,p.sstVar,firstColumn,width);
    if p.isKelvin
        A = A-273.15;
    end
    % Physical guard handles fill values left unmasked by some NetCDF files.
    A(~isfinite(A) | A < -2.5 | A > 45) = NaN;
end

function [lon,lat] = read_geolocation(p,firstColumn,width)
    lon = read_coordinate_tile(p,p.lonVar,firstColumn,width);
    lat = read_coordinate_tile(p,p.latVar,firstColumn,width);
end

function coord = read_coordinate_tile(p,name,firstColumn,width)
    ci = ncinfo(p.file,name);
    dims = ci.Dimensions;
    active = find([dims.Length]>1);
    if numel(active)==2
        coord = read_spatial_tile(p,name,firstColumn,width);
    elseif numel(active)==1
        vector = double(ncread(p.file,name));
        vector = vector(:);
        axisName = dims(active).Name;
        if strcmp(axisName,p.axes{1})
            if numel(vector)~=p.sz(1)
                error('Coordinate size mismatch in %s.',p.file);
            end
            coord = repmat(vector,1,width);
        elseif strcmp(axisName,p.axes{2})
            if numel(vector)~=p.sz(2)
                error('Coordinate size mismatch in %s.',p.file);
            end
            segment = vector(firstColumn:firstColumn+width-1);
            coord = repmat(segment.',p.sz(1),1);
        else
            error('Coordinate %s does not map to SST dimensions.',name);
        end
    else
        error('Unsupported coordinates for variable %s in %s.',name,p.file);
    end
end

function A = read_spatial_tile(p,name,firstColumn,width)
    vi = ncinfo(p.file,name);
    dims = vi.Dimensions;
    names = {dims.Name};
    first = find(strcmp(names,p.axes{1}));
    second = find(strcmp(names,p.axes{2}));
    if numel(first)~=1 || numel(second)~=1 || first==second
        error('Cannot map %s spatial axes in %s.',name,p.file);
    end
    other = setdiff(1:numel(dims),[first second]);
    if any([dims(other).Length]~=1)
        error('Non-singleton non-spatial dimension in %s.',name);
    end
    start = ones(1,numel(dims));
    count = [dims.Length];
    start(second) = firstColumn;
    count(second) = width;
    raw = ncread(p.file,name,start,count);
    raw = permute(raw,[first second other]);
    A = reshape(double(raw),[p.sz(1),width]);
end

function inside = inside_rectangle(lon,lat,box)
    tolerance = 1e-5;
    inside = isfinite(lon) & isfinite(lat) & ...
        lon >= box(1)-tolerance & lon <= box(2)+tolerance & ...
        lat >= box(3)-tolerance & lat <= box(4)+tolerance;
end
