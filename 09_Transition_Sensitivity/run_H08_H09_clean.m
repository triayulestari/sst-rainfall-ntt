function run_H08_H09_clean()
% ========================================================================
% CLEAN H08-H09 OCT-NOV 2022 SOURCE-TRANSITION SENSITIVITY PIPELINE
% MATLAB R2021a+ | Statistics and Machine Learning Toolbox
%
% Put this file in Data/09_Transition_Sensitivity and run:
%   run_H08_H09_clean
%
% EDIT ONLY THIS SETTING if you want to stop after seasonal analyses:
%   maxStage = 4;    % 2,3,4,5,6,7 allowed
% Default 7 runs all scientifically valid stages supported by the inputs.
%
% NEVER deletes files. NEVER writes to Data/01...Data/08.
% Folder 01_SST_H08_H09_Overlap_202210_202211 is READ ONLY.
% H08 and H09 results are recomputed independently using original scripts.
% Stage 07a/07b excluded: require source-specific SST NetCDF crop series.
% ========================================================================

    maxStage = 7;  % First pass: review monthly and seasonal results before Stage 05-07
    if ~ismember(maxStage,2:7)
        error('maxStage must be an integer from 2 to 7.');
    end
    thisFile = mfilename('fullpath');
    assert(~isempty(thisFile),'Save this file before running.');
    root09 = fileparts(thisFile);
    dataRoot = fileparts(root09);
    oldPath=path;
    addpath(root09,'-begin');
    pathCleaner=onCleanup(@()path(oldPath));
    inputOverlap = fullfile(root09,'01_SST_H08_H09_Overlap_202210_202211');
    outputOverlap = fullfile(root09,'02_Comparison_Outputs');
    scenarioRoot = fullfile(root09,'03_Scenarios');
    scriptRoot = fullfile(root09,'00_Original_Methods');
    scenarioNames = {'H08_Final','H09_Alternative'};

    % One authoritative ordered list of original methods and their outputs.
    % Stage 02 includes anomaly calculation; Stage 03 is monthly/lagged.
    tasks = { ...
      2,'02_Regional_Timeseries','b_compute_regional_anomalies.m', ...
        {'regional_calendar_month_means.csv','regional_anomalies.csv','regional_detrending_summary.csv','regional_anomalies.mat'}; ...
      3,'03_Monthly_and_Lagged','a_monthly_zero_lag.m', ...
        {'monthly_zero_lag_correlation.csv','monthly_zero_lag_correlation.mat'}; ...
      3,'03_Monthly_and_Lagged','b_autocorrelation_effective_n.m', ...
        {'autocorrelation_effectiveN.csv','autocorrelation_effectiveN.mat'}; ...
      3,'03_Monthly_and_Lagged','c_lagged_correlation.m', ...
        {'lagged_correlation_results.csv','lagged_correlation_results.mat'}; ...
      4,'04_Seasonal_Analysis','a_seasonal_mean_anomalies.m', ...
        {'seasonal_mean_anomalies.csv','seasonal_mean_anomalies.mat'}; ...
      4,'04_Seasonal_Analysis','b_seasonal_correlation.m', ...
        {'seasonal_correlation_basic.csv','seasonal_correlation_basic.mat'}; ...
      4,'04_Seasonal_Analysis','c_seasonal_robustness.m', ...
        {'seasonal_robustness_results.csv','seasonal_robustness_results.mat','seasonal_LOYO_results.csv'}; ...
      4,'04_Seasonal_Analysis','d_check_seasonal_annual_dependence.m', ...
        {'seasonal_annual_dependence_QC.csv','seasonal_annual_dependence_QC.mat','seasonal_adjacent_year_pairs.csv'}; ...
      4,'04_Seasonal_Analysis','e_compile_seasonal_uncertainty.m', ...
        {'seasonal_uncertainty_summary.csv'}; ...
      5,'05_Spatial_Analysis','b_spatial_correlation_fdr.m', ...
        {'spatial_correlation_results.mat','spatial_correlation_summary.csv','spatial_correlation_grid_results.csv'}; ...
      6,'06_Climate_Mode_Sensitivity','a_prepare_climate_indices.m', ...
        {'climate_indices_2016_2025.mat','climate_indices_monthly.csv','climate_indices_seasonal.csv','climate_indices_QC.csv'}; ...
      6,'06_Climate_Mode_Sensitivity','b_seasonal_partial_correlation.m', ...
        {'seasonal_partial_correlation_results.csv','seasonal_partial_correlation_results.mat','seasonal_partial_correlation_QC.csv'}; ...
      6,'06_Climate_Mode_Sensitivity','c_seasonal_partial_robustness.m', ...
        {'seasonal_partial_robustness_results.csv','seasonal_partial_robustness_results.mat', ...
         'seasonal_partial_LOYO_results.csv','seasonal_partial_permutation_QC.csv'}; ...
      6,'06_Climate_Mode_Sensitivity','d_check_partial_uncertainty_dependence.m', ...
        {'partial_uncertainty_dependence_summary.csv','partial_residual_adjacent_year_pairs.csv'}; ...
      7,'07_Robustness_Tests','c_seasonal_detrend_missing2025.m', ...
        {'seasonal_detrend_sensitivity.csv','seasonal_exclude2025_sensitivity.csv','JJA_rainfall_magnitude.csv'}; ...
      7,'07_Robustness_Tests','d_spatial_coarsegrid_sensitivity.m', ...
        {'spatial_coarse010_summary.csv','spatial_coarse010_grid_results.csv','spatial_coarse010_results.mat'} ...
    };

    %% 0. PRE-FLIGHT: validate every dependency BEFORE doing any work.
    fprintf('\n===== PRE-FLIGHT H08/H09 CLEAN PIPELINE =====\n');
    assert(isfolder(inputOverlap), ...
        'Missing protected raw overlap folder: %s',inputOverlap);
    for month = {'202210','202211'}
        for satellite = {'H08','H09'}
            pat = sprintf('%s_%s01_0000_1MSST*.nc',satellite{1},month{1});
            matches = dir(fullfile(inputOverlap,pat));
            assert(numel(matches)==1,'Expected exactly one %s in %s.',pat,inputOverlap);
        end
    end
    mustHave = { ...
        fullfile(dataRoot,'02_Regional_Timeseries','regional_timeseries_raw.mat'), ...
        fullfile(dataRoot,'02_Regional_Timeseries','regional_timeseries_raw.csv'), ...
        fullfile(dataRoot,'02_Regional_Timeseries','regional_grid_check.csv'), ...
        fullfile(dataRoot,'02_Regional_Timeseries','regional_anomalies.mat'), ...
        fullfile(root09,'a_compare_h08_h09_overlap.m'), ...
        fullfile(root09,'b_prepare_h09_scenario.m'), ...
        fullfile(root09,'z_compare_scenarios.m')};
    if maxStage>=5
        mustHave{end+1} = fullfile(dataRoot,'05_Spatial_Analysis','spatial_rainfall_anomaly.mat');
    end
    if maxStage>=6
        mustHave{end+1} = fullfile(dataRoot,'06_Climate_Mode_Sensitivity', ...
            'climate_indices_input_2016_2025.csv');
    end
    for k=1:size(tasks,1)
        if tasks{k,1}<=maxStage
            mustHave{end+1} = fullfile(scriptRoot,tasks{k,2},tasks{k,3});
        end
    end
    for k=1:numel(mustHave)
        assert(isfile(mustHave{k}),'Required source is missing: %s',mustHave{k});
    end
    fprintf('Pre-flight PASS: all inputs for maxStage=%d exist.\n',maxStage);
    fprintf('No original Data folders or overlap NetCDF files will be modified.\n');

    logDir = fullfile(root09,'05_Run_Logs');
    ensure_folder(logDir);
    logFile = fullfile(logDir,['run_' datestr(now,'yyyymmdd_HHMMSS') '.txt']);
    diary(logFile);
    logCleaner = onCleanup(@()diary('off'));
    fprintf('\n===== CLEAN TRANSITION SENSITIVITY START =====\n');
    fprintf('Original Data root : %s\n',dataRoot);
    fprintf('Sensitivity folder : %s\n',root09);
    fprintf('Maximum stage      : %d\n',maxStage);
    fprintf('Delta convention   : H09 - H08\n');

    %% 1. Independent raw H08/H09 source comparison.
    overlapOutputs = { ...
        'H08_H09_overlap_regional_comparison.csv', ...
        'H08_H09_overlap_source_inventory.csv', ...
        'H08_H09_overlap_comparison.png', ...
        'H08_H09_overlap_methods.txt'};
    run_once(fullfile(root09,'a_compare_h08_h09_overlap.m'), ...
        outputOverlap,overlapOutputs,'01 / Source overlap');

    %% 2. Prepare controlled raw regional SST/CHIRPS scenarios.
    rawNames = {'regional_timeseries_raw.csv','regional_timeseries_raw.mat', ...
        'regional_grid_check.csv'};
    rawPresent = false(2,numel(rawNames));
    for i=1:2
        for j=1:numel(rawNames)
            rawPresent(i,j) = isfile(fullfile(scenarioRoot,scenarioNames{i}, ...
                '02_Regional_Timeseries',rawNames{j}));
        end
    end
    if all(rawPresent(:))
        fprintf('SKIP 02 / Both raw regional scenarios already exist.\n');
    elseif any(rawPresent(:))
        error(['PARTIAL raw scenario outputs found. Archive or remove ' ...
            '03_Scenarios before restarting (never remove Folder 01).']);
    else
        fprintf('\nRUN 02 / Prepare H08_Final and H09_Alternative raw inputs\n');
        execute_script(fullfile(root09,'b_prepare_h09_scenario.m'));
        for i=1:2
            for j=1:numel(rawNames)
                assert(isfile(fullfile(scenarioRoot,scenarioNames{i}, ...
                    '02_Regional_Timeseries',rawNames{j})), ...
                    'Missing scenario raw output after preparation.');
            end
        end
    end

    %% 3. Run original scientific algorithms, isolated by stage and scenario.
    for k=1:size(tasks,1)
        stage = tasks{k,1};
        if stage>maxStage, continue; end
        subfolder = tasks{k,2};
        filename = tasks{k,3};
        outputs = tasks{k,4};
        for i=1:2
            destDir = fullfile(scenarioRoot,scenarioNames{i},subfolder);
            ensure_folder(destDir);
            originalScript = fullfile(scriptRoot,subfolder,filename);
            localScript = fullfile(destDir,filename);
            safe_copy(originalScript,localScript);
            if stage==5
                shared = fullfile(dataRoot,'05_Spatial_Analysis');
                spatial = fullfile(shared,'spatial_rainfall_anomaly.mat');
                regional = fullfile(scenarioRoot,scenarioNames{i}, ...
                    '02_Regional_Timeseries','regional_anomalies.mat');
                verify_spatial_calendar(spatial,regional);
                sharedNames = {'spatial_rainfall_anomaly.mat', ...
                    'spatial_rainfall_grid_QC.csv','spatial_rainfall_monthly_QC.csv', ...
                    'spatial_valid_grid_mask.csv'};
                for j=1:numel(sharedNames)
                    src = fullfile(shared,sharedNames{j});
                    if isfile(src)
                        safe_copy(src,fullfile(destDir,sharedNames{j}));
                    end
                end
            end
            if stage==6
                indexSrc = fullfile(dataRoot,'06_Climate_Mode_Sensitivity', ...
                    'climate_indices_input_2016_2025.csv');
                safe_copy(indexSrc,fullfile(destDir, ...
                    'climate_indices_input_2016_2025.csv'));
            end
            label = sprintf('Stage %02d / %s / %s',stage,scenarioNames{i},filename);
            run_once(localScript,destDir,outputs,label);
        end
        if stage==2
            verify_scenario_lineage(dataRoot,scenarioRoot);
        end
    end
    verify_scenario_lineage(dataRoot,scenarioRoot);

    %% 4. Recompute comparison from CURRENT scenario outputs automatically.
    fprintf('\n===== BUILDING CURRENT H08/H09 COMPARISON =====\n');
    z_compare_scenarios(maxStage);
    fprintf('\n===== PIPELINE FINISHED THROUGH STAGE %02d =====\n',maxStage);
    fprintf('Comparison results: %s\n',fullfile(root09,'04_Comparison'));
    fprintf('Log: %s\n',logFile);
    fprintf(['Stage 07a/07b are NOT included; their original SST NetCDF input ' ...
        'must be source-switched spatially before a valid H08/H09 comparison.\n']);
    clear logCleaner;
    clear pathCleaner;
end

function run_once(scriptPath,outDir,outputs,label)
    present = false(numel(outputs),1);
    for j=1:numel(outputs)
        present(j) = isfile(fullfile(outDir,outputs{j}));
    end
    if all(present)
        fprintf('SKIP completed: %s\n',label);
        return;
    end
    if any(present)
        error('PARTIAL outputs for %s. Resolve before rerunning. Folder: %s', ...
            label,outDir);
    end
    fprintf('\nRUN: %s\n',label);
    execute_script(scriptPath);
    for j=1:numel(outputs)
        assert(isfile(fullfile(outDir,outputs{j})), ...
            'Script finished but output is missing: %s',fullfile(outDir,outputs{j}));
    end
    fprintf('PASS: %s\n',label);
end

function execute_script(scriptPath)
    assert(isfile(scriptPath),'MATLAB script missing: %s',scriptPath);
    % Original scripts use clc/clear; run them in the base workspace so the
    % function orchestrator cannot be cleared by those statements.
    cmd = sprintf('run(''%s'');',strrep(scriptPath,'''',''''''));
    evalin('base',cmd);
end

function verify_spatial_calendar(spatialFile,regionalFile)
    G=load(spatialFile,'time');
    D=load(regionalFile,'time');
    assert(isfield(G,'time') && isfield(D,'time') && ...
        isequal(G.time(:),D.time(:)), ...
        'Shared spatial CHIRPS timeline differs from scenario regional timeline.');
end

function verify_scenario_lineage(dataRoot,scenarioRoot)
    names={'H08_Final','H09_Alternative'};
    D=cell(1,2);
    expected = datetime(2016,1,1)+calmonths((0:119)');
    missing2025 = year(expected)==2025 & ismember(month(expected),[10 11]);
    switch2022 = year(expected)==2022 & ismember(month(expected),[10 11]);
    fields={'SST','RAIN','SST_deseason','RAIN_deseason', ...
        'SST_deseason_detrended','RAIN_deseason_detrended'};
    for i=1:2
        file = fullfile(scenarioRoot,names{i}, ...
            '02_Regional_Timeseries','regional_anomalies.mat');
        assert(isfile(file),'Scenario anomaly file missing: %s',file);
        D{i}=load(file);
        assert(isfield(D{i},'time') && isequal(D{i}.time(:),expected), ...
            'Unexpected scenario monthly timeline.');
        for j=1:numel(fields)
            assert(isfield(D{i},fields{j}) && ...
                isequal(size(D{i}.(fields{j})),[120 3]), ...
                'Missing/wrong variable %s in %s.',fields{j},names{i});
        end
        assert(all(all(isnan(D{i}.SST(missing2025,:)))) && ...
            all(all(isfinite(D{i}.SST(~missing2025,:)))) && ...
            all(isfinite(D{i}.RAIN(:))), ...
            'Unexpected SST missing pattern or CHIRPS gap in %s.',names{i});
    end
    A=D{1}; B=D{2};
    assert(isequaln(A.RAIN,B.RAIN) && ...
        isequaln(A.RAIN_deseason,B.RAIN_deseason) && ...
        isequaln(A.RAIN_deseason_detrended,B.RAIN_deseason_detrended), ...
        'CONTROLLED INPUT FAILED: rainfall changes between scenarios.');
    assert(isequaln(A.SST(~switch2022,:),B.SST(~switch2022,:)), ...
        'CONTROLLED INPUT FAILED: SST differs outside Oct-Nov 2022.');
    assert(nnz(abs(B.SST(switch2022,:)-A.SST(switch2022,:))>1e-10)==6, ...
        'Expected exactly 6 SST changes (3 regions x 2 months).');
    orig = load(fullfile(dataRoot,'02_Regional_Timeseries', ...
        'regional_anomalies.mat'));
    for j=1:numel(fields)
        x=A.(fields{j}); y=orig.(fields{j});
        assert(isequal(size(x),size(y)),'Original baseline size mismatch.');
        bothFinite=isfinite(x)&isfinite(y);
        sameMissing=isnan(x)&isnan(y);
        assert(all(sameMissing(:)|bothFinite(:)) && ...
            all(abs(x(bothFinite)-y(bothFinite))<1e-8), ...
            'H08 baseline differs from original research for %s.',fields{j});
    end
    fprintf(['LINEAGE QC PASS: H08 matches original to 1e-8; ' ...
        'H09 differs only in 6 SST inputs; all CHIRPS identical.\n']);
end

function ensure_folder(folder)
    if ~isfolder(folder)
        [ok,msg]=mkdir(folder);
        if ~ok, error('Cannot create %s: %s',folder,msg); end
    end
end

function safe_copy(src,dst)
    assert(isfile(src),'Source file missing: %s',src);
    if isfile(dst)
        assert(same_bytes(src,dst), ...
            'Existing destination differs from source; refusing overwrite: %s',dst);
        return;
    end
    [ok,msg]=copyfile(src,dst);
    assert(ok,'Failed to copy %s: %s',src,msg);
    assert(same_bytes(src,dst),'Copied file differs from source: %s',dst);
end

function tf=same_bytes(a,b)
    aa=dir(a); bb=dir(b);
    if aa.bytes~=bb.bytes, tf=false; return; end
    fa=fopen(a,'rb'); fb=fopen(b,'rb');
    assert(fa>=0 && fb>=0,'Cannot open files for copy verification.');
    cleaner=onCleanup(@()close_pair(fa,fb));
    tf=true;
    while true
        x=fread(fa,1024*1024,'*uint8');
        y=fread(fb,1024*1024,'*uint8');
        if ~isequal(x,y), tf=false; break; end
        if isempty(x), break; end
    end
    clear cleaner;
end

function close_pair(fa,fb)
    fclose(fa); fclose(fb);
end
