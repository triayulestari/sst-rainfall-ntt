function z_compare_scenarios(maxStage)
% ========================================================================
% AUTO-COMPARISON FOR THE CLEAN H08/H09 PIPELINE | MATLAB R2021a+
% Never imports a previous comparison or changes the original study.
% Only compares paired results from CURRENT 03_Scenarios folders.
% Delta = H09_Alternative - H08_Final.
%
% Outputs in 04_Comparison:
%   00_Run_Status.csv
%   01_Metric_Delta_Summary.csv
%   02_Metric_Delta_Detail_Changed_Only.csv
%   03_FDR_Family_Comparison.csv
%   04_Seasonal_Conclusions.csv
%   05_Methods_and_Interpretation.txt
% ========================================================================
    if nargin~=1 || ~ismember(maxStage,2:7)
        error('Pass maxStage = 2,3,4,5,6 or 7.');
    end
    root09=fileparts(mfilename('fullpath'));
    scenRoot=fullfile(root09,'03_Scenarios');
    out=fullfile(root09,'04_Comparison');
    if ~isfolder(out), mkdir(out); end
    base=fullfile(scenRoot,'H08_Final');
    alt =fullfile(scenRoot,'H09_Alternative');

    % One entry per scientifically paired CSV, with explicit matching keys.
    specs={ ...
      2,'02_Regional_Timeseries','regional_timeseries_raw.csv',{'Time'}; ...
      2,'02_Regional_Timeseries','regional_anomalies.csv',{'Time'}; ...
      2,'02_Regional_Timeseries','regional_calendar_month_means.csv',{'Month'}; ...
      2,'02_Regional_Timeseries','regional_detrending_summary.csv',{'Region'}; ...
      3,'03_Monthly_and_Lagged','monthly_zero_lag_correlation.csv',{'Region','Series'}; ...
      3,'03_Monthly_and_Lagged','autocorrelation_effectiveN.csv',{'Region'}; ...
      3,'03_Monthly_and_Lagged','lagged_correlation_results.csv',{'Region','Lag_month'}; ...
      4,'04_Seasonal_Analysis','seasonal_mean_anomalies.csv',{'Region','Season','Season_year'}; ...
      4,'04_Seasonal_Analysis','seasonal_correlation_basic.csv',{'Region','Season'}; ...
      4,'04_Seasonal_Analysis','seasonal_robustness_results.csv',{'Region','Season'}; ...
      4,'04_Seasonal_Analysis','seasonal_LOYO_results.csv',{'Region','Season','Removed_year'}; ...
      4,'04_Seasonal_Analysis','seasonal_annual_dependence_QC.csv',{'Region','Season'}; ...
      4,'04_Seasonal_Analysis','seasonal_uncertainty_summary.csv',{'Region','Season'}; ...
      5,'05_Spatial_Analysis','spatial_correlation_summary.csv',{'Region'}; ...
      5,'05_Spatial_Analysis','spatial_correlation_grid_results.csv',{'Region','Longitude','Latitude'}; ...
      6,'06_Climate_Mode_Sensitivity','seasonal_partial_correlation_results.csv',{'Region','Season'}; ...
      6,'06_Climate_Mode_Sensitivity','seasonal_partial_robustness_results.csv',{'Region','Season'}; ...
      6,'06_Climate_Mode_Sensitivity','seasonal_partial_LOYO_results.csv',{'Region','Season','Control','OmittedYear'}; ...
      6,'06_Climate_Mode_Sensitivity','partial_uncertainty_dependence_summary.csv',{'Region','Season','Control'}; ...
      7,'07_Robustness_Tests','seasonal_detrend_sensitivity.csv',{'Region','Season'}; ...
      7,'07_Robustness_Tests','seasonal_exclude2025_sensitivity.csv',{'Region','Season'}; ...
      7,'07_Robustness_Tests','JJA_rainfall_magnitude.csv',{'RegionJJA'}; ...
      7,'07_Robustness_Tests','spatial_coarse010_summary.csv',{'Region'}; ...
      7,'07_Robustness_Tests','spatial_coarse010_grid_results.csv',{'Region','Longitude','Latitude'} ...
    };

    summaryRows=cell(0,9);
    detailRows=cell(0,7);
    for k=1:size(specs,1)
        stage=specs{k,1};
        if stage>maxStage, continue; end
        folder=specs{k,2}; file=specs{k,3}; keys=specs{k,4};
        f8=fullfile(base,folder,file);
        f9=fullfile(alt,folder,file);
        assert(isfile(f8) && isfile(f9), ...
            'Cannot compare missing current output: %s',file);
        A=readtable(f8); B=readtable(f9);
        [A,B]=align_pair(A,B,keys,file);
        vars=A.Properties.VariableNames;
        fileLabel=[folder '/' file];
        for v=1:numel(vars)
            metric=vars{v};
            if ismember(metric,keys), continue; end
            x=A.(metric); y=B.(metric);
            if ~(isnumeric(x) && isnumeric(y)), continue; end
            x=double(x(:)); y=double(y(:));
            sameMissing=isnan(x)&isnan(y);
            valid=isfinite(x)&isfinite(y);
            assert(all(sameMissing|valid), ...
                'Missing/nonfinite mismatch: %s / %s',file,metric);
            delta=y(valid)-x(valid);
            changed=valid & abs(y-x)>1e-12;
            if isempty(delta)
                meanAbs=NaN; maxAbs=NaN; meanDelta=NaN;
            else
                meanAbs=mean(abs(delta));
                maxAbs=max(abs(delta));
                meanDelta=mean(delta);
            end
            summaryRows(end+1,:)={stage,fileLabel,metric, ...
                nnz(valid),nnz(changed),meanAbs,maxAbs,meanDelta,nnz(sameMissing)}; %#ok<AGROW>
            ix=find(changed);
            for j=1:numel(ix)
                row=ix(j);
                keyText=make_key_text(A,row,keys);
                detailRows(end+1,:)={stage,fileLabel,keyText,metric, ...
                    x(row),y(row),y(row)-x(row)}; %#ok<AGROW>
            end
        end
        fprintf('COMPARE PASS: %s (%d matched rows)\n',fileLabel,height(A));
    end

    S=cell2table(summaryRows,'VariableNames', ...
        {'Stage','File','Metric','N_finite_pairs','N_changed', ...
         'Mean_abs_delta','Max_abs_delta','Mean_delta_H09_minus_H08','N_shared_NaN'});
    S=to_numeric_cols(S,{'Stage','N_finite_pairs','N_changed', ...
        'Mean_abs_delta','Max_abs_delta','Mean_delta_H09_minus_H08','N_shared_NaN'});
    writetable(S,fullfile(out,'01_Metric_Delta_Summary.csv'));

    D=cell2table(detailRows,'VariableNames', ...
        {'Stage','File','Key','Metric','H08','H09','Delta_H09_minus_H08'});
    D=to_numeric_cols(D,{'Stage','H08','H09','Delta_H09_minus_H08'});
    writetable(D,fullfile(out,'02_Metric_Delta_Detail_Changed_Only.csv'));

    F=build_fdr(base,alt,maxStage);
    writetable(F,fullfile(out,'03_FDR_Family_Comparison.csv'));

    if maxStage>=4
        A=readtable(fullfile(base,'04_Seasonal_Analysis','seasonal_robustness_results.csv'));
        B=readtable(fullfile(alt,'04_Seasonal_Analysis','seasonal_robustness_results.csv'));
        [A,B]=align_pair(A,B,{'Region','Season'},'seasonal_robustness_results.csv');
        Region=A.Region; Season=A.Season; N=A.N;
        H08_r=A.Pearson_r; H09_r=B.Pearson_r;
        Delta_r=H09_r-H08_r;
        H08_p_permutation=A.p_permutation; H09_p_permutation=B.p_permutation;
        H08_q_FDR=A.q_FDR_permutation; H09_q_FDR=B.q_FDR_permutation;
        Delta_q_FDR=H09_q_FDR-H08_q_FDR;
        H08_status=arrayfun(@status_q,H08_q_FDR,'UniformOutput',false);
        H09_status=arrayfun(@status_q,H09_q_FDR,'UniformOutput',false);
        Decision_changed=~strcmp(H08_status,H09_status);
        Conclusions=table(Region,Season,N,H08_r,H09_r,Delta_r, ...
            H08_p_permutation,H09_p_permutation,H08_q_FDR,H09_q_FDR, ...
            Delta_q_FDR,H08_status,H09_status,Decision_changed);
        writetable(Conclusions,fullfile(out,'04_Seasonal_Conclusions.csv'));
    end

    Stage=(2:7)';
    Status=cell(numel(Stage),1);
    for j=1:numel(Stage)
        if Stage(j)>maxStage
            Status{j}='NOT_RUN_BY_CHOICE';
        elseif Stage(j)==7
            Status{j}='COMPLETE_ELIGIBLE_07c_07d__07a_07b_NOT_TESTED';
        else
            Status{j}='COMPLETE_AND_COMPARED';
        end
    end
    writetable(table(Stage,Status),fullfile(out,'00_Run_Status.csv'));

    noteFile=fullfile(out,'05_Methods_and_Interpretation.txt');
    fid=fopen(noteFile,'w');
    assert(fid>=0,'Cannot write comparison note.');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'CONTROLLED H08/H09 OCT-NOV 2022 SST SOURCE TRANSITION\n');
    fprintf(fid,'Comparison generated from CURRENT 03_Scenarios outputs only.\n');
    fprintf(fid,'Delta convention: H09 alternative minus H08 final.\n');
    fprintf(fid,'maxStage completed: %d. Stage 02 includes regional anomalies.\n',maxStage);
    fprintf(fid,'H08 original baseline is checked by run_H08_H09_clean.m (tolerance 1e-8).\n');
    fprintf(fid,'H09 differs from H08 ONLY in six regional SST inputs (Oct-Nov 2022).\n');
    fprintf(fid,'CHIRPS and climate indices are identical across scenarios.\n');
    fprintf(fid,'Original Stage 03-07 scripts and FDR test families are unchanged.\n');
    fprintf(fid,'All comparisons align rows by explicit scientific keys.\n');
    fprintf(fid,'Numeric comparison tolerance for changed detail: 1e-12.\n');
    fprintf(fid,'Spatial coordinates compared with tolerance 1e-4 degrees.\n');
    fprintf(fid,'02_Metric_Delta_Detail_Changed_Only.csv contains only changed values.\n');
    fprintf(fid,'A missing FDR family due to maxStage means NOT RUN, not zero significance.\n');
    fprintf(fid,'Stage 07a and 07b NOT tested: require source-specific cropped SST NetCDF.\n');
    fprintf(fid,'Grid cells are spatially dependent; their FDR counts are not replicates.\n');
    fprintf(fid,'Fisher-z intervals are approximate; year permutations do not preserve persistence.\n');
    fprintf(fid,'Source platform and product processing version differ simultaneously.\n');
    fprintf(fid,'This is source-transition sensitivity, not validation of absolute SST accuracy.\n');
    fprintf(fid,'N_comparison_metrics=%d; N_changed_numeric_values=%d; FDR_families=%d.\n', ...
        height(S),height(D),height(F));
    clear cleaner;
    fprintf('\n===== COMPARISON CREATED =====\n');
    fprintf('Metric summaries: %d; changed numeric records: %d; FDR families: %d\n', ...
        height(S),height(D),height(F));
    fprintf('Output: %s\n',out);
end

function [A,B]=align_pair(A,B,keys,file)
    assert(height(A)==height(B),'Row-count mismatch: %s',file);
    assert(isequal(A.Properties.VariableNames,B.Properties.VariableNames), ...
        'Column-name mismatch: %s',file);
    assert(all(ismember(keys,A.Properties.VariableNames)), ...
        'Expected key columns absent: %s',file);
    A=sortrows(A,keys); B=sortrows(B,keys);
    for k=1:numel(keys)
        a=A.(keys{k}); b=B.(keys{k});
        if isnumeric(a) && isnumeric(b)
            assert(all(abs(double(a(:))-double(b(:)))<1e-4), ...
                'Numeric scientific keys do not align: %s / %s',file,keys{k});
        else
            assert(isequaln(string(a(:)),string(b(:))), ...
                'Scientific keys do not align: %s / %s',file,keys{k});
        end
    end
    if height(A)>1
        % Unique scientific keys are required for unambiguous comparisons.
        for i=2:height(A)
            assert(~strcmp(make_key_text(A,i,keys),make_key_text(A,i-1,keys)), ...
                'Duplicate scientific key in %s.',file);
        end
    end
end

function keyText=make_key_text(T,i,keys)
    parts=cell(1,numel(keys));
    for k=1:numel(keys)
        x=T.(keys{k});
        if iscell(x), v=x{i}; else, v=x(i); end
        if isnumeric(v)
            parts{k}=sprintf('%.10g',double(v));
        else
            parts{k}=char(string(v));
        end
    end
    keyText=strjoin(parts,' | ');
end

function T=to_numeric_cols(T,names)
    for k=1:numel(names)
        if iscell(T.(names{k}))
            T.(names{k})=cell2mat(T.(names{k}));
        end
    end
end

function F=build_fdr(base,alt,maxStage)
    rows=cell(0,10);
    if maxStage>=3
        file=fullfile('03_Monthly_and_Lagged','lagged_correlation_results.csv');
        rows=add_family(rows,base,alt,file,{'Region','Lag_month'}, ...
            'q_FDR_all39','Lagged_all_39','ALL',39,[]);
        rows=add_family(rows,base,alt,file,{'Region','Lag_month'}, ...
            'q_FDR_lag0_to_plus6','Lagged_0_to_plus6_21','ALL',21,'lag_nonnegative');
    end
    if maxStage>=4
        file=fullfile('04_Seasonal_Analysis','seasonal_robustness_results.csv');
        rows=add_family(rows,base,alt,file,{'Region','Season'}, ...
            'q_FDR_permutation','Seasonal_permutation_12','ALL',12,[]);
    end
    if maxStage>=5
        file=fullfile('05_Spatial_Analysis','spatial_correlation_grid_results.csv');
        for r={'Flores','Sumba','Timor'}
            rows=add_family(rows,base,alt,file,{'Region','Longitude','Latitude'}, ...
                'q_FDR_region','Spatial_within_region',r{1},[],[]);
        end
        rows=add_family(rows,base,alt,file,{'Region','Longitude','Latitude'}, ...
            'q_FDR_all_grids','Spatial_pooled_all_grids','ALL',2811,[]);
    end
    if maxStage>=6
        file=fullfile('06_Climate_Mode_Sensitivity','seasonal_partial_robustness_results.csv');
        rows=add_family(rows,base,alt,file,{'Region','Season'}, ...
            'Nino_q_FDR','Partial_Nino34_12','ALL',12,[]);
        rows=add_family(rows,base,alt,file,{'Region','Season'}, ...
            'DMI_q_FDR','Partial_DMI_12','ALL',12,[]);
    end
    if maxStage>=7
        file=fullfile('07_Robustness_Tests','spatial_coarse010_grid_results.csv');
        for r={'Flores','Sumba','Timor'}
            rows=add_family(rows,base,alt,file,{'Region','Longitude','Latitude'}, ...
                'q_FDR_region','Coarse_within_region',r{1},[],[]);
        end
        rows=add_family(rows,base,alt,file,{'Region','Longitude','Latitude'}, ...
            'q_FDR_all_coarse','Coarse_pooled_all','ALL',727,[]);
    end
    if isempty(rows)
        F=table(cell(0,1),cell(0,1),zeros(0,1),zeros(0,1), ...
            zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
            zeros(0,1),zeros(0,1), ...
            'VariableNames',{'Family','Region','N_tests','H08_q005', ...
            'H09_q005','H08_q010','H09_q010','Changed_decision_005', ...
            'Changed_decision_010','Max_abs_delta_q'});
    else
        F=cell2table(rows,'VariableNames', ...
            {'Family','Region','N_tests','H08_q005','H09_q005', ...
             'H08_q010','H09_q010','Changed_decision_005', ...
             'Changed_decision_010','Max_abs_delta_q'});
        F=to_numeric_cols(F,{'N_tests','H08_q005','H09_q005', ...
            'H08_q010','H09_q010','Changed_decision_005', ...
            'Changed_decision_010','Max_abs_delta_q'});
    end
end

function rows=add_family(rows,base,alt,file,keys,qName,family,region,expected,filterType)
    A=readtable(fullfile(base,file)); B=readtable(fullfile(alt,file));
    [A,B]=align_pair(A,B,keys,file);
    mask=true(height(A),1);
    if ~strcmp(region,'ALL')
        mask=mask & strcmp(string(A.Region),string(region));
    end
    if isequal(filterType,'lag_nonnegative')
        mask=mask & A.Lag_month>=0;
    end
    q8=A.(qName); q9=B.(qName);
    x=double(q8(mask));
    y=double(q9(mask));
    assert(all(isfinite(x)) && all(isfinite(y)) && ...
        all(x>=0 & x<=1) && all(y>=0 & y<=1), ...
        'Invalid/missing FDR q-values: %s / %s',file,qName);
    if ~isempty(expected)
        assert(numel(x)==expected, ...
            'Unexpected number of FDR tests for %s (expected %d).',family,expected);
    end
    rows(end+1,:)={family,region,numel(x),nnz(x<.05),nnz(y<.05), ...
        nnz(x<.10),nnz(y<.10),nnz((x<.05)~=(y<.05)), ...
        nnz((x<.10)~=(y<.10)),max(abs(y-x))}; %#ok<AGROW>
end

function s=status_q(q)
    if q<0.05
        s='FDR_RETAINED';
    elseif q<0.10
        s='SUGGESTIVE_ONLY';
    else
        s='NOT_FDR_SUPPORTED';
    end
end
