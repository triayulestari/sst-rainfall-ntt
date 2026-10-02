%% =========================================================
% 01_Extract_SST_Box_Variants.m
%
% FINAL VERSION
%
% SST BOX-SENSITIVITY EXTRACTION
%
% Regions:
%   Flores
%   Sumba
%   Timor
%
% SST box variants:
%
%   1. Shrink 0.2 degree
%   2. Shrink 0.1 degree
%   3. Baseline
%   4. Expand 0.1 degree
%   5. Expand 0.2 degree
%
% All perturbations are applied symmetrically to the
% four boundaries of each SST averaging box.
%
% Period:
%   January 2016 - December 2025
%
% Known missing SST files:
%   October 2025
%   November 2025
%
% Input folder:
%   ..\1a-SST_NTT
%
% Input files:
%   sst_YYYYMM.nc
%
% Outputs:
%
%   sst_box_variants_2016_2025.mat
%   sst_box_variants_monthly.csv
%   sst_box_variants_domain_QC.csv
%   sst_box_variants_valid_grid_QC.csv
%
% IMPORTANT:
%
% Baseline domains MUST exactly reproduce the main
% regional SST analysis:
%
%   Flores = 226 x 66  = 14916 rectangular grids
%   Sumba  = 121 x 66  =  7986 rectangular grids
%   Timor  = 136 x 101 = 13736 rectangular grids
%
% MATLAB R2021a
% No local functions.
%% =========================================================

clc;
clear;
close all;


%% =========================================================
% 1. BASIC SETTINGS
%% =========================================================

sst_folder = ...
    fullfile(...
    '..',...
    '1a-SST_NTT');


start_year = ...
    2016;


end_year = ...
    2025;


n_years = ...
    end_year - start_year + 1;


n_months_total = ...
    n_years * 12;


%% ---------------------------------------------------------
% Coordinate tolerance
%
% IMPORTANT:
%
% NetCDF coordinates may contain very small floating-point
% representation differences.
%
% 1e-4 degree is used consistently with the main regional
% extraction pipeline.
%% ---------------------------------------------------------

coord_tolerance = ...
    1e-4;


%% =========================================================
% 2. REGION DEFINITIONS
%
% Columns:
%
%   1 = lon_min
%   2 = lon_max
%   3 = lat_min
%   4 = lat_max
%
% These are the ORIGINAL SST domains used in the main
% analysis.
%% =========================================================

region_names = {...
    'Flores';...
    'Sumba';...
    'Timor'};


baseline_bounds = [...
    119.0   123.5   -9.2   -7.9;...
    118.8   121.2  -10.5   -9.2;...
    123.3   126.0  -10.6   -8.6];


n_regions = ...
    length(region_names);


%% =========================================================
% 3. BOX-VARIANT DEFINITIONS
%
% Negative values:
%   shrink inward
%
% Positive values:
%   expand outward
%% =========================================================

variant_names = {...
    'Shrink_0p2';...
    'Shrink_0p1';...
    'Baseline';...
    'Expand_0p1';...
    'Expand_0p2'};


variant_labels = {...
    'Shrink 0.2';...
    'Shrink 0.1';...
    'Baseline';...
    'Expand 0.1';...
    'Expand 0.2'};


perturbation = [...
    -0.2;...
    -0.1;...
     0.0;...
     0.1;...
     0.2];


n_variants = ...
    length(variant_names);


baseline_index = ...
    3;


%% =========================================================
% 4. BUILD REQUESTED BOX BOUNDS
%
% Dimensions:
%
%   region x variant x boundary
%
% Boundary order:
%
%   1 = lon_min
%   2 = lon_max
%   3 = lat_min
%   4 = lat_max
%% =========================================================

box_bounds = ...
    NaN(...
    n_regions,...
    n_variants,...
    4);


for rgn = 1:n_regions

    base_lon_min = ...
        baseline_bounds(rgn,1);


    base_lon_max = ...
        baseline_bounds(rgn,2);


    base_lat_min = ...
        baseline_bounds(rgn,3);


    base_lat_max = ...
        baseline_bounds(rgn,4);


    for v = 1:n_variants

        d = ...
            perturbation(v);


        if d < 0

            %% ---------------------------------------------
            % SHRINK DOMAIN
            %% ---------------------------------------------

            amount = ...
                abs(d);


            box_bounds(rgn,v,1) = ...
                base_lon_min + amount;


            box_bounds(rgn,v,2) = ...
                base_lon_max - amount;


            box_bounds(rgn,v,3) = ...
                base_lat_min + amount;


            box_bounds(rgn,v,4) = ...
                base_lat_max - amount;


        else

            %% ---------------------------------------------
            % BASELINE OR EXPAND DOMAIN
            %% ---------------------------------------------

            box_bounds(rgn,v,1) = ...
                base_lon_min - d;


            box_bounds(rgn,v,2) = ...
                base_lon_max + d;


            box_bounds(rgn,v,3) = ...
                base_lat_min - d;


            box_bounds(rgn,v,4) = ...
                base_lat_max + d;

        end

    end

end


%% =========================================================
% 5. PRINT REQUESTED BOX DEFINITIONS
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SST BOX-SENSITIVITY DEFINITIONS\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    fprintf(['Variant          Lon min    Lon max    ',...
             'Lat min    Lat max\n']);


    fprintf('--------------------------------------------------------\n');


    for v = 1:n_variants

        fprintf(...
            '%-14s   %7.2f    %7.2f    %7.2f    %7.2f\n',...
            variant_labels{v},...
            box_bounds(rgn,v,1),...
            box_bounds(rgn,v,2),...
            box_bounds(rgn,v,3),...
            box_bounds(rgn,v,4));

    end

end


%% =========================================================
% 6. FIND FIRST AVAILABLE SST FILE
%% =========================================================

first_file = '';


for Y = start_year:end_year

    for M = 1:12

        filename = ...
            sprintf(...
            'sst_%04d%02d.nc',...
            Y,...
            M);


        filepath = ...
            fullfile(...
            sst_folder,...
            filename);


        if exist(filepath,'file') == 2

            first_file = ...
                filepath;

            break

        end

    end


    if ~isempty(first_file)

        break

    end

end


if isempty(first_file)

    error(...
        'No SST NetCDF files were found in %s.',...
        sst_folder);

end


fprintf('\n')
fprintf('First available SST file:\n')

fprintf('%s\n',...
    first_file);


%% =========================================================
% 7. DETECT NETCDF VARIABLE NAMES
%% =========================================================

info = ...
    ncinfo(first_file);


nc_variable_names = ...
    {info.Variables.Name};


%% Longitude

if any(strcmp(nc_variable_names,'lon'))

    lon_name = ...
        'lon';


elseif any(strcmp(nc_variable_names,'longitude'))

    lon_name = ...
        'longitude';


else

    error(...
        'Longitude variable was not found.');

end


%% Latitude

if any(strcmp(nc_variable_names,'lat'))

    lat_name = ...
        'lat';


elseif any(strcmp(nc_variable_names,'latitude'))

    lat_name = ...
        'latitude';


else

    error(...
        'Latitude variable was not found.');

end


%% SST

if any(strcmp(nc_variable_names,'sst'))

    sst_name = ...
        'sst';


else

    error(...
        'SST variable "sst" was not found.');

end


fprintf('\n')
fprintf('Detected variables:\n')

fprintf('Longitude = %s\n',...
    lon_name);

fprintf('Latitude  = %s\n',...
    lat_name);

fprintf('SST       = %s\n',...
    sst_name);


%% =========================================================
% 8. READ MASTER SST GRID
%% =========================================================

lon = ...
    double(...
    ncread(...
    first_file,...
    lon_name));


lat = ...
    double(...
    ncread(...
    first_file,...
    lat_name));


lon = ...
    lon(:);


lat = ...
    lat(:);


%% =========================================================
% 9. MASTER GRID QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MASTER SST GRID\n')
fprintf('=========================================================\n')


fprintf('Longitude points = %d\n',...
    length(lon));


fprintf('Latitude points  = %d\n',...
    length(lat));


fprintf('Longitude range  = %.4f to %.4f\n',...
    min(lon),...
    max(lon));


fprintf('Latitude range   = %.4f to %.4f\n',...
    min(lat),...
    max(lat));


%% ---------------------------------------------------------
% Estimate native grid spacing
%% ---------------------------------------------------------

lon_step = ...
    median(...
    abs(diff(lon)),...
    'omitnan');


lat_step = ...
    median(...
    abs(diff(lat)),...
    'omitnan');


fprintf('Median lon spacing = %.6f degree\n',...
    lon_step);


fprintf('Median lat spacing = %.6f degree\n',...
    lat_step);


fprintf('Coordinate tolerance = %.1e degree\n',...
    coord_tolerance);


%% =========================================================
% 10. DOMAIN COVERAGE QC
%
% Make sure all expanded boxes remain inside the SST crop.
%% =========================================================

for rgn = 1:n_regions

    for v = 1:n_variants

        req_lon_min = ...
            box_bounds(rgn,v,1);


        req_lon_max = ...
            box_bounds(rgn,v,2);


        req_lat_min = ...
            box_bounds(rgn,v,3);


        req_lat_max = ...
            box_bounds(rgn,v,4);


        if ...
            req_lon_min < min(lon)-coord_tolerance || ...
            req_lon_max > max(lon)+coord_tolerance || ...
            req_lat_min < min(lat)-coord_tolerance || ...
            req_lat_max > max(lat)+coord_tolerance

            error(...
                ['Domain %s | %s exceeds ',...
                 'the available SST crop.'],...
                region_names{rgn},...
                variant_labels{v});

        end

    end

end


fprintf('\n')
fprintf('All box variants are inside the SST crop.\n');


%% =========================================================
% 11. SELECT GRID INDICES FOR EACH BOX
%% =========================================================

lon_indices = ...
    cell(...
    n_regions,...
    n_variants);


lat_indices = ...
    cell(...
    n_regions,...
    n_variants);


n_lon_grid = ...
    NaN(...
    n_regions,...
    n_variants);


n_lat_grid = ...
    NaN(...
    n_regions,...
    n_variants);


n_rect_grid = ...
    NaN(...
    n_regions,...
    n_variants);


actual_lon_min = ...
    NaN(...
    n_regions,...
    n_variants);


actual_lon_max = ...
    NaN(...
    n_regions,...
    n_variants);


actual_lat_min = ...
    NaN(...
    n_regions,...
    n_variants);


actual_lat_max = ...
    NaN(...
    n_regions,...
    n_variants);


for rgn = 1:n_regions

    for v = 1:n_variants

        req_lon_min = ...
            box_bounds(rgn,v,1);


        req_lon_max = ...
            box_bounds(rgn,v,2);


        req_lat_min = ...
            box_bounds(rgn,v,3);


        req_lat_max = ...
            box_bounds(rgn,v,4);


        %% -------------------------------------------------
        % IMPORTANT:
        % Coordinate tolerance prevents floating-point
        % coordinate values such as 121.199996 from being
        % incorrectly excluded from a 121.20 boundary.
        %% -------------------------------------------------

        idx_lon = ...
            find(...
            lon >= req_lon_min-coord_tolerance & ...
            lon <= req_lon_max+coord_tolerance);


        idx_lat = ...
            find(...
            lat >= req_lat_min-coord_tolerance & ...
            lat <= req_lat_max+coord_tolerance);


        if isempty(idx_lon)

            error(...
                'No longitude grids selected for %s | %s.',...
                region_names{rgn},...
                variant_labels{v});

        end


        if isempty(idx_lat)

            error(...
                'No latitude grids selected for %s | %s.',...
                region_names{rgn},...
                variant_labels{v});

        end


        lon_indices{rgn,v} = ...
            idx_lon;


        lat_indices{rgn,v} = ...
            idx_lat;


        n_lon_grid(rgn,v) = ...
            length(idx_lon);


        n_lat_grid(rgn,v) = ...
            length(idx_lat);


        n_rect_grid(rgn,v) = ...
            n_lon_grid(rgn,v) * ...
            n_lat_grid(rgn,v);


        actual_lon_min(rgn,v) = ...
            min(lon(idx_lon));


        actual_lon_max(rgn,v) = ...
            max(lon(idx_lon));


        actual_lat_min(rgn,v) = ...
            min(lat(idx_lat));


        actual_lat_max(rgn,v) = ...
            max(lat(idx_lat));

    end

end


%% =========================================================
% 12. PRINT GRID-SELECTION QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('GRID SELECTION QC\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    fprintf(['Variant        nLon   nLat   RectGrid   ',...
             'Actual Lon          Actual Lat\n']);


    fprintf(['------------------------------------------------',...
             '--------------------------\n']);


    for v = 1:n_variants

        fprintf(...
            ['%-13s   %4d   %4d   %8d   ',...
             '%6.2f-%6.2f   %6.2f-%6.2f\n'],...
            variant_labels{v},...
            n_lon_grid(rgn,v),...
            n_lat_grid(rgn,v),...
            n_rect_grid(rgn,v),...
            actual_lon_min(rgn,v),...
            actual_lon_max(rgn,v),...
            actual_lat_min(rgn,v),...
            actual_lat_max(rgn,v));

    end

end


%% =========================================================
% 13. HARD BASELINE GRID QC
%
% These counts MUST match the locked main SST analysis.
%% =========================================================

expected_baseline_nlon = [...
    226;...
    121;...
    136];


expected_baseline_nlat = [...
     66;...
     66;...
    101];


expected_baseline_rect = [...
    14916;...
     7986;...
    13736];


fprintf('\n')
fprintf('=========================================================\n')
fprintf('BASELINE GRID REPRODUCTION QC\n')
fprintf('=========================================================\n')


baseline_grid_qc_pass = ...
    true;


for rgn = 1:n_regions

    current_nlon = ...
        n_lon_grid(...
        rgn,...
        baseline_index);


    current_nlat = ...
        n_lat_grid(...
        rgn,...
        baseline_index);


    current_rect = ...
        n_rect_grid(...
        rgn,...
        baseline_index);


    fprintf('\n%s\n',...
        region_names{rgn});


    fprintf('Expected nLon     = %d\n',...
        expected_baseline_nlon(rgn));


    fprintf('Actual nLon       = %d\n',...
        current_nlon);


    fprintf('Expected nLat     = %d\n',...
        expected_baseline_nlat(rgn));


    fprintf('Actual nLat       = %d\n',...
        current_nlat);


    fprintf('Expected RectGrid = %d\n',...
        expected_baseline_rect(rgn));


    fprintf('Actual RectGrid   = %d\n',...
        current_rect);


    if ...
        current_nlon ~= expected_baseline_nlon(rgn) || ...
        current_nlat ~= expected_baseline_nlat(rgn) || ...
        current_rect ~= expected_baseline_rect(rgn)

        baseline_grid_qc_pass = ...
            false;


        fprintf('STATUS = FAILED\n');


    else

        fprintf('STATUS = PASSED\n');

    end

end


if ~baseline_grid_qc_pass

    error([...
        'BASELINE GRID QC FAILED. ',...
        'Do not continue with sensitivity analysis. ',...
        'Baseline boxes do not reproduce the main SST ',...
        'extraction domains.']);

end


fprintf('\n')
fprintf('All baseline grid counts reproduce the main analysis.\n');


%% =========================================================
% 14. CREATE MONTHLY TIME VECTOR
%% =========================================================

time = ...
    NaT(...
    n_months_total,...
    1);


Year = ...
    NaN(...
    n_months_total,...
    1);


Month = ...
    NaN(...
    n_months_total,...
    1);


counter = ...
    0;


for Y = start_year:end_year

    for M = 1:12

        counter = ...
            counter + 1;


        time(counter) = ...
            datetime(...
            Y,...
            M,...
            1);


        Year(counter) = ...
            Y;


        Month(counter) = ...
            M;

    end

end


%% =========================================================
% 15. PREALLOCATE SST TIME SERIES
%
% Dimensions:
%
%   time x variant x region
%% =========================================================

sst_variant = ...
    NaN(...
    n_months_total,...
    n_variants,...
    n_regions);


valid_grid_count = ...
    NaN(...
    n_months_total,...
    n_variants,...
    n_regions);


file_available = ...
    false(...
    n_months_total,...
    1);


%% =========================================================
% 16. READ MONTHLY SST FILES
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('READING MONTHLY SST FILES\n')
fprintf('=========================================================\n')


for t = 1:n_months_total

    Y = ...
        Year(t);


    M = ...
        Month(t);


    filename = ...
        sprintf(...
        'sst_%04d%02d.nc',...
        Y,...
        M);


    filepath = ...
        fullfile(...
        sst_folder,...
        filename);


    %% -----------------------------------------------------
    % Missing SST file
    %% -----------------------------------------------------

    if exist(filepath,'file') ~= 2

        fprintf(...
            'Missing file: %s\n',...
            filename);

        continue

    end


    file_available(t) = ...
        true;


    %% -----------------------------------------------------
    % Read SST data
    %% -----------------------------------------------------

    sst_raw = ...
        double(...
        ncread(...
        filepath,...
        sst_name));


    sst_raw = ...
        squeeze(...
        sst_raw);


    %% -----------------------------------------------------
    % Determine data orientation
    %
    % Desired:
    %
    % rows    = longitude
    % columns = latitude
    %% -----------------------------------------------------

    sz = ...
        size(sst_raw);


    if ...
        sz(1) == length(lon) && ...
        sz(2) == length(lat)

        sst_data = ...
            sst_raw;


    elseif ...
        sz(1) == length(lat) && ...
        sz(2) == length(lon)

        sst_data = ...
            sst_raw';


    else

        error(...
            ['Unexpected SST matrix size in %s. ',...
             'Expected lon x lat or lat x lon.'],...
            filename);

    end


    %% -----------------------------------------------------
    % Extract regional means for all box variants
    %% -----------------------------------------------------

    for rgn = 1:n_regions

        for v = 1:n_variants

            idx_lon = ...
                lon_indices{rgn,v};


            idx_lat = ...
                lat_indices{rgn,v};


            subset = ...
                sst_data(...
                idx_lon,...
                idx_lat);


            valid_values = ...
                subset(...
                ~isnan(subset));


            valid_grid_count(t,v,rgn) = ...
                length(valid_values);


            if ~isempty(valid_values)

                sst_variant(t,v,rgn) = ...
                    mean(valid_values);

            end

        end

    end


    %% -----------------------------------------------------
    % Progress report
    %% -----------------------------------------------------

    if M == 12

        fprintf(...
            'Completed through %s\n',...
            datestr(...
            time(t),...
            'mmm-yyyy'));

    end

end


%% =========================================================
% 17. MONTHLY FILE AVAILABILITY QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('MONTHLY SST VALIDITY QC\n')
fprintf('=========================================================\n')


fprintf('Expected months      = %d\n',...
    n_months_total);


fprintf('Available SST files  = %d / %d\n',...
    sum(file_available),...
    n_months_total);


fprintf('Missing SST files    = %d\n',...
    sum(~file_available));


if any(~file_available)

    fprintf('\nMissing file months:\n');


    missing_idx = ...
        find(~file_available);


    for i = 1:length(missing_idx)

        fprintf(...
            '%s\n',...
            datestr(...
            time(missing_idx(i)),...
            'mmm-yyyy'));

    end

end


%% =========================================================
% 18. EXPECTED MISSING-MONTH QC
%
% The pipeline expects only:
%
%   Oct 2025
%   Nov 2025
%% =========================================================

expected_missing = ...
    false(...
    n_months_total,...
    1);


expected_missing(...
    year(time)==2025 & ...
    month(time)==10) = ...
    true;


expected_missing(...
    year(time)==2025 & ...
    month(time)==11) = ...
    true;


if ~isequal(...
        ~file_available,...
        expected_missing)

    warning([...
        'Actual missing SST months differ from the ',...
        'expected Oct-Nov 2025 pattern.']);

else

    fprintf('\n')
    fprintf(['Missing-month QC PASSED: ',...
             'only Oct-Nov 2025 are absent.\n']);

end


%% =========================================================
% 19. VALID MONTH COUNTS BY REGION / VARIANT
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID MONTHS BY REGION AND VARIANT\n')
fprintf('=========================================================\n')


valid_month_count = ...
    NaN(...
    n_regions,...
    n_variants);


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        valid_month_count(rgn,v) = ...
            sum(...
            ~isnan(...
            sst_variant(:,v,rgn)));


        fprintf(...
            '%-13s = %d / %d\n',...
            variant_labels{v},...
            valid_month_count(rgn,v),...
            n_months_total);

    end

end


%% =========================================================
% 20. HARD VALID-MONTH QC
%
% All variants should contain 118 valid months.
%% =========================================================

if any(valid_month_count(:) ~= 118)

    error([...
        'At least one SST box variant does not have ',...
        '118 valid months. Check the extraction.']);

end


fprintf('\n')
fprintf('All regional box variants contain 118 / 120 valid months.\n');


%% =========================================================
% 21. VALID SST GRID-COUNT QC
%% =========================================================

valid_grid_min = ...
    NaN(...
    n_regions,...
    n_variants);


valid_grid_mean = ...
    NaN(...
    n_regions,...
    n_variants);


valid_grid_max = ...
    NaN(...
    n_regions,...
    n_variants);


for rgn = 1:n_regions

    for v = 1:n_variants

        grid_series = ...
            valid_grid_count(...
            :,v,rgn);


        valid_grid_min(rgn,v) = ...
            min(...
            grid_series,...
            [],...
            'omitnan');


        valid_grid_mean(rgn,v) = ...
            mean(...
            grid_series,...
            'omitnan');


        valid_grid_max(rgn,v) = ...
            max(...
            grid_series,...
            [],...
            'omitnan');

    end

end


fprintf('\n')
fprintf('=========================================================\n')
fprintf('VALID SST GRID COUNTS\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    fprintf(['Variant          Min       Mean       Max       ',...
             'Rectangular\n']);


    fprintf('----------------------------------------------------------\n');


    for v = 1:n_variants

        fprintf(...
            '%-13s   %7.0f   %9.1f   %7.0f   %10.0f\n',...
            variant_labels{v},...
            valid_grid_min(rgn,v),...
            valid_grid_mean(rgn,v),...
            valid_grid_max(rgn,v),...
            n_rect_grid(rgn,v));

    end

end


%% =========================================================
% 22. SST TIME-SERIES RANGE QC
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SST TIME-SERIES RANGE QC\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    fprintf('\n%s\n',...
        upper(region_names{rgn}));


    for v = 1:n_variants

        tmp = ...
            sst_variant(:,v,rgn);


        fprintf(...
            '%-13s = %.3f to %.3f C\n',...
            variant_labels{v},...
            min(...
            tmp,...
            [],...
            'omitnan'),...
            max(...
            tmp,...
            [],...
            'omitnan'));

    end

end


%% =========================================================
% 23. BASELINE VARIANT SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('BASELINE VARIANT SUMMARY\n')
fprintf('=========================================================\n')


for rgn = 1:n_regions

    tmp = ...
        sst_variant(...
        :,baseline_index,rgn);


    fprintf('\n%s\n',...
        region_names{rgn});


    fprintf('Valid months = %d / 120\n',...
        sum(~isnan(tmp)));


    fprintf('Mean SST     = %.4f C\n',...
        mean(...
        tmp,...
        'omitnan'));


    fprintf('nLon         = %d\n',...
        n_lon_grid(...
        rgn,...
        baseline_index));


    fprintf('nLat         = %d\n',...
        n_lat_grid(...
        rgn,...
        baseline_index));


    fprintf('RectGrid     = %d\n',...
        n_rect_grid(...
        rgn,...
        baseline_index));


    fprintf('Valid grid min  = %.0f\n',...
        valid_grid_min(...
        rgn,...
        baseline_index));


    fprintf('Valid grid mean = %.1f\n',...
        valid_grid_mean(...
        rgn,...
        baseline_index));


    fprintf('Valid grid max  = %.0f\n',...
        valid_grid_max(...
        rgn,...
        baseline_index));

end


%% =========================================================
% 24. CREATE MONTHLY SST OUTPUT TABLE
%% =========================================================

MonthlyTable = ...
    table(...
    time,...
    Year,...
    Month);


for rgn = 1:n_regions

    for v = 1:n_variants

        variable_name = ...
            sprintf(...
            'SST_%s_%s',...
            region_names{rgn},...
            variant_names{v});


        MonthlyTable.(variable_name) = ...
            sst_variant(...
            :,v,rgn);

    end

end


%% =========================================================
% 25. CREATE DOMAIN QC TABLE
%% =========================================================

n_rows = ...
    n_regions * ...
    n_variants;


QC_Region = ...
    cell(...
    n_rows,...
    1);


QC_Variant = ...
    cell(...
    n_rows,...
    1);


QC_Perturbation_deg = ...
    NaN(...
    n_rows,...
    1);


Requested_lon_min = ...
    NaN(...
    n_rows,...
    1);


Requested_lon_max = ...
    NaN(...
    n_rows,...
    1);


Requested_lat_min = ...
    NaN(...
    n_rows,...
    1);


Requested_lat_max = ...
    NaN(...
    n_rows,...
    1);


Actual_lon_min = ...
    NaN(...
    n_rows,...
    1);


Actual_lon_max = ...
    NaN(...
    n_rows,...
    1);


Actual_lat_min = ...
    NaN(...
    n_rows,...
    1);


Actual_lat_max = ...
    NaN(...
    n_rows,...
    1);


N_lon = ...
    NaN(...
    n_rows,...
    1);


N_lat = ...
    NaN(...
    n_rows,...
    1);


Rectangular_grid_count = ...
    NaN(...
    n_rows,...
    1);


Valid_grid_min = ...
    NaN(...
    n_rows,...
    1);


Valid_grid_mean = ...
    NaN(...
    n_rows,...
    1);


Valid_grid_max = ...
    NaN(...
    n_rows,...
    1);


Valid_months = ...
    NaN(...
    n_rows,...
    1);


row_counter = ...
    0;


for rgn = 1:n_regions

    for v = 1:n_variants

        row_counter = ...
            row_counter + 1;


        QC_Region{row_counter} = ...
            region_names{rgn};


        QC_Variant{row_counter} = ...
            variant_labels{v};


        QC_Perturbation_deg(row_counter) = ...
            perturbation(v);


        Requested_lon_min(row_counter) = ...
            box_bounds(rgn,v,1);


        Requested_lon_max(row_counter) = ...
            box_bounds(rgn,v,2);


        Requested_lat_min(row_counter) = ...
            box_bounds(rgn,v,3);


        Requested_lat_max(row_counter) = ...
            box_bounds(rgn,v,4);


        Actual_lon_min(row_counter) = ...
            actual_lon_min(rgn,v);


        Actual_lon_max(row_counter) = ...
            actual_lon_max(rgn,v);


        Actual_lat_min(row_counter) = ...
            actual_lat_min(rgn,v);


        Actual_lat_max(row_counter) = ...
            actual_lat_max(rgn,v);


        N_lon(row_counter) = ...
            n_lon_grid(rgn,v);


        N_lat(row_counter) = ...
            n_lat_grid(rgn,v);


        Rectangular_grid_count(row_counter) = ...
            n_rect_grid(rgn,v);


        Valid_grid_min(row_counter) = ...
            valid_grid_min(rgn,v);


        Valid_grid_mean(row_counter) = ...
            valid_grid_mean(rgn,v);


        Valid_grid_max(row_counter) = ...
            valid_grid_max(rgn,v);


        Valid_months(row_counter) = ...
            valid_month_count(rgn,v);

    end

end


DomainQCTable = ...
    table(...
    QC_Region,...
    QC_Variant,...
    QC_Perturbation_deg,...
    Requested_lon_min,...
    Requested_lon_max,...
    Requested_lat_min,...
    Requested_lat_max,...
    Actual_lon_min,...
    Actual_lon_max,...
    Actual_lat_min,...
    Actual_lat_max,...
    N_lon,...
    N_lat,...
    Rectangular_grid_count,...
    Valid_grid_min,...
    Valid_grid_mean,...
    Valid_grid_max,...
    Valid_months);


%% =========================================================
% 26. CREATE MONTHLY VALID-GRID TABLE
%% =========================================================

ValidGridTable = ...
    table(...
    time,...
    Year,...
    Month);


for rgn = 1:n_regions

    for v = 1:n_variants

        variable_name = ...
            sprintf(...
            'ValidGrid_%s_%s',...
            region_names{rgn},...
            variant_names{v});


        ValidGridTable.(variable_name) = ...
            valid_grid_count(...
            :,v,rgn);

    end

end


%% =========================================================
% 27. SAVE MAT FILE
%% =========================================================

save(...
    'sst_box_variants_2016_2025.mat',...
    'time',...
    'Year',...
    'Month',...
    'lon',...
    'lat',...
    'region_names',...
    'variant_names',...
    'variant_labels',...
    'perturbation',...
    'baseline_index',...
    'baseline_bounds',...
    'box_bounds',...
    'actual_lon_min',...
    'actual_lon_max',...
    'actual_lat_min',...
    'actual_lat_max',...
    'lon_indices',...
    'lat_indices',...
    'n_lon_grid',...
    'n_lat_grid',...
    'n_rect_grid',...
    'sst_variant',...
    'valid_grid_count',...
    'valid_grid_min',...
    'valid_grid_mean',...
    'valid_grid_max',...
    'valid_month_count',...
    'file_available',...
    'coord_tolerance',...
    'MonthlyTable',...
    'DomainQCTable',...
    'ValidGridTable');


%% =========================================================
% 28. SAVE CSV FILES
%% =========================================================

writetable(...
    MonthlyTable,...
    'sst_box_variants_monthly.csv');


writetable(...
    DomainQCTable,...
    'sst_box_variants_domain_QC.csv');


writetable(...
    ValidGridTable,...
    'sst_box_variants_valid_grid_QC.csv');


%% =========================================================
% 29. FINAL QC SUMMARY
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('FINAL EXTRACTION QC\n')
fprintf('=========================================================\n')


fprintf('\nBaseline rectangular grid counts:\n');


for rgn = 1:n_regions

    fprintf('%-8s = %d\n',...
        region_names{rgn},...
        n_rect_grid(...
        rgn,...
        baseline_index));

end


fprintf('\nExpected:\n');

fprintf('Flores = 14916\n');

fprintf('Sumba  = 7986\n');

fprintf('Timor  = 13736\n');


fprintf('\nValid SST months:\n');

fprintf('All 15 region-variant combinations = 118 / 120\n');


fprintf('\nMissing months:\n');

fprintf('Oct-2025\n');

fprintf('Nov-2025\n');


%% =========================================================
% 30. FINAL MESSAGE
%% =========================================================

fprintf('\n')
fprintf('=========================================================\n')
fprintf('SST BOX-VARIANT EXTRACTION COMPLETED\n')
fprintf('=========================================================\n')


fprintf('\nFiles saved:\n');

fprintf('1. sst_box_variants_2016_2025.mat\n');

fprintf('2. sst_box_variants_monthly.csv\n');

fprintf('3. sst_box_variants_domain_QC.csv\n');

fprintf('4. sst_box_variants_valid_grid_QC.csv\n');


fprintf('\nMethodological note:\n');

fprintf(['The Baseline variant exactly reproduces the SST ',...
         'averaging domains used in the main analysis.\n']);


fprintf(['Shrink and Expand variants modify all four box ',...
         'boundaries symmetrically by 0.1 or 0.2 degree.\n']);


fprintf(['Only the SST averaging domain is perturbed; ',...
         'the rainfall domain remains unchanged.\n']);


fprintf('\nNext step:\n');

fprintf(['02_Deseasonalize_Box_Variants.m will calculate ',...
         'a separate monthly SST climatology and anomaly ',...
         'series for every region-box combination.\n']);