
%% ========================================================================
% e_figure5_partial_correlation_heatmaps.m | MATLAB R2021a
% MANUSCRIPT FIGURE 5 - SEASONAL PARTIAL CORRELATION HEATMAPS
%
% FINAL REVISION:
% - Flores TOP, Sumba MIDDLE, Timor BOTTOM
% - Same color scale [-1,+1] in both panels
% - Large numerical labels
% - Dagger: suggestive only (0.05 <= qFDR < 0.10)
% - No significant partial relationship at qFDR < 0.05
%
% INPUT:
% ../06_Climate_Mode_Sensitivity/
% seasonal_partial_robustness_results.csv
%
% Save this script in Data/08_Figures/
% No statistical recalculation.
%% ========================================================================

clc;
close all;

%% 1. READ STAGE 06 CSV

scriptPath = mfilename('fullpath');

assert(~isempty(scriptPath), ...
    'Save this file as a MATLAB .m script before running.');

outDir = fileparts(scriptPath);
dataDir = fileparts(outDir);

inCSV = fullfile(dataDir, ...
    '06_Climate_Mode_Sensitivity', ...
    'seasonal_partial_robustness_results.csv');

assert(isfile(inCSV), ...
    'Stage 06 CSV not found: %s',inCSV);

T = readtable(inCSV,'VariableNamingRule','preserve');

need = {'Region','Season','N', ...
        'Partial_Nino_r','Nino_q_FDR', ...
        'Partial_DMI_r','DMI_q_FDR'};

assert(all(ismember(need,T.Properties.VariableNames)), ...
    'Unexpected CSV columns: %s', ...
    strjoin(T.Properties.VariableNames,', '));

assert(height(T)==12, ...
    'Expected 12 region-season rows.');

%% 2. BUILD REGIONAL MATRICES

% IMPORTANT:
% Row 1 = Flores
% Row 2 = Sumba
% Row 3 = Timor

regions = {'Flores','Sumba','Timor'};
seasons = {'DJF','MAM','JJA','SON'};

R_Nino = nan(3,4);
Q_Nino = nan(3,4);

R_DMI = nan(3,4);
Q_DMI = nan(3,4);

Nobs = nan(3,4);

for ir = 1:3

    for is = 1:4

        row = ...
            strcmpi(strtrim(string(T.Region)),regions{ir}) & ...
            strcmpi(strtrim(string(T.Season)),seasons{is});

        assert(nnz(row)==1, ...
            'Missing or duplicate %s %s.', ...
            regions{ir},seasons{is});

        R_Nino(ir,is) = double(T.Partial_Nino_r(row));
        Q_Nino(ir,is) = double(T.Nino_q_FDR(row));

        R_DMI(ir,is) = double(T.Partial_DMI_r(row));
        Q_DMI(ir,is) = double(T.DMI_q_FDR(row));

        Nobs(ir,is) = double(T.N(row));

    end

end

%% 3. DATA QUALITY CONTROL

allR = [R_Nino(:);R_DMI(:)];
allQ = [Q_Nino(:);Q_DMI(:)];

assert(all(isfinite([allR;allQ])), ...
    'Non-finite correlation or qFDR value.');

assert(all(abs(allR)<=1), ...
    'Correlation must be between -1 and +1.');

assert(all(allQ>=0 & allQ<=1), ...
    'qFDR must be between 0 and 1.');

assert(isequal(Nobs,repmat([9 10 10 9],3,1)), ...
    'Unexpected seasonal sample sizes.');

nSigN = nnz(Q_Nino<0.05);
nSigD = nnz(Q_DMI<0.05);

nSugN = nnz(Q_Nino>=0.05 & Q_Nino<0.10);
nSugD = nnz(Q_DMI>=0.05 & Q_DMI<0.10);

fprintf('\n===== FIGURE 5 DATA QC =====\n');

fprintf('Nino 3.4: q<0.05 = %d; suggestive = %d\n', ...
    nSigN,nSugN);

fprintf('DMI:      q<0.05 = %d; suggestive = %d\n', ...
    nSigD,nSugD);

assert(nSigN==0 && nSigD==0, ...
    'Significance results changed. Check Stage 06.');

assert(nSugN==2 && nSugD==0, ...
    'Suggestive results differ from expected Stage 06.');

assert( ...
    Q_Nino(1,3)>=0.05 && Q_Nino(1,3)<0.10 && ...
    Q_Nino(3,3)>=0.05 && Q_Nino(3,3)<0.10, ...
    'Expected Flores JJA and Timor JJA to be suggestive.');

%% 4. SHARED DIVERGING COLORMAP

nHalf = 128;

blue = [0.35 0.52 0.73];
neutral = [0.965 0.965 0.965];
red = [0.79 0.36 0.35];

cmap = [ ...
    linspace(blue(1),neutral(1),nHalf)' ...
    linspace(blue(2),neutral(2),nHalf)' ...
    linspace(blue(3),neutral(3),nHalf)'; ...
    linspace(neutral(1),red(1),nHalf)' ...
    linspace(neutral(2),red(2),nHalf)' ...
    linspace(neutral(3),red(3),nHalf)' ];

cLim = [-1 1];

%% 5. FIGURE LAYOUT

fig = figure('Color','white', ...
    'Units','pixels', ...
    'Position',[70 90 1400 555], ...
    'PaperPositionMode','auto');

fontName = 'Arial';

fsTicks = 13;
fsNumber = 16;
fsTitle = 15;

posA = [0.070 0.255 0.360 0.605];
posB = [0.505 0.255 0.360 0.605];

posCB = [0.902 0.315 0.015 0.495];
posNote = [0.065 0.025 0.870 0.140];

axA = axes('Parent',fig, ...
    'Units','normalized','Position',posA);

axB = axes('Parent',fig, ...
    'Units','normalized','Position',posB);

axs = [axA axB];

Rs = {R_Nino,R_DMI};
Qs = {Q_Nino,Q_DMI};

panelNames = { ...
    '(a) Nino 3.4-controlled', ...
    '(b) DMI-controlled'};

%% 6. PLOT BOTH HEATMAPS

for ip = 1:2

    ax = axs(ip);

    rMat = Rs{ip};
    qMat = Qs{ip};

    imagesc(ax,rMat);

    colormap(ax,cmap);
    caxis(ax,cLim);

    % =====================================================
    % IMPORTANT FIX:
    % Reverse Y direction so row 1 is at the TOP.
    %
    % TOP    = Flores
    % MIDDLE = Sumba
    % BOTTOM = Timor
    %
    % DO NOT FLIP THE CORRELATION MATRICES.
    % =====================================================

    set(ax, ...
        'YDir','reverse', ...
        'XLim',[0.5 4.5], ...
        'YLim',[0.5 3.5], ...
        'XTick',1:4, ...
        'XTickLabel',seasons, ...
        'YTick',1:3, ...
        'YTickLabel',regions, ...
        'FontName',fontName, ...
        'FontSize',fsTicks, ...
        'LineWidth',0.9, ...
        'TickDir','out', ...
        'TickLength',[0 0], ...
        'Box','on', ...
        'Layer','top');

    title(ax,panelNames{ip}, ...
        'FontName',fontName, ...
        'FontSize',fsTitle, ...
        'FontWeight','bold');

    xlabel(ax,'Season', ...
        'FontName',fontName, ...
        'FontSize',fsTicks);

    hold(ax,'on');

    %% CELL BORDERS

    for x = 0.5:1:4.5

        plot(ax,[x x],[0.5 3.5],'-', ...
            'Color',[0.83 0.83 0.83], ...
            'LineWidth',0.8, ...
            'HandleVisibility','off');

    end

    for y = 0.5:1:3.5

        plot(ax,[0.5 4.5],[y y],'-', ...
            'Color',[0.83 0.83 0.83], ...
            'LineWidth',0.8, ...
            'HandleVisibility','off');

    end

    %% NUMERICAL CORRELATION LABELS

    for ir = 1:3

        for is = 1:4

            r = rMat(ir,is);
            q = qMat(ir,is);

            label = sprintf('%.2f',r);

            % Dagger represents suggestive evidence ONLY
            if q>=0.05 && q<0.10

                label = [label char(8224)];

            end

            % Text contrast based on actual heatmap color

            ix = max(1,min(size(cmap,1), ...
                round(1+(r+1)*(size(cmap,1)-1)/2)));

            rgb = cmap(ix,:);

            luminance = ...
                rgb*[0.2126;0.7152;0.0722];

            if luminance<0.57
                ink = [1 1 1];
            else
                ink = [0.09 0.09 0.09];
            end

            text(ax,is,ir,label, ...
                'HorizontalAlignment','center', ...
                'VerticalAlignment','middle', ...
                'FontName',fontName, ...
                'FontSize',fsNumber, ...
                'FontWeight','bold', ...
                'Color',ink, ...
                'Interpreter','none');

        end

    end

end

%% 7. SHARED COLORBAR

cb = colorbar(axB,'eastoutside');

cb.FontName = fontName;
cb.FontSize = 12;

cb.Ticks = [-1 -0.5 0 0.5 1];

cb.Label.String = 'Partial correlation (r)';
cb.Label.FontSize = 13;
cb.Label.FontName = fontName;

%% 8. STATISTICAL ANNOTATION

notes = { ...
    'NO partial relationship survived BH-FDR at qFDR < 0.05 (Nino 3.4: 0/12; DMI: 0/12).', ...
    [char(8224) ' = suggestive only (0.05 <= qFDR < 0.10); not statistically significant.'], ...
    'DJF/SON: n = 9 season-years; MAM/JJA: n = 10 season-years.'};

annotation(fig,'textbox',posNote, ...
    'String',notes, ...
    'Interpreter','none', ...
    'EdgeColor','none', ...
    'FitBoxToText','off', ...
    'FontName',fontName, ...
    'FontSize',11, ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'Color',[0.15 0.15 0.15]);

%% 9. RESTORE LAYOUT POSITIONS

drawnow;

set(axA,'Units','normalized','Position',posA);
set(axB,'Units','normalized','Position',posB);
set(cb,'Units','normalized','Position',posCB);

drawnow;

% Verify axis orientation before export

assert( ...
    strcmpi(get(axA,'YDir'),'reverse') && ...
    strcmpi(get(axB,'YDir'),'reverse'), ...
    'Incorrect heatmap row order.');

fprintf('Display order: Flores / Sumba / Timor.\n');

%% 10. EXPORT FIGURES

outPNG = fullfile(outDir, ...
    'Figure_5_Partial_Correlation_Heatmaps.png');

outPDF = fullfile(outDir, ...
    'Figure_5_Partial_Correlation_Heatmaps.pdf');

outGray = fullfile(outDir, ...
    'Figure_5_Partial_Correlation_Heatmaps_Grayscale_QC.png');

% High-resolution PNG

exportgraphics(fig,outPNG, ...
    'Resolution',600, ...
    'BackgroundColor','white');

% Vector PDF

exportgraphics(fig,outPDF, ...
    'ContentType','vector', ...
    'BackgroundColor','white');

%% 11. GRAYSCALE QUALITY CHECK

rgb = imread(outPNG);

if size(rgb,3)==3

    gray = uint8(round( ...
        0.2126*double(rgb(:,:,1)) + ...
        0.7152*double(rgb(:,:,2)) + ...
        0.0722*double(rgb(:,:,3))));

else

    gray = rgb;

end

imwrite(gray,outGray);

%% 12. SAVE QC TABLE

Region = cell(12,1);
Season = cell(12,1);

N = zeros(12,1);

Partial_Nino_r = zeros(12,1);
Nino_q_FDR = zeros(12,1);

Partial_DMI_r = zeros(12,1);
DMI_q_FDR = zeros(12,1);

row = 0;

for ir = 1:3

    for is = 1:4

        row = row+1;

        Region{row} = regions{ir};
        Season{row} = seasons{is};

        N(row) = Nobs(ir,is);

        Partial_Nino_r(row) = R_Nino(ir,is);
        Nino_q_FDR(row) = Q_Nino(ir,is);

        Partial_DMI_r(row) = R_DMI(ir,is);
        DMI_q_FDR(row) = Q_DMI(ir,is);

    end

end

QCT = table( ...
    Region,Season,N, ...
    Partial_Nino_r,Nino_q_FDR, ...
    Partial_DMI_r,DMI_q_FDR);

writetable(QCT, ...
    fullfile(outDir,'Figure_5_Annotation_QC.csv'));

%% 13. SAVE METHODS METADATA

fid = fopen(fullfile(outDir, ...
    'Figure_5_Methods_Metadata.txt'),'w');

assert(fid~=-1,'Unable to write metadata.');

fprintf(fid, ...
    'Figure 5: Seasonal partial SST-rainfall correlations\n');

fprintf(fid,'Source: %s\n',inCSV);

fprintf(fid, ...
    'Top-to-bottom: Flores, Sumba, Timor.\n');

fprintf(fid, ...
    'Controls: Nino 3.4 and DMI separately.\n');

fprintf(fid, ...
    'Conditional residual permutations: 10000 per test.\n');

fprintf(fid, ...
    'BH-FDR: separate 12-test families per index.\n');

fprintf(fid, ...
    'Shared color limits: [-1,+1].\n');

fprintf(fid, ...
    'Nino significant=%d; suggestive=%d.\n', ...
    nSigN,nSugN);

fprintf(fid, ...
    'DMI significant=%d; suggestive=%d.\n', ...
    nSigD,nSugD);

fprintf(fid, ...
    'Dagger means suggestive, NOT significant.\n');

fprintf(fid, ...
    'Seasonal sample size: n=9 or n=10.\n');

fprintf(fid, ...
    'Results are exploratory and decade-specific.\n');

fclose(fid);

%% 14. FINAL QC

fprintf('\n===== FIGURE 5 COMPLETE =====\n');

fprintf('Top-to-bottom: Flores, Sumba, Timor\n');

fprintf('Nino: significant=%d, suggestive=%d\n', ...
    nSigN,nSugN);

fprintf('DMI: significant=%d, suggestive=%d\n', ...
    nSigD,nSugD);

fprintf('PNG: %s\n',outPNG);
fprintf('PDF: %s\n',outPDF);
fprintf('Grayscale QC: %s\n',outGray);
