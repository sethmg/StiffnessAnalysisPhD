clc
clear all
close all

inputFile = '../StiffnessComparisons-2.txt';
if ~exist(inputFile,'file')                                                 % if the input file is not in the root dir, get the user to find it for you
    [inputFileName,inputPathName] = uigetfile('*.txt','The input file could not be found. Please select the stiffness comparisons file');
    inputFile = [inputPathName,inputFileName];
end
inputFileID = fopen(inputFile,'r');
C = textscan(inputFileID,'%s\t%f\t%f\t%f\t%f\t%f\t%s','headerlines',1);

% [specimenNames,DT_Stiffness,In_Stiffness,DT_LoadingRate,DT_Max,DXA,OP_Status] = textscan(inputFile,'%s\t%f\t%f\t%f\t%f\t%f\t%s','headerlines',1);
% Put the data into sensible variables. Check the input file if one of these seems strange
specimenNames = C{:,1};                                                     %OIBG Specimen Name
DT_Stiffness = C{:,2};                                                      % Stiffness calculated from the drop tower, N/m
In_Stiffness = C{:,3};                                                      % Stiffness calculated from the instron, N/m
DT_LoadingRate = C{:,4};                                                    % Trochanter velocity calculated from the drop tower, m/s
DT_Max = C{:,5};                                                            % Max force in drop tower, N
DXA = C{:,6};                                                               % Total aBMD by DXA g/cm^2 
OP_Status = C{:,7};                                                         % As determined by Hologic QDR 4500W (S/N 49757)

% get indexes of the specimens with the key OP statuses
insValid = logical(In_Stiffness);
dtValid =  logical(DT_Stiffness);
bothValid = logical(In_Stiffness.*DT_Stiffness);
% exclude H1268L DT due to the impact of the bypass masses on the spring
H1268L_index = find(strcmp(specimenNames,'H1268L'));
dtValid( H1268L_index ) = 0;
bothValid( H1268L_index ) = 0;

normal_Indexes = false(length(OP_Status),1);                                % logical indexes to the normal density bones
normal_Indexes( strcmp(OP_Status,'Normal') ) = 1;                           
normal_insValid = false(length(OP_Status),1);                               % logical indexes to normal density bones that have valid instron data
normal_insValid( insValid & normal_Indexes ) = 1;
normal_dtValid = false(length(OP_Status),1);                                % logical indexes to normal density bones that have valid drop tower data
normal_dtValid( dtValid & normal_Indexes ) = 1;
normal_bothValid = false(length(OP_Status),1);                              % logical indexes to normal dinsity bones that have instron and drop tower data
normal_bothValid( bothValid & normal_Indexes ) = 1;
% exclude H1268L DT due to the impact of the bypass masses on the spring
normal_dtValid( H1268L_index ) = 0;
normal_bothValid( H1268L_index ) = 0;

osteopenic_Indexes = false(length(OP_Status),1);                            % logical indexes for osteopenic bones, formulated like the normal density data
osteopenic_Indexes( strcmp(OP_Status,'Osteopenia') ) = 1;
osteopenic_insValid = false(length(OP_Status),1);
osteopenic_insValid( insValid & osteopenic_Indexes ) = 1;
osteopenic_dtValid = false(length(OP_Status),1);
osteopenic_dtValid( dtValid & osteopenic_Indexes ) = 1;
osteopenic_bothValid = false(length(OP_Status),1);
osteopenic_bothValid( bothValid & osteopenic_Indexes ) = 1;
% exclude H1268L DT due to the impact of the bypass masses on the spring
osteopenic_dtValid( H1268L_index ) = 0;
osteopenic_bothValid( H1268L_index ) = 0;

osteoporotic_Indexes = false(length(OP_Status),1);                          % logical indexes for osteoporotic bones, formulated like the normal density data
osteoporotic_Indexes( strcmp(OP_Status,'Osteoporosis') ) = 1;
osteoporotic_insValid = false(length(OP_Status),1);
osteoporotic_insValid (insValid & osteoporotic_Indexes ) = 1;
osteoporotic_dtValid = false(length(OP_Status),1);
osteoporotic_dtValid( dtValid & osteoporotic_Indexes ) = 1;
osteoporotic_bothValid = false(length(OP_Status),1);
osteoporotic_bothValid( bothValid & osteoporotic_Indexes ) = 1;
% exclude H1268L DT due to the impact of the bypass masses on the spring
osteoporotic_dtValid( H1268L_index ) = 0;
osteoporotic_bothValid( H1268L_index ) = 0;


%% Loading Rate Plots
delta_Stiffness = DT_Stiffness - In_Stiffness;
% plotPositions = get(0,'screensize');
plotPositions = [         21          40        1628         904];


% Plot Change in stiffness, grouped by OP status
deltaOPFH = figure(1);
set(deltaOPFH,'position',plotPositions,'paperpositionMode','auto');
deltaOPAH = axes;
hold on
plot(deltaOPAH,DT_LoadingRate(normal_bothValid)*1000,delta_Stiffness(normal_bothValid)/1000,'go','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(deltaOPAH,DT_LoadingRate(osteopenic_bothValid)*1000,delta_Stiffness(osteopenic_bothValid)/1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(deltaOPAH,DT_LoadingRate(osteoporotic_bothValid)*1000,delta_Stiffness(osteoporotic_bothValid)/1000,'rx','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
grid
set(deltaOPAH,'Fontname','times','fontsize',40)
xlabel('Loading Rate (mm/s)','Fontname','times','fontsize',45)
ylabel('Change in Stiffness (N/mm)','Fontname','times','fontsize',45)
xlim([0 800])
deltaOPLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic');
% fit the pooled dataset
% [lR_dSFit,lR_dS_goodness] = fit(DT_LoadingRate*1000,delta_Stiffness/1000,'poly1');
[lR_dSFit,lR_dS_goodness] = fit(DT_LoadingRate(bothValid),delta_Stiffness(bothValid),'poly1');
if lR_dS_goodness.rsquare > 0.2
    hold on
    plot(sort(DT_LoadingRate(bothValid)*1000),feval(lR_dSFit,sort(DT_LoadingRate(bothValid)))/1000,'k','linewidth',2)
    %text(700,0,sprintf('%0.3f * Loading Rate + %0.0f, r^2 = %0.3f',lR_dSFit.p1,lR_dSFit.p2,lR_dS_goodness.rsquare),'fontname','times','fontsize',20);
end
 
% Plot change in stiffness relative to the instron stiffness, grouped by OP status
relOPFH = figure(2);
set(relOPFH,'position',plotPositions,'paperpositionMode','auto');
relOPAH = axes;
hold on
plot(relOPAH,DT_LoadingRate(normal_bothValid)*1000,delta_Stiffness(normal_bothValid)./In_Stiffness(normal_bothValid)*100,'go','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(relOPAH,DT_LoadingRate(osteopenic_bothValid)*1000,delta_Stiffness(osteopenic_bothValid)./In_Stiffness(osteopenic_bothValid)*100,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(relOPAH,DT_LoadingRate(osteoporotic_bothValid)*1000,delta_Stiffness(osteoporotic_bothValid)./In_Stiffness(osteoporotic_bothValid)*100,'rx','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
grid
set(relOPAH,'Fontname','times','fontsize',40)
xlabel('Loading Rate (mm/s)','Fontname','times','fontsize',45)
ylabel('$\frac{Stiffness_{(DT)}-Stiffness_{(Instron)}}{Stiffness_{(Instron)}} * 100$','Fontname','times','fontsize',45,'interpreter','latex')
xlim([0 800])
relOPLH = legend('WHO Normal aBMD','WHO Osteopenic');%,'WHO Osteoporotic');
% fit the pooled dataset
[lR_rSFit,lR_rS_goodness] = fit(DT_LoadingRate(bothValid),(delta_Stiffness(bothValid)./In_Stiffness(bothValid)),'poly1');
if lR_rS_goodness.rsquare > 0.2
    hold on
    plot(relOPAH,sort(DT_LoadingRate(bothValid))*1000,feval(lR_rSFit,sort(DT_LoadingRate(bothValid)))*100,'k','linewidth',2)
    %text(100,-80,sprintf('%0.3f * Loading Rate (m/s) + %0.0f, r^2 = %0.3f',lR_rSFit.p1,lR_rSFit.p2,lR_rS_goodness.rsquare),'fontname','times','fontsize',20);
end
cPosition = get(relOPAH,'position');
cPosition(1) = .15;
cPosition(3) = .78;
set(relOPAH,'position',cPosition)

% Plot max force grouped by OP status
maxOPFH = figure(3);
set(maxOPFH,'position',plotPositions,'paperpositionMode','auto');
maxOPAH = axes;
hold on
plot(maxOPAH,DT_LoadingRate(normal_dtValid)*1000,DT_Max(normal_dtValid)/1000,'go','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(maxOPAH,DT_LoadingRate(osteopenic_dtValid)*1000,DT_Max(osteopenic_bothValid)/1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(maxOPAH,DT_LoadingRate(osteoporotic_dtValid)*1000,DT_Max(osteoporotic_dtValid)/1000,'rx','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
grid
set(maxOPAH,'Fontname','times','fontsize',40)
xlabel('Loading Rate (mm/s)','Fontname','times','fontsize',45)
ylabel('Max Force (kN)','Fontname','times','fontsize',45)
xlim([0 800])
maxOPLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic');


%% Bone Density Plots
% Plot max force grouped by OP status
maxFH = figure(4);
set(maxFH,'position',plotPositions,'paperpositionMode','auto');
maxAH = axes;
hold on
plot(maxAH,DXA(normal_dtValid),DT_Max(normal_dtValid)/1000,'go','markersize',20,'linewidth',5);
plot(maxAH,DXA(osteopenic_dtValid),DT_Max(osteopenic_dtValid)/1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5);
plot(maxAH,DXA(osteoporotic_dtValid),DT_Max(osteoporotic_dtValid)/1000,'rx','markersize',20,'linewidth',5);
grid
set(maxAH,'Fontname','times','fontsize',40)
xlabel('DXA (g/cm^2)','Fontname','times','fontsize',45)
ylabel('Max Force (kN)','Fontname','times','fontsize',45)
maxLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic','location','northwest');
% fit the pooled dataset
[ro_mFFit,ro_mF_goodness] = fit(DXA(dtValid),DT_Max(dtValid),'poly1');
if ro_mF_goodness.rsquare > 0.2
    hold on
    plot(maxAH,sort(DXA(dtValid)),feval(ro_mFFit,sort(DXA(dtValid)))/1000,'k','linewidth',2)
    %text(.75,2500,sprintf('%0.0f * DXA + %0.0f, r^2 = %0.3f',ro_mFFit.p1,ro_mFFit.p2,ro_mF_goodness.rsquare),'fontname','times','fontsize',20);
end

% Plot loading rate, grouped by OP status
rateFH = figure(5);
set(rateFH,'position',plotPositions,'paperpositionMode','auto');
rateAH = axes;
hold on
plot(rateAH,DXA(normal_dtValid),DT_LoadingRate(normal_dtValid)*1000,'og','markersize',20,'linewidth',5); % dxa in g/cm^2, rate in mm/s
plot(rateAH,DXA(osteopenic_dtValid),DT_LoadingRate(osteopenic_dtValid)*1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(rateAH,DXA(osteoporotic_dtValid),DT_LoadingRate(osteoporotic_dtValid)*1000,'rx','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
grid
set(rateAH,'Fontname','times','fontsize',40)
ylabel('Loading Rate (mm/s)','Fontname','times','fontsize',45)
xlabel('DXA (g/cm^2)','Fontname','times','fontsize',45)
rateLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic');

% Plot change in stiffness, grouped by OP status
diffFH = figure(6);
set(diffFH,'position',plotPositions,'paperpositionMode','auto');
diffAH = axes;
hold on
plot(diffAH,DXA(normal_bothValid),delta_Stiffness(normal_bothValid)/1000,'go','markersize',20,'linewidth',5);
plot(diffAH,DXA(osteopenic_bothValid),delta_Stiffness(osteopenic_bothValid)/1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5);
plot(diffAH,DXA(osteoporotic_bothValid),delta_Stiffness(osteoporotic_bothValid)/1000,'rx','markersize',20,'linewidth',5);
grid
set(diffAH,'Fontname','times','fontsize',40)
xlabel('DXA (g/cm^2)','Fontname','times','fontsize',45)
ylabel('Stiffness Change (N/mm)','Fontname','times','fontsize',45)
diffLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic','location','northwest');

% stiffness change bland-altman plot
meanStiffness = (DT_Stiffness+In_Stiffness)/2;
f7H = figure(7);
a7H = axes;
set(f7H,'position',plotPositions,'paperpositionMode','auto');
hold on
plot(a7H,meanStiffness(normal_bothValid)/1000,delta_Stiffness(normal_bothValid)/1000,'go','markersize',20,'linewidth',5);
plot(a7H,meanStiffness(osteopenic_bothValid)/1000,delta_Stiffness(osteopenic_bothValid)/1000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5);
plot(a7H,meanStiffness(osteoporotic_bothValid)/1000,delta_Stiffness(osteoporotic_bothValid)/1000,'rx','markersize',20,'linewidth',5);
[delta_mean,delta_sigma,delta_meanci,delta_sigmaci] = normfit(delta_Stiffness(bothValid));
xlimits = xlim;
plot(a7H,xlimits,[delta_mean delta_mean]/1000,'k','linewidth',4);
plot(a7H,xlimits,[delta_meanci(1) delta_meanci(1)]/1000,'color',[.7 .7 .7],'linewidth',4)
plot(a7H,xlimits,[delta_meanci(2) delta_meanci(2)]/1000,'color',[.7 .7 .7],'linewidth',4)
xlim(xlimits)
grid
set(a7H,'Fontname','times','fontsize',40)
xlabel('Mean Stiffness (N/mm)','Fontname','times','fontsize',45)
ylabel('Stiffness Change (N/mm)','Fontname','times','fontsize',45)
diffLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic','location','northwest');

% plot stiffness vs loading rate, grouped by OP status
f8H = figure(8);
set(f8H,'position',plotPositions,'paperpositionMode','auto');
a8H = axes;
hold on
plot(a8H,DT_LoadingRate(normal_dtValid)*1000,DT_Stiffness(normal_dtValid)/1000000,'og','markersize',20,'linewidth',5); % dxa in g/cm^2, rate in mm/s
plot(a8H,DT_LoadingRate(osteopenic_dtValid)*1000,DT_Stiffness(osteopenic_dtValid)/1000000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
plot(a8H,DT_LoadingRate(osteoporotic_dtValid)*1000,DT_Stiffness(osteoporotic_dtValid)/1000000,'rx','markersize',20,'linewidth',5); % loading rate in mm/s, siffness in N/mm
grid
set(a8H,'Fontname','times','fontsize',40)
xlabel('Loading Rate (mm/s)','Fontname','times','fontsize',45)
ylabel('Stiffness (kN/mm)','Fontname','times','fontsize',45)
rateLH = legend('WHO Normal aBMD','WHO Osteopenic','WHO Osteoporotic');
[a8Fit,a8_goodness] = fit(DT_LoadingRate(dtValid),DT_Stiffness(dtValid),'poly1');
if a8_goodness.rsquare > 0.2
    hold on
    plot(a8H,sort(DT_LoadingRate(dtValid))*1000,feval(a8Fit,sort(DT_LoadingRate(dtValid)))/1000000,'k','linewidth',2)
    %text(.75,2500,sprintf('%0.0f * DXA + %0.0f, r^2 = %0.3f',ro_mFFit.p1,ro_mFFit.p2,ro_mF_goodness.rsquare),'fontname','times','fontsize',20);
end
% bar showing low rate stiffness
barH = bar(20,mean(In_Stiffness(insValid))/1000000,'r');
set(barH,'barWidth',25)
whiskerX = [get(barH,'XData') get(barH,'XData')];
whiskerY = [mean(In_Stiffness(insValid)) + std(In_Stiffness(insValid)) mean(In_Stiffness(insValid)) - std(In_Stiffness(insValid))]/1000000;
plot(a8H,whiskerX,whiskerY,'k','linewidth',3)
% bar showing stiffness under 200 mm/s
barH2 = bar(50, mean(DT_Stiffness(find(DT_LoadingRate < 0.2 & dtValid)))/1000000,'g');
set(barH2,'barWidth',25)
whiskerX = [get(barH2,'Xdata') get(barH2,'Xdata')];
whiskerY = [get(barH2,'Ydata')+ std(DT_Stiffness(find(DT_LoadingRate < 0.2 & dtValid)))/1000000 get(barH2,'Ydata')-std(DT_Stiffness(find(DT_LoadingRate < 0.2 & dtValid)))/1000000];
plot(a8H,whiskerX,whiskerY,'k','linewidth',3)

% % Plot the DT stiffness on the x and Ins on the Y, along with a line of y = x
fH9 = figure(9);
aH9 = axes;
hold on;
plot(aH9,DT_Stiffness(osteoporotic_bothValid)./1000000, In_Stiffness(osteoporotic_bothValid)./1000000,'rx','markersize',20,'linewidth',5)
plot(aH9,DT_Stiffness(osteopenic_bothValid)./1000000, In_Stiffness(osteopenic_bothValid)./1000000,'s','markeredgecolor',[1 .5 .2],'markersize',20,'linewidth',5)
plot(aH9,DT_Stiffness(normal_bothValid)./1000000, In_Stiffness(normal_bothValid)./1000000,'go','markersize',20','linewidth',5)
axis square
xlim([0 6]);
ylim([0 6]);
ezH9 = ezplot('x',[0 6]);
set(ezH9,'linewidth',3);
set(fH9,'position',plotPositions,'paperpositionmode','auto');
grid
set(aH9,'Fontname','times','fontsize',40);
xlabel('Fall Simulator Stiffness (kN/mm)','fontname','times','fontsize',40);
ylabel('Quasi-Static Stiffness (kN/mm)','fontname','times','fontsize',40);
set(aH9,'xtick',get(aH9,'ytick'),'xticklabel',get(aH9,'yticklabel'));
set(get(aH9,'title'),'string',[])
legend('Osteoporotic','Osteopenic','Normal');
print(fH9,'../DT_StiffnessVsIn_Stiffness_HighRes.png','-r300','-dpng');
print(fH9,'../DT_StiffnessVsIn_Stiffness_LowhRes.png','-r100','-dpng');
saveas(fH9,'../DT_StiffnessVsIn_Stiffness.fig');

%% Statistics based on OP Status groups

% one way anova to see if one OP group had higher loading rates
% OP_LRanova = anova1(DT_LoadingRate,OP_Status);


% one way anova to see if one OP group softened more
% OP_DSanova = anova1(delta_Stiffness,OP_Status);

% t-test to see if stiffness is the same in DT and Ins
%[stiff_h,stiff_p,stiff_ci,stiff_stats] =  ttest2(DT_Stiffness(dtValid),In_Stiffness(insValid));

% one way anove to see if DT bones are softer than instron bones
% DT_INanova = anova1([DT_Stiffness,In_Stiffness]);