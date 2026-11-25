function check_H08_H09_source_lineage()
% CHECK_H08_H09_SOURCE_LINEAGE
% Read-only audit for October and November 2022 SST source selection.
% MATLAB R2021a or newer; requires only built-in NetCDF/table functions.
%
% SAVE THIS FILE IN: 09_Transition_Sensitivity/
% RUN: check_H08_H09_source_lineage
%
% INPUTS (never modified):
%   ../02_Regional_Timeseries/regional_timeseries_raw.csv
%   ../02_Regional_Timeseries/regional_grid_check.csv
%   02_Comparison_Outputs/H08_H09_overlap_regional_comparison.csv
%   ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_202210.nc
%   ../01_SST_Rainfall_NTT_2016_2025/01_Crop_SST_NTT/sst_202211.nc
%
% OUTPUT (new, does not overwrite the study calculations):
%   04_Comparison/06_Crop_Source_Lineage_QC.csv
%
% This compares the CURRENT cropped NetCDF files against the saved study
% baseline and original-source overlap comparisons. It does not identify
% satellite provenance from metadata alone and is not an accuracy validation.

    root09 = fileparts(mfilename('fullpath'));
    if isempty(root09)
        error('Save check_H08_H09_source_lineage.m in 09_Transition_Sensitivity first.');
    end
    rootData = fileparts(root09);
    cropDir = fullfile(rootData,'01_SST_Rainfall_NTT_2016_2025','01_Crop_SST_NTT');
    rawFile = fullfile(rootData,'02_Regional_Timeseries','regional_timeseries_raw.csv');
    gridFile = fullfile(rootData,'02_Regional_Timeseries','regional_grid_check.csv');
    overlapFile = fullfile(root09,'02_Comparison_Outputs', ...
        'H08_H09_overlap_regional_comparison.csv');
    outDir = fullfile(root09,'04_Comparison');
    for f = {rawFile,gridFile,overlapFile}
        if ~isfile(f{1})
            error('Required input missing: %s',f{1});
        end
    end

    T = readtable(rawFile);
    G = readtable(gridFile);
    O = readtable(overlapFile);
    tRaw = local_dates(T.Time);
    tGrid = local_dates(G.Time);
    if height(T) ~= 120 || height(G) ~= 120 || ~isequal(tRaw,tGrid)
        error('Original Stage 02 input calendar is not a consistent 120-month series.');
    end
    regions = {'Flores','Sumba','Timor'};
    % Same geographic SST rectangles as a_extract_regional_timeseries.m.
    boxes = [119.0,123.5,-9.2,-7.9; ...
             118.8,121.2,-10.5,-9.2; ...
             123.3,126.0,-10.6,-8.6];
    tolerance = 1e-5; % Celsius, matching original Stage 09 overlap QC

    Month_YYYYMM = cell(6,1); Region = cell(6,1);
    Stage02_H08_reference_C = NaN(6,1);
    Overlap_H08_mean_C = NaN(6,1);
    Overlap_H09_mean_C = NaN(6,1);
    Cropped_SST_mean_C = NaN(6,1);
    Stage02_valid_cells = NaN(6,1);
    H08_overlap_valid_cells = NaN(6,1);
    H09_overlap_valid_cells = NaN(6,1);
    Cropped_valid_cells = NaN(6,1);
    Stage02_matches_H08 = false(6,1);
    Stage02_count_matches_H08 = false(6,1);
    Crop_matches_H08 = false(6,1);
    Crop_matches_H09 = false(6,1);
    Crop_file_present = false(6,1);
    Finding = cell(6,1);

    row = 0;
    for mm = 10:11
        fCrop = fullfile(cropDir,sprintf('sst_2022%02d.nc',mm));
        hasCrop = isfile(fCrop);
        if hasCrop
            lon = double(ncread(fCrop,'lon')); lon = lon(:);
            lat = double(ncread(fCrop,'lat')); lat = lat(:);
            units = char(ncreadatt(fCrop,'sst','units'));
            if ~contains(lower(units),'celsius')
                error('Crop unit is not degree Celsius: %s',fCrop);
            end
            Z = double(ncread(fCrop,'sst'));
            if numel(Z) ~= numel(lon)*numel(lat)
                error('Expected one SST field (lon x lat): %s',fCrop);
            end
            Z = reshape(Z,numel(lon),numel(lat));
            Z(~isfinite(Z) | abs(Z)>1e7) = NaN;
        end
        monthCode = sprintf('2022%02d',mm);
        timeRow = (year(tRaw)==2022 & month(tRaw)==mm);
        if nnz(timeRow)~=1
            error('Cannot uniquely select %s from Stage 02.',monthCode);
        end
        for ir = 1:3
            row = row+1;
            name = regions{ir};
            overlapRow = strcmp(string(O.Month_YYYYMM),string(monthCode)) & ...
                strcmp(string(O.Region),string(name));
            if nnz(overlapRow)~=1
                error('Cannot uniquely find overlap %s / %s.',monthCode,name);
            end
            o = O(overlapRow,:);
            sstValues = T.(['SST_' name '_C']);
            countValues = G.(['Valid_SST_' name]);
            baseline = double(sstValues(timeRow));
            baselineCount = double(countValues(timeRow));
            h08 = double(o.H08_mean_C);
            h09 = double(o.H09_mean_C);
            count08 = double(o.N_H08_valid);
            count09 = double(o.N_H09_valid);

            Month_YYYYMM{row} = monthCode;
            Region{row} = name;
            Stage02_H08_reference_C(row) = baseline;
            Overlap_H08_mean_C(row) = h08;
            Overlap_H09_mean_C(row) = h09;
            Stage02_valid_cells(row) = baselineCount;
            H08_overlap_valid_cells(row) = count08;
            H09_overlap_valid_cells(row) = count09;
            Stage02_matches_H08(row) = abs(baseline-h08)<tolerance;
            Stage02_count_matches_H08(row) = baselineCount==count08;
            Crop_file_present(row) = hasCrop;

            if hasCrop
                bx = boxes(ir,:);
                ix = find(lon>=bx(1)-1e-4 & lon<=bx(2)+1e-4);
                iy = find(lat>=bx(3)-1e-4 & lat<=bx(4)+1e-4);
                if isempty(ix) || isempty(iy)
                    error('Empty SST selection in cropped NetCDF: %s / %s',name,monthCode);
                end
                block = Z(ix,iy);
                vals = block(isfinite(block));
                if isempty(vals)
                    error('No valid SST pixels for %s / %s.',name,monthCode);
                end
                cropMean = mean(vals);
                Cropped_SST_mean_C(row) = cropMean;
                Cropped_valid_cells(row) = numel(vals);
                Crop_matches_H08(row) = abs(cropMean-h08)<tolerance && numel(vals)==count08;
                Crop_matches_H09(row) = abs(cropMean-h09)<tolerance && numel(vals)==count09;
            end

            if ~Stage02_matches_H08(row) || ~Stage02_count_matches_H08(row)
                Finding{row} = 'STAGE02_BASELINE_NOT_MATCHING_H08';
            elseif ~hasCrop
                Finding{row} = 'CROPPED_NETCDF_NOT_AVAILABLE';
            elseif Crop_matches_H08(row) && ~Crop_matches_H09(row)
                Finding{row} = 'CROP_MATCHES_H08_BASELINE';
            elseif Crop_matches_H09(row) && ~Crop_matches_H08(row)
                Finding{row} = 'CROP_MATCHES_H09_ALTERNATIVE';
            elseif Crop_matches_H08(row) && Crop_matches_H09(row)
                Finding{row} = 'CROP_AMBIGUOUS_BOTH_MATCH';
            else
                Finding{row} = 'CROP_MATCHES_NEITHER_SOURCE';
            end
        end
    end

    Result = table(Month_YYYYMM,Region,Stage02_H08_reference_C, ...
        Overlap_H08_mean_C,Overlap_H09_mean_C,Cropped_SST_mean_C, ...
        Stage02_valid_cells,H08_overlap_valid_cells,H09_overlap_valid_cells, ...
        Cropped_valid_cells,Stage02_matches_H08,Stage02_count_matches_H08, ...
        Crop_file_present,Crop_matches_H08,Crop_matches_H09,Finding);
    if ~isfolder(outDir), mkdir(outDir); end
    outFile = fullfile(outDir,'06_Crop_Source_Lineage_QC.csv');
    writetable(Result,outFile);

    fprintf('\n===== H08 / H09 STAGE-01 SOURCE LINEAGE =====\n');
    disp(Result(:,{'Month_YYYYMM','Region','Stage02_matches_H08', ...
        'Crop_matches_H08','Crop_matches_H09','Finding'}));
    fprintf('Stage 02 matches H08 for %d/6 records.\n', ...
        nnz(Stage02_matches_H08 & Stage02_count_matches_H08));
    fprintf('Current cropped NC matches H08 for %d/6; H09 for %d/6.\n', ...
        nnz(Crop_matches_H08),nnz(Crop_matches_H09));
    fprintf('Cropped NC found for %d/6 region-month checks.\n',nnz(Crop_file_present));
    fprintf('Saved: %s\n',outFile);
    fprintf('No original research file has been modified.\n');
    if ~all(Stage02_matches_H08 & Stage02_count_matches_H08)
        warning('Main baseline does not match source-overlap H08. STOP before modifying source selection.');
    elseif all(Crop_matches_H08)
        fprintf('PASS: saved Stage 02 and current cropped SST match H08 for both 2022 months.\n');
        fprintf('Align the source-selection rule in the GrADS script with this confirmed lineage.\n');
    elseif all(Crop_matches_H09)
        fprintf('Current cropped SST follows H09, while Stage 02 baseline follows H08.\n');
        fprintf('Do not overwrite Stage 02; regenerate only two H08 crops in a separate QC folder.\n');
    else
        fprintf('Cropping lineage NOT FULLY RESOLVED; inspect the row-wise findings.\n');
    end
end

function t = local_dates(x)
    if isdatetime(x)
        t = dateshift(x(:),'start','month');
    else
        t = datetime(string(x(:)), ...
            'InputFormat','dd-MMM-yyyy','Locale','en_US');
        t = dateshift(t,'start','month');
    end
end
