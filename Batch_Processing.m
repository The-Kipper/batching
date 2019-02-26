%% Clean House

clc
clearvars
close all


%% Define conditions and column headers
ColumnHeaders = {'LR_pVGRF_FAST','PO_pVGRF_FAST','LR_pVGRFt_FAST','PO_pVGRFt_FAST',...
    'LR_pVGRF_NORM','PO_pVGRF_NORM','LR_pVGRFt_NORM','PO_pVGRFt_NORM',...
    'LR_pVGRF_SLOW','PO_pVGRF_SLOW','LR_pVGRFt_SLOW','PO_pVGRFt_SLOW'};
%% Open Key File
[filename,pathname] = uigetfile('C:\Users\Kip\Documents\MATLAB\KNS 541\*.xlsx',...
    'Open subjects file','Multiselect','off');

%check if user presses cancel on the dialog
if isequal(filename,0)
    uiwait(warndlg('Key file not selected! Click OK to continue.','Warning!'));
    return
else
    [data,txt] = xlsread([pathname,filename]); % seperate data and text
end
sub_list = txt(2:end,1); % start at row 2 to the end of the data file of column 1

%% Select Subjects to Process
% create a list dlg that allows the user to select which subjects to
% process. The subject list is made from the indexed sub_list pulled from
% the imported and read key file.

selection =listdlg('PromptString','Select Subjects:',...
    'SelectionMode','multiple',...
    'ListString',sub_list,...
    'OKString','Do it!',...
    'CancelString', 'Naw fam');

if isempty(selection)
    uiwait(warndlg('Subjects not selected! Click OK to continue.','Warning!'));
    return
else
    subjects = sub_list(selection);
end



%% Batch (loop) selected subjects
nsub = size(subjects,1);

for s = 1:nsub
    % Open current Subject
    sub_folder = [pathname 'data\' subjects{s} '\'];
    
    % Open subject data
    sub_data = dlmread([sub_folder subjects{s} '_GRF.out'],'\t', 5,1);
    
    % Read file header info for trial names
    fid = fopen([sub_folder subjects{s} '_GRF.out'],'r');
    f = textscan(fid, '%s',size(sub_data,2)+1,'delimiter','\t');
    trials_list = f{1}(2:end);
    clear f
    status = fclose(fid);
    
    % Determine the Number of Trials
    ntrials = size(sub_data,2) / 3;       %3 columns of data per trial
    g =  1;     % GRF counter
    cf = 1;     % Fast trial counter
    cn = 1;     % Normal trial counter
    cs = 1;     % Slow trial counter
    for t = 1:ntrials% Batch (loop) through trials of current subjects
        
        % ID trial name
        k = strfind(trials_list{g},'\');
        l = strfind(trials_list{g},'.c3d');
        trial = trials_list{g}(k(end)+1:l-1);    %index the last \ to the end
        
        % Find gait events
        [HS,TO] = Handwerker_FindGaitEvents(sub_data(:,g+2),10);
        
        % Extract and crop trial data
        trial_data = sub_data(HS:TO,g+2);
        
        % find LR/PO peak VGRF
        [PeakVertMag,PeakVertIndex] = findpeaks(trial_data,'NPeaks',2,'MinPeakWidth',100);
        
        % Transpose PeakVertMag and PeakVertIndex for SPSS
        PeakVertMag = PeakVertMag';
        PeakVertIndex = PeakVertIndex';
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% IF YOU WANT TO MANUALLY CHECK PEAKS %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%         % Check peaks
%         % Plot line
%         plot(trial_data,'Color',[0 0 0],...
%             'LineWidth',2,...
%             'LineStyle','-');
%         ylabel('Force (N)')
%         xlabel('Frame #')
%         title(strrep(trial,'_','\_'))
%         hold on
%         
%         % Plot event markers
%         plot(PeakVertIndex,PeakVertMag,'rd',...
%             'LineStyle','none',...
%             'MarkerSize',10,...
%             'MarkerFaceColor',[1 0 0],...
%             'MarkerEdgeColor',[1 0 0]);
%         hold off

%         c = 0; %check flag
%         while c~=1
%             c = menu('Is this correct?',{'yes','no'});
%             if c==2
%                 [x,y] = ginput(2);  % allows for 2 inputs
%                 x=round(x);
%                 for i = 1:length(x)
%                     [PeakVertMag(i),idx] = max(trial_data(x(i)-20:x(i)+20,1));
%                     PeakVertIndex(i) = x(i)-20 + idx -1;
%                 end
%                 
%                 % plot adjust event markers
%                 clf
%                 plot(trial_data,'Color',[0 0 0],...
%                     'LineWidth',2,...
%                     'LineStyle','-');
%                 ylabel('Force (N)')
%                 xlabel('Frame #')
%                 title(strrep(trial,'_','\_'))
%                 hold on
%                 
%                 % Plot event markers
%                 plot(PeakVertIndex,PeakVertMag,'rd',...
%                     'LineStyle','none',...
%                     'MarkerSize',10,...
%                     'MarkerFaceColor',[1 0 0],...
%                     'MarkerEdgeColor',[1 0 0]);
%                 hold off
%                 clear x y i
%             end
%         end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Normalize the results
        PeakVertMag = PeakVertMag / data(s,3);
        PeakVertPerc = 100*PeakVertIndex /length(trial_data);
        
        % Compile metric by condition
        if strfind(trial,'FAST')
            sub_FAST(cf,:) = [PeakVertMag,PeakVertPerc];
            cf = cf + 1;
        elseif strfind(trial,'NORM')
            sub_NORM(cn,:) = [PeakVertMag,PeakVertPerc];
            cn = cn + 1;
        elseif strfind(trial,'SLOW')
            sub_SLOW(cs,:) = [PeakVertMag,PeakVertPerc];
            cs = cs + 1;
        end
        g = g+3;
    end
    % Write out subject file
    Comp_sub_data = [sub_FAST sub_NORM sub_SLOW];
    subpath = ['C:\Users\Kip\Documents\MATLAB\KNS 541\Act.18\data\', subjects{s} '\t'];
    subfile = 'Subject data.out';
    ColHead = sprintf('%s\t',ColumnHeaders{:});
    dlmwrite([subpath subfile],ColHead,'');
    dlmwrite([subpath subfile],Comp_sub_data,'-append','delimiter','\t')
    
    % Calculate subject average for each condition
Mean_Sub{s} = mean(Comp_sub_data(:,:));
end

% % Compiling dvs for SPSS
SPSS_table = [Mean_Sub{1};Mean_Sub{2};Mean_Sub{3};Mean_Sub{4};Mean_Sub{5};...
             Mean_Sub{6};Mean_Sub{7};Mean_Sub{8};Mean_Sub{9};Mean_Sub{10}];

T = table(SPSS_table(:,1),SPSS_table(:,2),SPSS_table(:,3),SPSS_table(:,4),SPSS_table(:,5),...
    SPSS_table(:,6),SPSS_table(:,7),SPSS_table(:,8),SPSS_table(:,9),SPSS_table(:,10),...
    SPSS_table(:,11),SPSS_table(:,12),...
    'VariableNames',{'LR_pVGRF_FAST','PO_pVGRF_FAST','LR_pVGRFt_FAST','PO_pVGRFt_FAST',...
    'LR_pVGRF_NORM','PO_pVGRF_NORM','LR_pVGRFt_NORM','PO_pVGRFt_NORM',...
    'LR_pVGRF_SLOW','PO_pVGRF_SLOW','LR_pVGRFt_SLOW','PO_pVGRFt_SLOW'},...
    'RowNames',{'S01';'S02';'S03';'S04';'S05';'S06';'S07';'S08';'S09';'S10'});
T.Properties.DimensionNames{1} = 'Subjects';
disp(T)

%% Save
[filename, pathname] = uiputfile('*.xlsx','Save compiled means folder');
if isequal(filename,0) || isequal(pathname,0)
    uiwait(warndlg({'File not saved.';'Click OK to continue.'},'Warning!'));
else 
    writetable(T,[pathname filename],'WriteRowName',1)
end







