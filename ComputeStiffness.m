%% House Keeping
clc
clear all
close all

%% Load the files

[inInsFile,inInsPath] = uigetfile([filesep,'media',filesep,'Test_Data',filesep,'Ins_*.mat'],'Please select an Instron data file');
if exist([inInsPath,'DT_',inInsFile(5:10),'_Processed_filtfilt.mat'],'file')         % check if the expected drop tower file is with the instron file, if not ask user to locate
    inDTForceFile = ['DT_',inInsFile(5:10),'_Processed_filtfilt.mat'];
    inDTForcePath = inInsPath;
else
    [inDTForceFile,inDTForcePath] = uigetfile([inInsPath,'DT_*.mat'],'Please select a DT force file');
end
if exist([inInsPath,'DT_',inInsFile(5:10),'_TEMA_Displacement_Processed_filtfilt.mat'],'file') % check if the expected drop tower file is with the instron file, if not ask user to locate
    inDTDispFile = ['DT_',inInsFile(5:10),'_TEMA_Displacement_Processed_filtfilt.mat'];
    inDTDispPath = inInsPath;
else
    [inDTDispFile,inDTDispPath] = uigetfile([inInsPath,'DT_*TEMA*.mat'],'Please select a DT displacement file');
end

% read the input files
load([inInsPath,inInsFile]);
insTime = time;                                                             % rename the instron time vector to prevent variable name clash with other input file variables
load([inDTForcePath,inDTForceFile]);
dTTime = time;                                                              % rename the drop tower signal data time vector to prevent variable name clash
load([inDTDispPath,inDTDispFile]);
sTime = inputdlg('Please enter the time of the first image of the displacement tracking in ms.','Time alignment',1,{'0'});
sTime = str2num(sTime{1});

%% Interpolate DT the data to the same spacing
DTTimeInterp = linspace(-200,500,10000);                                    % time for the interpolated drop tower

if length(TrackedImpacFilt) > length(TrackedTrochFilt)                      % determine the indexes for data. NANs from the tracking
    indexesDisp = 1:length(TrackedTrochFilt);                               % can result in one vector being shorter than the other.
else
    indexesDisp = 1:length(TrackedImpacFilt);
end

TrackedImpacFilt(:,1) = TrackedImpacFilt(:,1) - TrackedImpacFilt(1,1);      % zero the disp data
TrackedImpacFilt(:,2) = TrackedImpacFilt(:,2) - TrackedImpacFilt(1,2);
TrackedTrochFilt(:,1) = TrackedTrochFilt(:,1) - TrackedTrochFilt(1,1);
TrackedTrochFilt(:,2) = TrackedTrochFilt(:,2) - TrackedTrochFilt(1,2);

DTImpactorDispInterp = interp1(timeDisp(indexesDisp)+sTime,TrackedImpacFilt(indexesDisp,1),DTTimeInterp);   % interpolate the impactor displacement into new time vector
DTTrochDispInterp = interp1(timeDisp(indexesDisp)+sTime,TrackedTrochFilt(indexesDisp,1),DTTimeInterp);      % interpolate the trochanter displacement into new time vector

DTForceInterp = interp1(dTTime(1:length(oneAxis)),oneAxis,DTTimeInterp);                       % interpolate the single axis load cell into the new time vector
DTSixAInterp = interp1(dTTime(1:length(sixAxis(:,3))),sixAxis(:,3),DTTimeInterp);                   % interoplate the six axis load cell into the new time vector

figure(1)
plot(DTTimeInterp,DTTrochDispInterp,DTTimeInterp,DTSixAInterp./1000)
grid
hHold = msgbox('Zoom in to select the start of the impact');
uiwait(hHold);
[x,y] = ginput(1);
usedIndexes = find(DTTimeInterp > x,1,'first'):length(DTTimeInterp);
DTImpactorDispInterp = DTImpactorDispInterp - DTImpactorDispInterp(usedIndexes(1));
DTTrochDispInterp = DTTrochDispInterp - DTTrochDispInterp(usedIndexes(1));

close gcf


%% Calculate the Drop tower stiffness at the max force of the single axis loadcell
dispDefinedRange = usedIndexes(1):find(isnan(DTTrochDispInterp)==0,1,'last');    % find the region of the time vector where displacement is defined
% dispDefinedRange = find(isnan(DTTrochDispInterp)==0,1,'first'):find(isnan(DTTrochDispInterp)==0,1,'last');    % find the region of the time vector where displacement is defined
% [maxF,maxFI] = max(DTForceInterp(dispDefinedRange)); % find the max force in the region where displacement is defined
% maxFI = maxFI+dispDefinedRange(1)-1;                                        % correct index for the limited scope of the displacement defined region
%% select the max force of the more complex time seriese
figure(1)
plot(DTSixAInterp(dispDefinedRange));
hHold = msgbox('Zoom in and click on the peak. The highest value in a window of +/- 5 data points will be used as the max');
grid
uiwait(hHold);
[x,y] = ginput(1);
[maxF,maxFI] = max(DTSixAInterp(floor(dispDefinedRange(1)+x-5):ceil(dispDefinedRange(1)+x+5)));
maxFI = dispDefinedRange(1)+floor(x-5)+maxFI-1;
close gcf

quarterFI = find(DTSixAInterp > DTSixAInterp(maxFI)*.25,1,'first');         % find the index at 25% max force
ninetyFI = find(DTSixAInterp > DTSixAInterp(maxFI)*.9,1,'first');         % find the index at 90% max force
DT_stiffness = (DTSixAInterp(ninetyFI)-DTSixAInterp(quarterFI))/(DTTrochDispInterp(ninetyFI)-DTTrochDispInterp(quarterFI)); % calculate stiffness between 25% and 90% values
DT_yIntercept = DTSixAInterp(ninetyFI)-(DT_stiffness*DTTrochDispInterp(ninetyFI));     % calculate the y-intercept of the linear stiffness fit
DT_loadingRate = (DTTrochDispInterp(ninetyFI)-DTTrochDispInterp(quarterFI))/((DTTimeInterp(ninetyFI)-DTTimeInterp(quarterFI))/1000); % calculate average trochanter velocity between 25% and 90% values
DT_maxF = maxF;                                                             % save the max force value for writing to the data file



%% Calculate the instron stiffness
[maxF,maxFI] = max(-force);                                                 % find the max force in the instron data
quarterFI = find(-force > maxF/2,1,'first');                                % inde the index for 25% of max force
Ins_stiffness = (force(maxFI)-force(quarterFI))/((displacement(maxFI)-displacement(quarterFI))/1000);   % calculate sitffness using 25% and 100% max force
Ins_yIntercept = -force(maxFI)-Ins_stiffness*-displacement(maxFI)/1000;     % find y-intercept of the linear stiffness fit

%% Review results and create an output file with the stiffness in it.
% plot the drop tower force displacement curve
plotPosition = [1684 53 1674 919];

DT_dfFH = figure(1);
DT_dfAX = axes;
plot(DT_dfAX,DTTrochDispInterp(dispDefinedRange),DTSixAInterp(dispDefinedRange)./1000,'r','linewidth',2)
hold on;
cLimits = axis;
xlim([0 10])
ezplotString = sprintf('%f*x + %f',DT_stiffness/1000,DT_yIntercept/1000); % the /1000000 converts from N/m to kN/mm, the /1000 goes from N to kN
DT_slopeH = ezplot(ezplotString,xlim);
set(DT_slopeH,'linewidth',2,'linestyle','--');
grid
xlabel('Trochanter Displacement (mm)','Fontname','times','fontsize',45)
ylabel('Compressive Force (kN)','Fontname','times','fontsize',45)
% title('Drop Tower Displacement vs Force and Stiffness','Fontname','times','fontsize',20)
set(DT_dfAX,'fontname','times','fontsize',40)%,'xlim',[0 5],'ylim',[cLimits(3) cLimits(4)])
legend('Drop Tower','Stiffness')
set(get(DT_dfAX,'title'),'string',[])
ylim([cLimits(3) cLimits(4)])
set(DT_dfFH,'position',plotPosition);


% plot the instron force displacement curve
Ins_dfFH = figure(2);
Ins_dfAX = axes;
plot(Ins_dfAX,-displacement,-force./1000,'r','linewidth',2);
hold on;
cLimits = axis;
xlim([0 1.5])
ezplotString = sprintf('%f*x + %f',Ins_stiffness/1000000,Ins_yIntercept/1000); % the /1000000 converts from N/m to kN/mm, the /1000 goes from N to kN
Ins_slopeH = ezplot(ezplotString,xlim);
set(Ins_slopeH,'linewidth',2,'linestyle','--');
grid
xlabel('Trochanter Displacement (mm)','Fontname','times','fontsize',45)
ylabel('Compressive Force (kN)','Fontname','times','fontsize',45)
% title('Instron Displacement vs Force and Stiffness','Fontname','times','fontsize',20)
set(Ins_dfAX,'fontname','times','fontsize',40,'ylim',[cLimits(3) cLimits(4)])
legend('Quasi-static','Stiffness')
set(get(Ins_dfAX,'title'),'string',[]);
set(Ins_dfFH,'position',plotPosition);

% plot instron and DT on the same axes
Tog_dfFH = figure(3);
Tog_dfAX = axes;
plot(Tog_dfAX,DTTrochDispInterp(dispDefinedRange),DTSixAInterp(dispDefinedRange)./1000,-displacement,-force./1000,'--r','linewidth',2)
grid
xlabel('Trochanter Displacement (mm)','Fontname','times','fontsize',45)
ylabel('Compressive Force (kN)','Fontname','times','fontsize',45)
set(Tog_dfAX,'fontname','times','fontsize',40)
legend('Drop Tower','Quasi-static')
xlim([0 10])
set(Tog_dfFH,'position',plotPosition)

% drop tower force vs time
DT_fvtFH = figure(4);
[AH,H1,H2] = plotyy(DTTimeInterp,DTSixAInterp./1000,DTTimeInterp(dispDefinedRange),DTTrochDispInterp(dispDefinedRange));
set(H1,'linewidth',2)
set(H2,'color','r','linewidth',2)
grid
xlabel('Time (ms)','Fontname','times','fontsize',45)
ylabel('Force (kN)','Fontname','times','fontsize',45)
set(get(AH(2),'ylabel'),'string','Displacement (mm)','fontName','times','fontsize',45)
set(AH(1),'fontname','times','fontsize',40)
set(AH(2),'fontname','times','fontsize',40,'xtick',[],'xticklabel',[],'Ycolor','r')
set(DT_fvtFH,'position',plotPosition)
set(AH(1),'xlim',[10 60])
set(AH(2),'xlim',get(AH(1),'xlim'))

% allow the user to review the results. using an msgbox as it is not modal
% and does not retain focus while open
msgH = msgbox('Please review the plots. Close this box to contiune.','Results Review','help');
uiwait(msgH);

% ask if data is okay. This dialog will retain focus while open.
reviewResult = questdlg('Please review the plots.  Should the data file be written?','Results Review','Yes','No','No');
specimenName = inDTDispPath(strfind(inDTDispPath,'H1'):strfind(inDTDispPath,'H1')+5);       % get the specimen name from the input path

% depending on selection, write data file or quit
switch reviewResult
    case 'Yes'
        if ~exist([inDTDispPath,'..',filesep,'..',filesep,'StiffnessComparisons-2.txt'],'file')   % if the data file does not exist, create and initalize it with the header line.
            outFileID = fopen([inDTDispPath,'..',filesep,'..',filesep,'StiffnessComparisons-2.txt'],'w');
            fprintf(outFileID,'Specimen\tDroptower(N/m)\tInstron(N/m)\tTrochanter_DT_Loading_Rate_(m/s)\tMax_DT_Force_(N)\tDXA_Score\tDXA_Classification\n');
        else
            outFileID = fopen([inDTDispPath,'../../StiffnessComparisons-2.txt'],'a+');
        end
        fprintf(outFileID,'%s\t%14.0f\t%14.0f\t%32f\t%16.0f\r\n',specimenName,DT_stiffness*1000,Ins_stiffness,DT_loadingRate./1000,DT_maxF);
        fclose(outFileID);
        
    case 'No'
        msgH = msgbox('The action was cancelled, no results were written','Cancellation Notification','warn');
        uiwait(msgH,30);
end

% % Save the figures
% if ~exist([inDTDispPath,filesep,'..',filesep,'Plots'],'dir')
%     mkdir([inDTDispPath,filesep,'..'],'Plots')
% end
% outPlotDTtime = sprintf('%s_DT_ForceVsTime',specimenName);
% set(DT_fvtFH,'position',[1 1 3360 1050],'paperpositionmode','auto');
% print(DT_fvtFH,'-dpng','-r100',[inDTDispPath,'../Plots/',outPlotDTtime,'_lowRes.png'])
% print(DT_fvtFH,'-dpng','-r300',[inDTDispPath,'../Plots/',outPlotDTtime,'_higRes.png'])
% saveas(DT_fvtFH,[inDTDispPath,'../Plots/',outPlotDTtime],'fig');
%
% outPlotDT = sprintf('%s_DT_ForceDisp',specimenName);
% outPlotIns = sprintf('%s_Ins_ForceDisp',specimenName);
% outPlotTog = sprintf('%s_Tog_ForceDisp',specimenName);
%
% set(DT_dfFH,'position',[1 1 3360 1050],'paperpositionmode','auto');
% set(Tog_dfFH,'position',[1 1 3360 1050],'paperpositionmode','auto');
% set(Ins_dfFH,'position',[1 1 3360 1050],'paperpositionmode','auto');
% 
% print(DT_dfFH,'-dpng','-r100',[inDTDispPath,'../Plots/',outPlotDT,'_lowRes.png'])
% print(Ins_dfFH,'-dpng','-r100',[inDTDispPath,'../Plots/',outPlotIns,'_lowRes.png'])
% print(Tog_dfFH,'-dpng','-r100',[inDTDispPath,'../Plots/',outPlotTog,'_lowRes.png'])
% 
% print(DT_dfFH,'-dpng','-r300',[inDTDispPath,'../Plots/',outPlotDT,'_highRes.png'])
% print(Ins_dfFH,'-dpng','-r300',[inDTDispPath,'../Plots/',outPlotIns,'_higRes.png'])
% print(Tog_dfFH,'-dpng','-r300',[inDTDispPath,'../Plots/',outPlotTog,'_higRes.png'])
% 
% saveas(DT_dfFH,[inDTDispPath,'../Plots/',outPlotDT],'fig');
% saveas(Ins_dfFH,[inDTDispPath,'../Plots/',outPlotIns],'fig');
% saveas(Tog_dfFH,[inDTDispPath,'../Plots/',outPlotTog],'fig');

