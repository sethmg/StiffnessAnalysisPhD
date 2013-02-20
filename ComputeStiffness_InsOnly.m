%% House Keeping
clc
clear all
close all

%% Load the files

[inInsFile,inInsPath] = uigetfile('/media/Test_Data/Ins_*.mat','Please select an Instron data file');

% read the input files
load([inInsPath,inInsFile]);
insTime = time;                                                             % rename the instron time vector to prevent variable name clash with other input file variables

%% Calculate the instron stiffness
[maxF,maxFI] = max(-force);                                                 % find the max force in the instron data
quarterFI = find(-force > maxF/2,1,'first');                                % inde the index for 25% of max force
Ins_stiffness = (force(maxFI)-force(quarterFI))/((displacement(maxFI)-displacement(quarterFI))/1000);   % calculate sitffness using 25% and 100% max force
Ins_yIntercept = -force(maxFI)-Ins_stiffness*-displacement(maxFI)/1000;     % find y-intercept of the linear stiffness fit

%% Review results and create an output file with the stiffness in it.
% plot the instron force displacement curve
Ins_dfFH = figure(2);
Ins_dfAX = axes;
plot(Ins_dfAX,-displacement,-force./1000,'r','linewidth',2);
hold on;
cLimits = axis;
ezplotString = sprintf('%f*x + %f',Ins_stiffness/1000000,Ins_yIntercept/1000); % the /1000000 converts from N/m to kN/mm, the /1000 goes from N to kN
Ins_slopeH = ezplot(ezplotString);
set(Ins_slopeH,'linewidth',2,'linestyle','--');
grid
xlabel('Trochanter Displacement (mm)','Fontname','times','fontsize',45)
ylabel('Compressive Force (kN)','Fontname','times','fontsize',45)
% title('Instron Displacement vs Force and Stiffness','Fontname','times','fontsize',20)
set(Ins_dfAX,'fontname','times','fontsize',40,'xlim',[cLimits(1) cLimits(2)],'ylim',[cLimits(3) cLimits(4)])
legend('Quasi-static','Stiffness')
ylimits = ylim;
ylim([0 2])
xlim([0 1.5])
set(get(Ins_dfAX,'title'),'string',[]);

% allow the user to review the results. using an msgbox as it is not modal
% and does not retain focus while open
msgH = msgbox('Please review the plots. Close this box to contiune.','Results Review','help');
uiwait(msgH);

% ask if data is okay. This dialog will retain focus while open.
reviewResult = questdlg('Please review the plots.  Should the data file be written?','Results Review','Yes','No','No');

% depending on selection, write data file or quit
switch reviewResult
    case 'Yes'
        if ~exist([inInsPath,'../../StiffnessComparisons-2.txt'],'file')   % if the data file does not exist, create and initalize it with the header line.
            outFileID = fopen([inInsPath,'../../StiffnessComparisons.txt'],'w');
            fprintf(outFileID,'Specimen\tDroptower(N/m)\tInstron(N/m)\tTrochanter DT Loading Rate (m/s)\tMax DT Force (N)\tDXA Score\tDXA Classification\n');
        else
            outFileID = fopen([inInsPath,'../../StiffnessComparisons-2.txt'],'a+');
        end
        specimenName = inInsPath(strfind(inInsPath,'H1'):strfind(inInsPath,'H1')+5);       % get the specimen name from the input path
        fprintf(outFileID,'%s\t%14.0f\t%14.0f\t%32f\t%16.0f\r\n',specimenName,0,Ins_stiffness,0,0);
        fclose(outFileID);
        
    case 'No'
        msgH = msgbox('The action was cancelled, no results were written','Cancellation Notification','warn');
        uiwait(msgH,30);
end

% % Save the figures
% outPlotIns = sprintf('%s_Ins_ForceDisp',specimenName);
% if ~exist([inInsPath,filesep,'..',filesep,'Plots'],'dir')
%     mkdir([inInsPath,filesep,'..'],'Plots')
% end
% set(Ins_dfFH,'position',[1 1 3360 1050],'paperpositionmode','auto');
% 
% print(Ins_dfFH,'-dpng','-r100',[inInsPath,'../Plots/',outPlotIns,'_lowRes.png'])
% 
% print(Ins_dfFH,'-dpng','-r300',[inInsPath,'../Plots/',outPlotIns,'_higRes.png'])
% 
% saveas(Ins_dfFH,[inInsPath,'../Plots/',outPlotIns],'fig');