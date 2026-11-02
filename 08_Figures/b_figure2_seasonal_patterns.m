%% ========================================================================
% b_figure2_seasonal_patterns.m  |  MATLAB R2021a
% MANUSCRIPT FIGURE 2: Seasonal patterns and deseasonalized anomalies
%
% Retains the FOUR original manuscript panels and their positions:
%   (a) SST mean for each calendar month (study period: 2016-2025)
%   (b) Rainfall mean for each calendar month (2016-2025)
%   (c) Monthly deseasonalized SST anomalies (Jan 2016 - Dec 2025)
%   (d) Monthly deseasonalized rainfall anomalies (same period)
%
% INPUT (automatically read; no copying/moving data):
%   Data/02_Regional_Timeseries/regional_anomalies.mat
%
% OUTPUT (in the same Data/08_Figures folder as this script):
%   Figure_2_Seasonal_Patterns_Anomalies.png   (600 dpi)
%   Figure_2_Seasonal_Patterns_Anomalies.pdf   (vector)
%   Figure_2_Plot_Data.mat
%   Figure_2_Data_QC.csv
%   Figure_2_Methods_Metadata.txt
%
% IMPORTANT:
%   - The plotted anomaly is DESEASONALIZED (monthly value minus the
%     2016-2025 mean of the SAME calendar month), NOT overall-mean anomaly.
%   - No new data processing: plotted values come from Stage 02 MAT.
%   - SST Oct-Nov 2025 is NaN for all regions; no interpolation / bridging.
%   - SST December 2025 IS present, displayed as isolated markers.
%   - Rainfall data remains available throughout all 120 months.
%   - Means are arithmetic regional means; no area weighting.
%% ========================================================================
clc;
close all;

%% 1. Locate Stage 02 data from the script location
script_path = mfilename('fullpath');
if isempty(script_path)
    error('Save the script first as b_figure2_seasonal_patterns.m.');
end
out_dir = fileparts(script_path);
data_dir = fileparts(out_dir);
in_file = fullfile(data_dir,'02_Regional_Timeseries','regional_anomalies.mat');
assert(isfile(in_file),'Missing Stage 02 input: %s',in_file);

D = load(in_file);
needed = {'time','SST','RAIN','SST_calendar_mean','RAIN_calendar_mean', ...
          'SST_deseason','RAIN_deseason','N_SST_calendar','N_RAIN_calendar'};
for k=1:numel(needed)
    assert(isfield(D,needed{k}),'Required MATLAB variable missing: %s',needed{k});
end

time = D.time(:);
SST = double(D.SST);
RAIN = double(D.RAIN);
SST_calendar_mean = double(D.SST_calendar_mean);
RAIN_calendar_mean = double(D.RAIN_calendar_mean);
SST_deseason = double(D.SST_deseason);
RAIN_deseason = double(D.RAIN_deseason);
N_SST_calendar = double(D.N_SST_calendar);
N_RAIN_calendar = double(D.N_RAIN_calendar);
regions = {'Flores','Sumba','Timor'};

%% 2. Reproducibility and input checks
assert(isdatetime(time) && numel(time)==120, ...
       'Time vector must contain exactly 120 MATLAB datetime values.');
expected_time = datetime(2016,1,1) + calmonths((0:119)');
assert(all(time==expected_time),'Unexpected monthly calendar positions.');
assert(isequal(size(SST),[120 3]) && isequal(size(RAIN),[120 3]), ...
       'Expected SST and RAIN of size 120x3.');
assert(isequal(size(SST_calendar_mean),[12 3]) && ...
       isequal(size(RAIN_calendar_mean),[12 3]), ...
       'Expected 12x3 climatology matrices.');
assert(isequal(size(SST_deseason),[120 3]) && ...
       isequal(size(RAIN_deseason),[120 3]), ...
       'Expected 120x3 deseasonalized anomaly matrices.');
assert(isequal(size(N_SST_calendar),[12 3]) && ...
       isequal(size(N_RAIN_calendar),[12 3]), ...
       'Expected 12x3 month-availability matrices.');

missing_expected = (year(time)==2025) & ismember(month(time),[10 11]);
dec2025 = (year(time)==2025 & month(time)==12);
assert(sum(missing_expected)==2 && sum(dec2025)==1, ...
       'Cannot locate the missing SST months and December 2025.');
assert(all(all(isnan(SST(missing_expected,:)))) && ...
       all(all(isnan(SST_deseason(missing_expected,:)))), ...
       'SST Oct-Nov 2025 must remain missing (NaN).');
assert(all(all(isfinite(SST(~missing_expected,:)))) && ...
       all(all(isfinite(SST_deseason(~missing_expected,:)))) && ...
       all(all(isfinite(SST(dec2025,:)))) && ...
       all(isfinite(RAIN(:))) && all(isfinite(RAIN_deseason(:))), ...
       'An unexpected missing or non-finite data value was found.');
assert(all(all(N_RAIN_calendar==10)) && ...
       all(all(N_SST_calendar(10:11,:)==9)) && ...
       all(all(N_SST_calendar([1:9 12],:)==10)), ...
       'Calendar-month observation counts do not match the data inventory.');

% Independent numerical check: stored deseasonalization is consistent
% with each regional study-period calendar-month mean.
max_sst_difference = 0;
max_rain_difference = 0;
for mo=1:12
    ix = (month(time)==mo);
    calc_s = SST(ix,:) - SST_calendar_mean(mo,:);
    calc_p = RAIN(ix,:) - RAIN_calendar_mean(mo,:);
    ds = abs(calc_s - SST_deseason(ix,:));
    dp = abs(calc_p - RAIN_deseason(ix,:));
    ds = ds(isfinite(ds));
    dp = dp(isfinite(dp));
    max_sst_difference = max(max_sst_difference,max(ds));
    max_rain_difference = max(max_rain_difference,max(dp));
end
assert(max_sst_difference<1e-8 && max_rain_difference<1e-8, ...
       'Stored deseasonalized anomaly differs from its Stage 02 definition.');

fprintf('\n===== FIGURE 2 INPUT QC =====\n');
fprintf('Source: %s\n',in_file);
fprintf('Period: January 2016 - December 2025 (120 calendar positions).\n');
fprintf('SST: %d valid months per region; rainfall: %d per region.\n', ...
        sum(isfinite(SST(:,1))),sum(isfinite(RAIN(:,1))));
fprintf('Missing SST: Oct-Nov 2025 only; Dec 2025 is present.\n');
fprintf('Climatology counts: SST Oct-Nov n=9, other SST n=10, rain n=10.\n');
fprintf('Anomaly re-check: SST max abs diff=%.3g C; rain=%.3g mm/month.\n', ...
        max_sst_difference,max_rain_difference);

%% 3. Manuscript style: three distinguishable regions in color AND line type
font_name = 'Arial';
font_size = 12;
label_size = 13;
line_w = 1.65;
colors = [0.05 0.40 0.70; ...  % Flores: blue
          0.82 0.29 0.12; ...  % Sumba: dark orange
          0.48 0.36 0.10];     % Timor: dark ochre (white-paper contrast)
styles  = {'-','--','-.'};
markers = {'o','s','^'};

% Larger right-hand time series panels preserve the old Figure 2 layout.
fig = figure('Color','white','Units','pixels', ...
             'Position',[70 70 1900 950], 'Renderer','painters');
axA = axes('Parent',fig,'Units','normalized','Position',[0.060 0.575 0.282 0.345]);
axB = axes('Parent',fig,'Units','normalized','Position',[0.060 0.125 0.282 0.345]);
axC = axes('Parent',fig,'Units','normalized','Position',[0.415 0.575 0.540 0.345]);
axD = axes('Parent',fig,'Units','normalized','Position',[0.415 0.125 0.540 0.345]);
axes_list = [axA axB axC axD];
for j=1:4
    set(axes_list(j),'FontName',font_name,'FontSize',font_size, ...
        'LineWidth',0.9,'TickDir','out','Box','on', ...
        'XGrid','on','YGrid','on','GridColor',[0.75 0.75 0.75], ...
        'GridAlpha',0.25,'Layer','top');
    hold(axes_list(j),'on');
end
month_names = {'Jan','Feb','Mar','Apr','May','Jun', ...
               'Jul','Aug','Sep','Oct','Nov','Dec'};

%% 4. Panel (a): 2016-2025 SST calendar-month means
for r=1:3
    plot(axA,1:12,SST_calendar_mean(:,r), ...
         'Color',colors(r,:),'LineStyle',styles{r}, ...
         'Marker',markers{r},'MarkerSize',5.0, ...
         'LineWidth',line_w,'MarkerFaceColor','white');
end
xlim(axA,[1 12]);
set(axA,'XTick',1:12,'XTickLabel',month_names,'XTickLabelRotation',0);
all_a = SST_calendar_mean(:);
y_a = [floor((min(all_a)-0.25)*2)/2,ceil((max(all_a)+0.25)*2)/2];
ylim(axA,y_a);
ylabel(axA,'SST (^{\circ}C)','FontSize',label_size);
add_panel_label(axA,'(a)',font_size+4);

%% 5. Panel (b): 2016-2025 rainfall calendar-month means
for r=1:3
    plot(axB,1:12,RAIN_calendar_mean(:,r), ...
         'Color',colors(r,:),'LineStyle',styles{r}, ...
         'Marker',markers{r},'MarkerSize',5.0, ...
         'LineWidth',line_w,'MarkerFaceColor','white');
end
xlim(axB,[1 12]);
set(axB,'XTick',1:12,'XTickLabel',month_names,'XTickLabelRotation',0);
ylim(axB,[0,ceil(max(RAIN_calendar_mean(:))*1.08/50)*50]);
ylabel(axB,'Rainfall (mm month^{-1})','FontSize',label_size);
xlabel(axB,'Calendar month','FontSize',label_size);
add_panel_label(axB,'(b)',font_size+4);

%% 6. Time axis: numeric MATLAB datenum is reliable for patch/shaded gaps
x = datenum(time);
year_ticks = [2016 2018 2020 2022 2024 2025];
x_year_ticks = datenum(year_ticks,1,1);
year_labels = arrayfun(@(v) sprintf('%d',v),year_ticks,'UniformOutput',false);
right_x_limits = [datenum(2016,1,1),datenum(2025,12,31)];

%% 7. Panel (c): monthly DESEASONALIZED SST anomalies, NOT detrended
hC = gobjects(1,3);
for r=1:3
    % MATLAB automatically breaks a line on each NaN. Thus no Oct-Nov
    % 2025 line segment is drawn between September and December.
    hC(r) = plot(axC,x,SST_deseason(:,r), ...
                 'Color',colors(r,:),'LineStyle',styles{r}, ...
                 'LineWidth',line_w);
end
ylim_c = ceil(max(abs(SST_deseason(:)))*2.15)/2;
ylim(axC,[-ylim_c ylim_c]);
xlim(axC,right_x_limits);
set(axC,'XTick',x_year_ticks,'XTickLabel',year_labels);
ylabel(axC,'SST anomaly (^{\circ}C)','FontSize',label_size);
yline(axC,0,':','Color',[0.45 0.45 0.45], ...
      'LineWidth',1.0,'HandleVisibility','off');

% Highlight EXACTLY the two unavailable SST calendar months.
% At a decade-long scale the band is necessarily thin, so an explanatory
% annotation is included as well. Never replace NaNs with zeros or join.
gap_start = datenum(2025,10,1);
gap_end = datenum(2025,12,1);
h_gap = patch(axC,[gap_start gap_end gap_end gap_start], ...
                   [-ylim_c -ylim_c ylim_c ylim_c], ...
                   [0.91 0.91 0.91], ...
                   'FaceAlpha',1.0,'EdgeColor','none', ...
                   'HandleVisibility','off');
uistack(h_gap,'bottom');

% Plot Dec 2025 separately: the NaN gap makes it an isolated observation,
% which would otherwise not be visible when plot() draws only line segments.
for r=1:3
    plot(axC,x(dec2025),SST_deseason(dec2025,r), ...
         'LineStyle','none','Marker',markers{r}, ...
         'MarkerSize',6,'MarkerFaceColor',colors(r,:), ...
         'MarkerEdgeColor','white','HandleVisibility','off');
end
legend(axC,hC,regions,'Location','northeast', ...
       'Orientation','horizontal','Box','off','FontName',font_name, ...
       'FontSize',font_size-1);
text(axC,0.99,0.065, ...
    'SST Oct-Nov 2025 missing (shaded); Dec 2025 as points', ...
    'Units','normalized','HorizontalAlignment','right', ...
    'FontName',font_name,'FontSize',10,'Color',[0.25 0.25 0.25], ...
    'BackgroundColor','white','Margin',2);
add_panel_label(axC,'(c)',font_size+4);

%% 8. Panel (d): monthly DESEASONALIZED rainfall anomalies
for r=1:3
    plot(axD,x,RAIN_deseason(:,r), ...
         'Color',colors(r,:),'LineStyle',styles{r}, ...
         'LineWidth',line_w);
end
ylim_d = ceil(max(abs(RAIN_deseason(:)))*1.10/50)*50;
ylim(axD,[-ylim_d ylim_d]);
xlim(axD,right_x_limits);
set(axD,'XTick',x_year_ticks,'XTickLabel',year_labels);
ylabel(axD,'Rainfall anomaly (mm month^{-1})','FontSize',label_size);
xlabel(axD,'Year','FontSize',label_size);
yline(axD,0,':','Color',[0.45 0.45 0.45], ...
      'LineWidth',1.0,'HandleVisibility','off');
add_panel_label(axD,'(d)',font_size+4);

%% 9. Figure-specific data/QC (does not overwrite Stage 02)
Region = regions(:);
Valid_SST_months = sum(isfinite(SST),1)';
Valid_Rain_months = sum(isfinite(RAIN),1)';
Missing_SST_Oct2025 = isnan(SST(missing_expected & month(time)==10,:))';
Missing_SST_Nov2025 = isnan(SST(missing_expected & month(time)==11,:))';
Available_SST_Dec2025 = isfinite(SST(dec2025,:))';
QC = table(Region,Valid_SST_months,Valid_Rain_months, ...
           Missing_SST_Oct2025,Missing_SST_Nov2025, ...
           Available_SST_Dec2025);
writetable(QC,fullfile(out_dir,'Figure_2_Data_QC.csv'));
save(fullfile(out_dir,'Figure_2_Plot_Data.mat'), ...
     'time','SST_calendar_mean','RAIN_calendar_mean', ...
     'SST_deseason','RAIN_deseason', ...
     'N_SST_calendar','N_RAIN_calendar','regions');

%% 10. Export graphics (captions should be added in the manuscript)
drawnow;
file_png = fullfile(out_dir,'Figure_2_Seasonal_Patterns_Anomalies.png');
file_pdf = fullfile(out_dir,'Figure_2_Seasonal_Patterns_Anomalies.pdf');
exportgraphics(fig,file_png,'Resolution',600,'BackgroundColor','white');
exportgraphics(fig,file_pdf,'ContentType','vector','BackgroundColor','white');

fid = fopen(fullfile(out_dir,'Figure_2_Methods_Metadata.txt'),'w');
assert(fid~=-1,'Unable to write Figure 2 metadata.');
fprintf(fid,'Figure 2 data source: %s\n',in_file);
fprintf(fid,'Panels (a),(b): 2016-2025 calendar-month-mean regional SST and rainfall.\n');
fprintf(fid,'Panels (c),(d): 2016-2025 monthly deseasonalized anomalies.\n');
fprintf(fid,'Definition: monthly value minus 2016-2025 mean of the SAME calendar month.\n');
fprintf(fid,'Region order: Flores, Sumba, Timor.\n');
fprintf(fid,'SST: 118 available months; 2025 Oct-Nov NaN and not interpolated.\n');
fprintf(fid,'Rainfall: 120 available months; CHIRPS monthly mm.\n');
fprintf(fid,'Calendar-month SST Oct-Nov base n=9, other SST n=10; rainfall n=10.\n');
fprintf(fid,'December 2025 SST drawn as isolated points after the missing gap.\n');
fprintf(fid,'No overall-mean-anomaly or detrended series are displayed in Figure 2.\n');
fprintf(fid,'Styles: three distinct line types and consistent colors across all panels.\n');
fprintf(fid,'Figure PNG exported at 600 dpi; PDF as vector.\n');
fclose(fid);

fprintf('\n===== FIGURE 2 COMPLETE =====\n');
fprintf('Output PNG: %s\n',file_png);
fprintf('Output PDF: %s\n',file_pdf);
fprintf('Output QC: Figure_2_Data_QC.csv\n');
fprintf('Review on exported PNG: markers for Dec 2025 and grey Oct-Nov gap.\n');

%% Local function for consistent panel letters; R2021a-compatible
function add_panel_label(ax,tag,size_pt)
    text(ax,0.017,0.95,tag,'Units','normalized', ...
        'FontName','Arial','FontSize',size_pt,'FontWeight','bold', ...
        'VerticalAlignment','top','HorizontalAlignment','left', ...
        'Color',[0 0 0],'BackgroundColor','white','Margin',1);
end
