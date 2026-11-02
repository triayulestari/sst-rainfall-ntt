%% ========================================================================
% c_figure3_lagged_seasonal_correlations.m | MATLAB R2021a
% FIGURE 3 - FINAL COMPACT VERSION (same 2 panels as manuscript)
%
% (a) Lagged Pearson correlations of monthly DESEASONALIZED anomalies
% (b) Seasonal Pearson correlations of seasonal-mean DESEASONALIZED anomalies
%
% Statistical annotations come DIRECTLY from the final Stage 03/04 CSVs.
% *        : BH-FDR q < 0.05 (retained)
% dagger   : 0.05 <= BH-FDR q < 0.10 (suggestive ONLY)
% none     : q >= 0.10 (not statistically supported after FDR)
%
% (a) q is based on autocorrelation-adjusted p, BH-FDR of 39 tests.
% (b) q is based on 10,000 two-sided year permutations, BH-FDR of 12 tests.
% Significant/ suggestive status is NEVER determined from color or r alone.
%
% Figure output in Data/08_Figures beside this script.
% The original analysis/CSV files are NEVER modified.
%% ========================================================================
clc;
close all;

%% A. Paths + read final results
script_file = mfilename('fullpath');
assert(~isempty(script_file),'Save as .m file before running.');
out_dir  = fileparts(script_file);
data_dir = fileparts(out_dir);
fLag = fullfile(data_dir,'03_Monthly_and_Lagged','lagged_correlation_results.csv');
fSea = fullfile(data_dir,'04_Seasonal_Analysis','seasonal_robustness_results.csv');
assert(isfile(fLag),'File not found: %s',fLag);
assert(isfile(fSea),'File not found: %s',fSea);
L = readtable(fLag);
S = readtable(fSea);
assert(all(ismember({'Region','Lag_month','N','Pearson_r', ...
    'p_autocorr_adjusted','q_FDR_all39'}, L.Properties.VariableNames)), ...
    'Stage 03 CSV columns differ from the final workflow.');
assert(all(ismember({'Region','Season','N','Pearson_r', ...
    'p_permutation','q_FDR_permutation'}, S.Properties.VariableNames)), ...
    'Stage 04 CSV columns differ from the final workflow.');
assert(height(L)==39 && height(S)==12,'Expected 39 lagged and 12 seasonal tests.');

regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};
lags    = -6:6;
lagR = nan(3,13); lagQ = nan(3,13);
seaR = nan(3,4);  seaQ = nan(3,4);
Rlag = string(L.Region); Rsea = string(S.Region);
Sname = string(S.Season);
for ir=1:3
    for il=1:13
        ix=find(Rlag==string(regions{ir}) & L.Lag_month==lags(il));
        assert(numel(ix)==1,'Missing/duplicate %s lag %d',regions{ir},lags(il));
        lagR(ir,il)=L.Pearson_r(ix);
        lagQ(ir,il)=L.q_FDR_all39(ix);
    end
    for is=1:4
        ix=find(Rsea==string(regions{ir}) & Sname==string(seasons{is}));
        assert(numel(ix)==1,'Missing/duplicate %s %s',regions{ir},seasons{is});
        seaR(ir,is)=S.Pearson_r(ix);
        seaQ(ir,is)=S.q_FDR_permutation(ix);
    end
end
assert(all(isfinite(lagR(:))) && all(isfinite(seaR(:))) && ...
       all(abs(lagR(:))<=1) && all(abs(seaR(:))<=1),'Invalid r values.');
assert(all(isfinite(lagQ(:))) && all(isfinite(seaQ(:))) && ...
       all(lagQ(:)>=0 & lagQ(:)<=1) && ...
       all(seaQ(:)>=0 & seaQ(:)<=1),'Invalid qFDR values.');

lagStar = (lagQ<.05); lagDag = (lagQ>=.05 & lagQ<.10);
seaStar = (seaQ<.05); seaDag = (seaQ>=.05 & seaQ<.10);
assert(nnz(lagStar)==0 && nnz(lagDag)==3 && ...
       nnz(seaStar)==4 && nnz(seaDag)==2, ...
    'Unexpected FDR counts. Check that the CSVs are the FINAL versions.');
dag = char(8224); % Unicode dagger symbol
fprintf('\n===== FIGURE 3 COMPACT: ANNOTATION QC =====\n');
fprintf('Lagged: %d FDR-retained, %d suggestive, %d other.\n', ...
    nnz(lagStar),nnz(lagDag),39-nnz(lagStar)-nnz(lagDag));
fprintf('Seasonal: %d FDR-retained, %d suggestive, %d other.\n', ...
    nnz(seaStar),nnz(seaDag),12-nnz(seaStar)-nnz(seaDag));

%% B. Compact canvas and manual panel positions (avoids tiledlayout resizing)
% New aspect is approx 2.7:1, shorter than the previous approx 2.45:1.
fig=figure('Color','white','Units','pixels','Position',[70 70 1500 550]);
fontName='Arial';
fs=12;
lineRGB=[0.000 0.447 0.741; ...
         0.850 0.325 0.098; ...
         0.470 0.360 0.080];
lineStyles={'-','--','-.'};
markers={'o','s','^'};

% A: ~56% of content area; B: ~44% incl. colorbar.
ax1=axes('Parent',fig,'Units','normalized', ...
    'Position',[0.068 0.225 0.445 0.66]);
ax2=axes('Parent',fig,'Units','normalized', ...
    'Position',[0.585 0.225 0.295 0.66]);

%% C. Panel (a) - Lagged correlations, direct qFDR outlines
hold(ax1,'on');
hSeries=gobjects(3,1);
for ir=1:3
    hSeries(ir)=plot(ax1,lags,lagR(ir,:), ...
        'Color',lineRGB(ir,:), ...
        'LineStyle',lineStyles{ir}, ...
        'Marker',markers{ir}, ...
        'MarkerSize',5.6,'MarkerFaceColor','white','LineWidth',1.9);
end
xline(ax1,0,':','Color',[0.52 0.52 0.52],'LineWidth',0.9, ...
    'HandleVisibility','off');
yline(ax1,0,'--','Color',[0.60 0.60 0.60],'LineWidth',0.8, ...
    'HandleVisibility','off');

% Highlight each suggestive point with a large black OUTLINE ring.
% Dagger nearby, never attached to an unrelated curve. No lag is q<.05.
for ir=1:3
    for il=1:13
        if lagDag(ir,il)
            x=lags(il); y=lagR(ir,il);
            plot(ax1,x,y,'o','LineStyle','none','MarkerSize',12, ...
                'LineWidth',1.65,'MarkerEdgeColor',[0.08 0.08 0.08], ...
                'MarkerFaceColor','none','HandleVisibility','off');
            dx=0.10; dy=0.057;
            if strcmp(regions{ir},'Timor') && x==4
                dx=0.13; dy=-0.068; % avoid Flores at the same lag
            end
            text(ax1,x+dx,y+dy,dag,'FontName',fontName, ...
                'FontSize',19,'FontWeight','bold', ...
                'Color',[0.06 0.06 0.06], ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle','Interpreter','none');
        end
    end
end
xlim(ax1,[-6.3 6.3]); ylim(ax1,[-.40 .42]);
xticks(ax1,-6:2:6); yticks(ax1,-.4:.2:.4);
xlabel(ax1,'Lag (months)','FontName',fontName,'FontSize',fs+1);
ylabel(ax1,'Pearson correlation (r)','FontName',fontName,'FontSize',fs+1);
set(ax1,'FontName',fontName,'FontSize',fs, ...
    'TickDir','out','LineWidth',0.85,'Box','on');
ax1.GridAlpha=.12; grid(ax1,'on');
legend(ax1,hSeries,regions,'Location','northwest', ...
    'FontName',fontName,'FontSize',fs-1,'Box','off');
text(ax1,-5.95,-.35,'Rainfall leads SST','FontName',fontName, ...
    'FontSize',fs-2,'FontAngle','italic','Color',[.30 .30 .30]);
text(ax1,1.2,-.35,'SST leads rainfall','FontName',fontName, ...
    'FontSize',fs-2,'FontAngle','italic','Color',[.30 .30 .30]);

%% D. Panel (b) - seasonal heatmap; r in fill, qFDR in border/symbol
imagesc(ax2,1:4,1:3,seaR,[-1 1]);
set(ax2,'YDir','reverse','XLim',[.5 4.5],'YLim',[.5 3.5], ...
    'XTick',1:4,'XTickLabel',seasons, ...
    'YTick',1:3,'YTickLabel',regions, ...
    'FontName',fontName,'FontSize',fs, ...
    'TickDir','out','LineWidth',.85,'Box','on');
n=128;
blue=[.23 .43 .69]; white=[.98 .98 .98]; red=[.83 .22 .19];
neg=[linspace(blue(1),white(1),n)', ...
     linspace(blue(2),white(2),n)', ...
     linspace(blue(3),white(3),n)'];
pos=[linspace(white(1),red(1),n)', ...
     linspace(white(2),red(2),n)', ...
     linspace(white(3),red(3),n)'];
colormap(ax2,[neg;pos]);
hold(ax2,'on');
for e=1.5:3.5
    plot(ax2,[e e],[.5 3.5],'-','Color',[.88 .88 .88], ...
        'LineWidth',.7,'HandleVisibility','off');
end
for e=1.5:2.5
    plot(ax2,[.5 4.5],[e e],'-','Color',[.88 .88 .88], ...
        'LineWidth',.7,'HandleVisibility','off');
end
for ir=1:3
    for is=1:4
        r=seaR(ir,is);
        mark='';
        if seaStar(ir,is)
            mark='*';
            % Solid thick BLACK border signals qFDR < 0.05.
            rectangle(ax2,'Position',[is-.465 ir-.465 .93 .93], ...
                'EdgeColor',[.07 .07 .07],'FaceColor','none', ...
                'LineWidth',2.1,'LineStyle','-');
        elseif seaDag(ir,is)
            mark=dag;
            % Dashed DARK GRAY border signals suggestive 0.05 <= q < .10.
            rectangle(ax2,'Position',[is-.465 ir-.465 .93 .93], ...
                'EdgeColor',[.18 .18 .18],'FaceColor','none', ...
                'LineWidth',1.8,'LineStyle','--');
        end
        fc=[.06 .06 .06];
        if abs(r)>=.62, fc=[1 1 1]; end
        text(ax2,is,ir,sprintf('%.2f%s',r,mark), ...
            'FontName',fontName,'FontSize',fs+2, ...
            'FontWeight','bold','Color',fc, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','Interpreter','none');
    end
end
xlabel(ax2,'Season','FontName',fontName,'FontSize',fs+1);
cb=colorbar(ax2,'eastoutside');
cb.Ticks=-1:.5:1;
cb.FontName=fontName; cb.FontSize=fs-1;
cb.Label.String='Pearson correlation (r)';
cb.Label.FontName=fontName; cb.Label.FontSize=fs;
% Explicit fixed positions AFTER colorbar to preserve intended proportions.
ax2.Units='normalized';
ax2.Position=[0.595 .225 .275 .66];
cb.Units='normalized';
cb.Position=[0.892 .225 .015 .66];

%% E. Panel tags and a self-contained legend for statistical evidence
annotation(fig,'textbox',[.068 .903 .07 .054], ...
    'String','(a)','FontName',fontName,'FontSize',fs+4, ...
    'FontWeight','bold','EdgeColor','none','FitBoxToText','off');
annotation(fig,'textbox',[.595 .903 .07 .054], ...
    'String','(b)','FontName',fontName,'FontSize',fs+4, ...
    'FontWeight','bold','EdgeColor','none','FitBoxToText','off');
annotation(fig,'textbox',[.08 .028 .85 .082], ...
    'String',{['* Solid border: qFDR < 0.05 (FDR-retained);  ' ...
               dag ' Dashed border/ring: 0.05 <= qFDR < 0.10 (suggestive only).'], ...
              'Unmarked results: qFDR >= 0.10; no lagged correlation survived qFDR < 0.05.'}, ...
    'FontName',fontName,'FontSize',fs-2, ...
    'Color',[.16 .16 .16],'HorizontalAlignment','center', ...
    'VerticalAlignment','middle','EdgeColor','none','Interpreter','none');
drawnow;

%% F. Export: PNG 600 dpi and vector PDF
outPNG=fullfile(out_dir,'Figure_3_Lagged_Seasonal_Correlations.png');
outPDF=fullfile(out_dir,'Figure_3_Lagged_Seasonal_Correlations.pdf');
exportgraphics(fig,outPNG,'Resolution',600,'BackgroundColor','white');
exportgraphics(fig,outPDF,'ContentType','vector','BackgroundColor','white');

%% G. All 51 annotation decisions, traceable to source qFDR
analysis=strings(51,1); regionCol=strings(51,1);
category=strings(51,1); lagMonth=nan(51,1);
Ncol=nan(51,1); rCol=nan(51,1);
pCol=nan(51,1); qCol=nan(51,1);
symbolCol=strings(51,1); statusCol=strings(51,1);
k=0;
for ii=1:height(L)
    k=k+1;
    analysis(k)="Lagged"; regionCol(k)=string(L.Region(ii));
    category(k)=sprintf('Lag %+d',L.Lag_month(ii));
    lagMonth(k)=L.Lag_month(ii); Ncol(k)=L.N(ii);
    rCol(k)=L.Pearson_r(ii);
    pCol(k)=L.p_autocorr_adjusted(ii);
    qCol(k)=L.q_FDR_all39(ii);
end
for ii=1:height(S)
    k=k+1;
    analysis(k)="Seasonal"; regionCol(k)=string(S.Region(ii));
    category(k)=string(S.Season(ii));
    Ncol(k)=S.N(ii); rCol(k)=S.Pearson_r(ii);
    pCol(k)=S.p_permutation(ii);
    qCol(k)=S.q_FDR_permutation(ii);
end
for ii=1:k
    if qCol(ii)<.05
        symbolCol(ii)="*"; statusCol(ii)="FDR-retained";
    elseif qCol(ii)<.10
        symbolCol(ii)=string(dag); statusCol(ii)="Suggestive only";
    else
        symbolCol(ii)="none"; statusCol(ii)="Not retained";
    end
end
QC=table(analysis,regionCol,category,lagMonth,Ncol,rCol,pCol,qCol, ...
    symbolCol,statusCol,'VariableNames', ...
    {'Analysis','Region','Category','Lag_month','N','Pearson_r', ...
     'p_used_for_FDR','q_FDR','Figure_symbol','Interpretation'});
writetable(QC,fullfile(out_dir,'Figure_3_Annotation_QC.csv'));

fid=fopen(fullfile(out_dir,'Figure_3_Methods_Metadata.txt'),'w');
assert(fid~=-1,'Cannot write metadata.');
fprintf(fid,'Figure 3: final compact version (2016-2025).\n');
fprintf(fid,'Panel (a): source %s\n',fLag);
fprintf(fid,'Monthly deseasonalized anomalies, -6...+6 lag.\n');
fprintf(fid,'Positive lags: SST leads rainfall. Negative: rainfall leads SST.\n');
fprintf(fid,'qFDR: BH across 39 autocorrelation-adjusted lag tests.\n');
fprintf(fid,'Panel (b): source %s\n',fSea);
fprintf(fid,'Seasonal mean deseasonalized anomalies.\n');
fprintf(fid,'Seasonal n: DJF 9, MAM 10, JJA 10, SON 9.\n');
fprintf(fid,'qFDR: BH across 12 tests from 10,000 year permutations.\n');
fprintf(fid,'Solid black cell outline + *: qFDR < 0.05.\n');
fprintf(fid,'Dashed gray cell outline + dagger: 0.05 <= qFDR < 0.10.\n');
fprintf(fid,'Outlined lag points + dagger: suggestive only; 0 lag tests q<0.05.\n');
fprintf(fid,'Fill colors represent r ONLY, not statistical significance.\n');
fprintf(fid,'Statistics are read from input CSVs; this script does not re-test hypotheses.\n');
fprintf(fid,'Limitation: yearwise exchangeability and small seasonal n; see Stage 04 QC.\n');
fclose(fid);
fprintf('Saved: %s\n',outPNG);
fprintf('Saved: %s\n',outPDF);
fprintf('Saved: Figure_3_Annotation_QC.csv (51 rows), metadata TXT.\n');
fprintf('PLEASE REVIEW exported PNG for symbol placement and borders.\n');
