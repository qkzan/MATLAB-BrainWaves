% atualização 15/10/2019 - 1st plot
% adiciona função return to cancel
% adiciona normalização

% addpath('E:\KitPower\Codes')
%%
clear; clc; close all;
% cd 'C:\Users\queru\OneDrive - Universidade Federal do Rio Grande do Sul\WARCrio\KitPower\Data'
% cd 'D:\KitPower\Data'  
% cd 'E:\KitPower\Data'  

[filename, pathname] = uigetfile('*.xlsx', 'Pick a Excel epochs file');
if ~ischar(filename)
  disp('User pressed Cancel');
  return;  % Or what ever is applicable
end
file = fullfile(pathname,filename);
folder = 'Results_4_filtered\';

placements = ["CtxD" "CtxE"];

% Routine
% [Data,~,RAW] = xlsread(file,-1);
[Data,~,RAW] = xlsread(file,'epochs');


Data = single(Data);
Databank = string(RAW);
%%
% find Excel's file structure
for j=1:size(RAW,2)
    try
        var = find(isnumeric(RAW{2,j}));
        if var == 1
            break
        end
    catch
    end
end
clear RAW;

I_matfile = find(strcmp(Databank(1,:),"Mat file"));
I_start = find(strcmp(Databank(1,:),"Mat start (s)"))-(j-1);
I_end = find(strcmp(Databank(1,:),'Mat end (s)'))-(j-1);
clear j;
I_factor1 = find(strcmp(Databank(1,:),"Factor 1"));
I_factor2 = find(strcmp(Databank(1,:),"Factor 2"));
I_period = find(strcmp(Databank(1,:),"Period"));
I_animal = find(strcmp(Databank(1,:),"Animal #"));
numberOfEpochs = size(Data,1);

% creates variables
if ~exist('srate','var')
    [srate,dt] = samplerate(strcat('ECG\',Databank(2,I_matfile)));
end
epochsize = (Data(1,I_end)*srate)-Data(1,I_start)*srate;
lfp_raw = nan(numberOfEpochs,epochsize+1,length(placements));
lfp_wavelets = nan(numberOfEpochs,epochsize+1+10*srate,length(placements));
N=[]; % cummulative number of epochs in each matlabfile
%%
figure('WindowState','maximized')
for N_matfile = 1:numberOfEpochs-1
    if Databank(N_matfile+1,I_matfile)~=Databank(N_matfile+2,I_matfile) % the epoch +1 of Databank is equal to epoch of Data
        N = [N N_matfile];
    end
end

N = [N numberOfEpochs];

for N_matfile = 1:length(N)
    % N_matfile=1;
    clear AD*
    if N_matfile == 1
        epochsN = 1:N(N_matfile);
        n = 0; % epochs counter
    else
        epochsN = N(N_matfile-1)+1:N(N_matfile); % for Data index use this, for Databank sum 1
        n = N(N_matfile-1);
    end
    
    I_epoch = N(N_matfile)+1;
    matfile = char(Databank(I_epoch,I_matfile));
    disp(['loading matfile: ' matfile])
    load(matfile,'AD*');
    clear ChTimevector; clf;
    
    epochStart = Data(epochsN,I_start)*srate;
    epochEnd = (Data(epochsN,I_end)*srate);
    
    for placement = 1:length(placements)
        I_PlaceChannel = find(strcmp(Databank(I_epoch,:),placements(placement)));
        Channel = Databank(1,I_PlaceChannel);
        
        if exist(Channel,'var')
            ChData = single(eval(Channel));
            if ~exist('ChTimevector','var')
                ChTimevector = 0:dt:(length(ChData)-1)/1000;
            end
            subplot(2,1,placement)
            hold off
            plot(ChTimevector/60,ChData,'k');ylim([-1 1]);xlabel('Time (min)');ylabel('Amplitude (mV)')
            ID = [char(Databank(I_epoch,I_factor1)),' ',char(Databank(I_epoch,I_factor2)),' ',char(Databank(I_epoch,I_animal))];
            title([char(ID),' - ',char(placements(placement)),' | Total epochs: ',num2str(length(epochsN))])
            annotation('textbox',[0 0 0 1],'string',['Original data file: ' matfile],'FitBoxToText','on','Interpreter','none')
            
            for j=1:length(epochsN)
                lfp_raw(j+n,:,placement) = ChData(epochStart(j):epochEnd(j));
                % for wavelets analysis takes a longer epoch to be cutted after filtering
                lfp_wavelets(j+n,:,placement) = single(ChData(epochStart(j)-5000:epochEnd(j)+5000));
                subplot(2,1,placement)
                hold on
                plot(ChTimevector(epochStart(j):epochEnd(j))/60,lfp_raw(j+n,:,placement))
            end
        end
    end
    
    mkdir(strcat(folder,ID))
%     saveas(figure(1),strcat(folder,ID,'\',matfile(1:end-4),'_epochs'),'epsc')
    saveas(figure(1),strcat(folder,ID,'\',matfile(1:end-4),'_epochs'),'jpeg')
        
    n = N(N_matfile);
%     teste = [teste n];
end
load gong; sound(y,Fs)
%%
clear AD* Ch* epochEnd epochStart epochsN j matf* n* ID file var I_PlaceChannel I_epoch
lfp_raw=single(lfp_raw);
lfp_wavelets=single(lfp_wavelets);
save EpochCutterResults

%%
clear all; close all
load('EpochCutterResults.mat','lfp_wavelets','srate','dt')

notchfilter = [59.5  60.5 
               119.4 120.4 
               179.5 180.5 
               239.3 240.3];
% notchfilter = [ 59.5  61.5
%                 119.4 120.4
%                 178.7 181.6
%                 239.3 240.5];

for idx = 1:size(notchfilter,1)
    d(idx) = designfilt('bandstopiir','FilterOrder',20, ...
        'HalfPowerFrequency1',notchfilter(idx,1),'HalfPowerFrequency2',notchfilter(idx,2), ...
        'DesignMethod','butter','SampleRate',srate);
end

h = waitbar(0,'Filtering the signal');
for k = 1:size(lfp_wavelets,1)
    h = waitbar(k/size(lfp_wavelets,1));
    for ch = 1:size(lfp_wavelets,3)
        
        data = double(lfp_wavelets(k,:,ch));
        
        for idx = 1:length(d)
            
            data = filtfilt(d(idx),data);
            %     fvtool(d2)
            %     pause(1)
        end
        
        lfp_notchfilt(k,:,ch) = data;

    end
    
end
close(h)

save('EpochCutterResults.mat','lfp_notchfilt','notchfilter','folder','-append')
%%
clear all; close all; clc
load 'EpochCutterResults.mat'
lfp = lfp_notchfilt(:,5000:5000+epochsize,:); % escolher variável para analisar
% lfp = lfp_raw;

filteradjust = (notchfilter(:,2)-notchfilter(:,1))/2;

% PSD parameters
winlength = 4*srate; %window size
winoverlap = winlength/2; %window overlap
nfft = [];
[~,f]=pwelch(lfp(1,:,1)',winlength,winoverlap,nfft,srate);
F_psd = f;
for idx = 1:size(notchfilter,1)
    F_psd = F_psd(F_psd<=notchfilter(idx,1)-filteradjust(idx) | F_psd>=notchfilter(idx,2)+filteradjust(idx));
end
F_psd = F_psd(F_psd<=250);

F_psd1 = f;
% F_psd =  f(f<=58.5 | f>=61.5 & f<=119.4 | f>=120.4 & f<=178.7 | f>=181.6 & f<=239.3 | f>=240.5 & f<=250);
% F_psd =  f(f<=58.5 | f>=61.5 & f<=119.4 | f>=120.4 & f<=178.7 | f>=181.6 & f<=239.3 | f>=240.5 & f<=250);
% F = f(f<=59.5 | f>=61 & f<=179 | f>=180.7 & f<=298.3 | f>=300.5 & f<=400);

% TFD parameters
winlength_tfd = 2*srate; %window size
winoverlap_tfd = 0.5*winlength_tfd/2; %window overlap
[~,f,t] = spectrogram(lfp(1,:,1)',winlength_tfd,winoverlap_tfd,nfft,srate);
% F_tfd = f;
F_tfd = f;
for idx = 1:size(notchfilter,1)
    F_tfd = F_tfd(F_tfd<=notchfilter(idx,1)-filteradjust(idx) | F_tfd>=notchfilter(idx,2)+filteradjust(idx));
end
F_tfd = F_tfd(F_tfd<=250);
% F_tfd = f(f<=58.5 | f>=61.5 & f<=119.4 | f>=120.4 & f<=178.7 | f>=181.6 & f<=239.3 | f>=240.5 & f<=250);
% F_tfd = f(f<=59.5 | f>=61 & f<=179 | f>=180.7 & f<=298.3 | f>=300.5 & f<=400);
clear f

for placement = 1:length(placements)
    disp(['Computing PSD for ' char(placements(placement))])
    [PSD1{placement},~] = pwelch(lfp_raw(:,:,placement)',winlength,winoverlap,F_psd1,srate);
    [PSD{placement},~] = pwelch(lfp(:,:,placement)',winlength,winoverlap,F_psd,srate);
    
    h = waitbar(0,['Computing TFD for ' char(placements(placement))]);
    for epoch = 1:size(lfp,1)
        h = waitbar(epoch/size(lfp,1));
        [~,~,~,TFD{epoch,placement}] = spectrogram(lfp(epoch,:,placement)',winlength_tfd,winoverlap_tfd,F_tfd,srate);
    end
    close(h)
    
    %Normalization and decibel transformation
%     PSD1{placement} = PSD1{placement}./sum(PSD1{placement});
%     PSD{placement} = PSD{placement}./sum(PSD{placement});    
    PSD1dB{placement} = 10*log10(PSD1{placement});
    PSDdB{placement} = 10*log10(PSD{placement}); 
end

save IndividualPowerResults PSD* TFD* F* t lfp
%% epoch visual inspection
clear;clc
load EpochCutterResults
load IndividualPowerResults
timevec = 0:dt:(size(lfp,2)-1)*dt;
selection=zeros(size(lfp,1),length(placements));
% load selection
fig = figure('WindowState','maximized'); 
colormap hot;  

for epoch=1:size(lfp,1)
    fig.Visible = 'off';
    placement=1;
    for j = 1:3:length(placements)*3
        
        if ~isnan(lfp(epoch,:,placement))
            
            p(placement) = subplot(length(placements),3,j);
            plot(timevec,lfp_raw(epoch,:,placement)+0.1,timevec,lfp(epoch,:,placement)-0.1)
            ylim([-1 1]); ylabel('Amplitude (mV)'); box off;
            title(placements(placement))
            legend('raw data','filtered');
            if placement == length(placements)
                xlabel('Time(s)');
            end
            linkaxes(p)
            
            subplot(length(placements),3,j+1)
            plot(F_psd1,PSD1dB{placement}(:,epoch),F_psd,PSDdB{placement}(:,epoch))
            legend('raw data','filtered')
            xlim([0 250]); ylim([-80 -30]); ylabel('Power (dB/Hz)'); box off
            if placement == length(placements)
                xlabel('Time(s)');
            end
            
            subplot(length(placements),3,j+2)
            imagesc(t,F_tfd,10*log10(TFD{epoch,placement}))
            axis xy; %xticks([0:1:20]); xticklabels([0:1:20]);
            ylabel('Frequency (Hz)'); h=colorbar('AxisLocation','out');
            caxis([-110 -20]);%caxis([0 10^-4]);
            ylabel(h,'Power (dB)','rotation',270,'VerticalAlignment','baseline')
            if placement == length(placements)
                xlabel('Time(s)');
            end
        end
        
        % Create checkboxes
        gcaplace = get(gca,'outerposition');
        ckb(placement) = uicontrol(fig,'style','checkbox','Value',1,...
            'Units', 'Normalized','Position', [0.03 gcaplace(2)+gcaplace(4)/2 0.015 0.03]);

        placement=placement+1;
    end
    
    % Make figure visible after adding all components
    fig.Visible = 'on';
    
    figureID = ['Epoch ' num2str(epoch) ' - Animal: ' char(Databank(epoch+1,I_factor1)) ' ' ...
        char(Databank(epoch+1,I_factor2)) ' ' char(Databank(epoch+1,I_animal)) ' period ' char(Databank(epoch+1,I_period))];
    annotation('textbox',[0 0 0 1],'string',figureID,'FitBoxToText','on')
    
    ID = [char(Databank(epoch+1,I_factor1)),' ',char(Databank(epoch+1,I_factor2)),' ',char(Databank(epoch+1,I_animal))];
    IDs(epoch) = string(ID);
    figurename = strcat(folder,ID,'\','Epoch_',num2str(epoch));
    
    % Create push button
    btn(1) = uicontrol(fig,'Style', 'pushbutton', 'String', 'Done',...
        'Units', 'Normalized','Position', [0.01 0.01 0.05 0.05  ],...
        'Callback','resp = 1;uiresume');
    btn(2) = uicontrol(fig,'Style', 'pushbutton', 'String', 'Discard',...
        'Units', 'Normalized','Position', [0.06 0.01 0.05 0.05  ],...
        'Callback','resp = 2;uiresume');
    btn(3) = uicontrol(fig,'Style', 'pushbutton', 'String', 'Cancel',...
        'Units', 'Normalized','Position', [0.11 0.01 0.05 0.05  ],...
        'Callback','resp = 0;uiresume');
    
   uiwait
   
   if resp == 0
       break
   elseif resp == 2
       for ckbI = 1:length(ckb)
           ckb(ckbI).Value = 0;
       end
   end
   
   for placement = 1:length(placements)
       if ~isnan(lfp(epoch,:,placement))
           selection(epoch,placement)=get(ckb(placement),'Value');
       end
   end
   btn(1).Visible = 'off'; btn(2).Visible = 'off'; btn(3).Visible = 'off';
   
   %apenas se já foi feito o corte em outro momento
   mkdir([folder,char(Databank(epoch+1,I_factor1)),' ',char(Databank(epoch+1,I_factor2)),' ',char(Databank(epoch+1,I_animal))]);
   
   saveas(fig,figurename,'jpeg');
   clf(fig)
%    clf
   disp(['Epoch: ' num2str(epoch) ', channel selection: ' num2str(selection(epoch,:))])
end
    close(fig)
if resp == 0
    return
else
     save selection selection
end
%%
clear;clc;
load EpochCutterResults
load IndividualPowerResults
load selection
F = F_psd;
F_range = { find(F>=1    & F<=4)    % delta (1)
            find(F>4    & F<=12)    % theta (2)
            find(F>12   & F<=30)    % beta (3)
            find(F>30   & F<=50)    % slow gamma (4)
            find(F>50   & F<=90)    % middle gamma(5)
            find(F>90   & F<=150)   % fast gamma (6)
            find(F>160  & F<=250)   % ripple (7)
            find(F>250  & F<=400)}; % fast ripple (8)
columns = 'A':'Z';
        
F_power = [];
warning('off','MATLAB:xlswrite:AddSheet')
for placement=1:length(placements)
    for f=1:length(F_range)
        for nepoch = 1:size(PSD{placement},2)
            F_power{placement}(nepoch,f) = mean(PSD{placement}(F_range{f},nepoch),1);
        end
    end
    xlswrite([folder 'EpochPower.xlsx'],["Delta" "Theta" "Beta" "Slow gamma" "Middle gamma" "Fast gamma" "Ripple" "Fast Ripple"],placements(placement),[columns(I_animal+2) num2str(1)])
    xlswrite([folder 'EpochPower.xlsx'],selection(:,placement)           ,placements(placement),'A2')
    xlswrite([folder 'EpochPower.xlsx'],Databank(:,I_factor1:I_animal)	,placements(placement),'B1')
    xlswrite([folder 'EpochPower.xlsx'],F_power{placement}(:,:)          ,placements(placement),[columns(I_animal+2) num2str(2)])
end
disp('Done')
save EpochPowerResults
%% choose the good epochs in Excel before running these
clear; clc
load EpochPowerResults

for placement = 1:length(placements)
    [Data2{placement},~,RAW{placement}] = xlsread([folder 'EpochPower.xlsx'],placements(placement));
    epochfilter(:,placement) = Data2{placement}(:,end);
end

save epochfilter epochfilter
xlswrite([folder 'EpochPower.xlsx'],["F" "Placement" Databank(1,I_factor1:I_animal) "Delta" "Theta" "Beta" "Slow gamma" "Middle gamma" "Fast gamma" "Ripple" "Fast Ripple"],'All','A1')

xlswrite([folder 'EpochPower.xlsx'],epochfilter(:,1)                                 ,'All','A2')
xlswrite([folder 'EpochPower.xlsx'],repmat(placements(1),size(epochfilter(:,1),1),1) ,'All','B2')
xlswrite([folder 'EpochPower.xlsx'],repmat(Databank(2:end,I_factor1:I_animal),2,1)	,'All','C2')
xlswrite([folder 'EpochPower.xlsx'],F_power{1}(:,:)          ,'All',[columns(I_animal+3) '2'])

xlswrite([folder 'EpochPower.xlsx'],epochfilter(:,2)                                 ,'All',['A' num2str(2+size(epochfilter(:,1),1))])
xlswrite([folder 'EpochPower.xlsx'],repmat(placements(2),size(epochfilter(:,2),1),1) ,'All',['B' num2str(2+size(epochfilter(:,1),1))])
xlswrite([folder 'EpochPower.xlsx'],F_power{2}(:,:)          ,'All',[columns(I_animal+3) num2str(2+size(epochfilter(:,1),1))])

%% after choosing the good epochs, calculates the animal mean and the group mean
I_group = find(strcmp(RAW{1}(1,:),"Group #"));
Ngroups = max(cell2mat(RAW{1}(2:end,I_group)));

for placement=1:length(placements)
    I_group = find(strcmp(RAW{placement}(1,:),"Group #"));
    I_animal = find(strcmp(RAW{placement}(1,:),"Animal #"));
    
    for group = 1:Ngroups
        for animal = 1:7
            epochsall{animal,group,placement} = find(Data2{placement}(:,I_group)==group & Data2{placement}(:,I_animal)==animal & epochfilter(:,placement)==1);
            
            epochs=epochsall{animal,group,placement};
            
            PSDepoch{animal,group,placement} = PSD{placement}(:,epochs);
            PSDanimal{animal,group,placement} = mean(PSDepoch{animal,group,placement},2);
            
            clear tfd_epochs tfd_epoch 
            
            if ~isempty(epochs)
                for epoch= 1:length(epochs)
                    tfd_epoch = TFD{epochs(epoch),placement};
                    tfd_epochs(:,:,epoch) = tfd_epoch;
                end
                TFDepoch{animal,group,placement} = tfd_epochs;
                TFDanimal{animal,group,placement} = mean(tfd_epochs,3);
                tfd_animal(:,:,animal) = TFDanimal{animal,group,placement};
            end
            
        end
        
        PSDgroup(:,group,placement) = nanmean(cell2mat(PSDanimal(:,group,placement)'),2);
        TFDgroup(:,:,group,placement) = nanmean(tfd_animal,3);
        clear tfd_animal
    end
end

save forgraphvariables PSDgroup F_psd placements PSDanimal folder
%% plots for each animal by group in dB/Hz
figure('Name','Animal Data','WindowState','maximized'); colormap hot;

labels = {{} 'Wistar' 'Sham';{} 'Wistar' 'FL';{} 'WAR' 'Sham';{} 'WAR' 'FL'};
for k =1:size(labels,1)
labels{k,1} = [labels{k,2} ' ' labels{k,3}];
end
for group = 1:Ngroups
    j=1;
    names = {};
    for placement=1:length(placements)
        
        figure(2)
        h(placement) = subplot(length(placements),1,placement);
        for animal = 1:7
            plot(F_psd,smoothdata(10*log10(PSDanimal{animal,group,placement}),'SmoothingFactor',0.02)); hold on
            names(animal) = {['Animal ' num2str(animal)]};
        end
        plot(F_psd,smoothdata(10*log10(PSDgroup(:,group,placement)),'SmoothingFactor',0.02),'k','LineWidth',2)
        legend(names,'mean')
        xlim([0 250]); ylim([-60 -10]); ylabel('Normalized dB power'); box off
        if placement == length(placements)
            xlabel('Time(s)');
        end
        title(placements(placement));
        set(legend,'position',[0.7827 0.69807 0.16607 0.2845])
        annotation('textbox',[0 0 0 1],'string',[labels{group,1}],'FitBoxToText','on');
        
        figure(1)
        subplot(length(placements),size(TFDanimal,1)+1,j)
        for animal = 1:7
            plot(F_psd,smoothdata(10*log10(PSDanimal{animal,group,placement}),'SmoothingFactor',0.02)); hold on
            names(animal) = {['Animal ' num2str(animal)]};
        end
        plot(F_psd,smoothdata(10*log10(PSDgroup(:,group,placement)),'SmoothingFactor',0.02),'k','LineWidth',2)
        legend(names,'mean')
        xlim([0 250]); ylim([-60 -10]); ylabel('Normalized dB power'); box off
        if placement == length(placements)
            xlabel('Time(s)');
        end
        title(placements(placement));
        set(legend,'position',[0.0079    0.3577    0.0827    0.0945])
        
        k = j;
        for animal = 1:size(TFDanimal,1)
            k=k+1;
            subplot(length(placements),size(TFDanimal,1)+1,k)
            imagesc(t,F_tfd,10*log10(TFDanimal{animal,group,placement}))
            axis xy; %xticks([0:1:20]); xticklabels([0:1:20]);
            ylabel('Frequency (Hz)'); %h=colorbar('AxisLocation','out');
            caxis([-110 -20]);%caxis([0 10^-4]);
            %             ylabel(h,'Power (mV²/Hz)','rotation',270,'VerticalAlignment','baseline')
            if placement == length(placements)
                xlabel('Time(s)');
            else
                title(names(animal))
            end
            
        end
        j=j+size(TFDanimal,1)+1;
    end
    btn(1) = uicontrol(figure(1),'Style', 'pushbutton', 'String', 'Done',...
        'Units', 'Normalized','Position', [0.01 0.01 0.05 0.05  ],...
        'Callback','resp = 1;uiresume');
    btn(2) = uicontrol(figure(1),'Style', 'pushbutton', 'String', 'Cancel',...
        'Units', 'Normalized','Position', [0.11 0.01 0.05 0.05  ],...
        'Callback','resp = 0;uiresume');
    annotation('textbox',[0 0 0 1],'string',[labels{group,1}],'FitBoxToText','on');
    linkaxes([h(1),h(2)])
    
    uiwait
    
    if resp == 0
        break
    end
    
    btn(1).Visible = 'off'; btn(2).Visible = 'off';
    saveas(figure(2),[folder 'Animal_Data_GroupPSD_' num2str(group)],'jpeg');
    saveas(figure(1),[folder 'Animal_Data_Group_' num2str(group)],'jpeg');
    figure(1);clf;
    figure(2);clf;
end
close all

%% Plots for group and animal
figure('Name','Group Data','WindowState','maximized'); colormap hot;
  
j=1;
for placement=1:length(placements)
    
        figure(1)
        subplot(length(placements),Ngroups+1,j)
        plot(F_psd,10*log10(PSDgroup(:,:,placement)))
        k =j;
        legend(labels{:,1})
        xlim([0 250]); ylabel('Normalized dB power'); box off
        ylim([-60 -10]);
        if placement == length(placements)
            xlabel('Time(s)');
        end
        title(placements(placement));
        
        for group = 1:Ngroups
            k=k+1;
            subplot(length(placements),Ngroups+1,k)
            imagesc(t,F_tfd,10*log10(TFDgroup(:,:,group,placement)))
            axis xy; %xticks([0:1:20]); xticklabels([0:1:20]);
            ylabel('Frequency (Hz)'); 
            h=colorbar('AxisLocation','out');
            caxis([-110 -20]);%caxis([0 10^-4]);
            ylabel(h,'Power (dB/Hz)','rotation',270,'VerticalAlignment','baseline')
            if placement == length(placements)
                xlabel('Time(s)');
            else
                title(labels{group})
            end
        end
        j=j+Ngroups+1;
        
end

resp=0;
btn(1) = uicontrol(figure(1),'Style', 'pushbutton', 'String', 'Done',...
    'Units', 'Normalized','Position', [0.01 0.01 0.05 0.05  ],...
    'Callback','resp = 1;uiresume');
btn(2) = uicontrol(figure(1),'Style', 'pushbutton', 'String', 'Cancel',...
    'Units', 'Normalized','Position', [0.11 0.01 0.05 0.05  ],...
    'Callback','resp = 0;uiresume');

uiwait

figure(1)

if resp == 0
    close
    return
end

btn(1).Visible = 'off'; btn(2).Visible = 'off';
saveas(figure(1),[folder 'Group_' num2str(group) '_Data'],'jpeg');
close

%% Export data to Excel

F = F_psd;
% F_range = { find(F>=1   & F<=4)     % delta (1)
%             find(F>4    & F<=12)    % theta (2) alpha 8-12Hz
%             find(F>12 & F<30)       % beta
%             find(F>=30  & F<=50)    % slow gamma (3)
%             find(F>50 & F<=59.5 | F>=60.5 & F<=90)    % middle gamma(4)
%             find(F>90   & F<150)   % fast gamma (5)
%             find(F>=160 & F<=250)   % ripple (6)
%             find(F>250  & F<=400)}; % fast ripple (7)
columns = 'A':'Z';

count = 1;
ID = {};
Power_export = [];
PSD_export = [];
warning('off','MATLAB:xlswrite:AddSheet')
for placement=1:length(placements)
    for group = 1:Ngroups
        for animal = 1:length(PSDanimal(:,group,placement))
            if ~isnan(PSDanimal{animal,group,placement})
                for f=1:length(F_range)
                    Power_export(count,f) = mean(PSDanimal{animal,group,placement}(F_range{f}));
                    PSD_export(:,count) = PSDanimal{animal,group,placement};
                end
                ID(count,:) = {labels{group,2} labels{group,3} group animal placements{placement} placement};
                count=count+1;
            end
        end
    end
end
% %
xlswrite([folder 'AnimalPower.xlsx'],["factor1" "factor2" "group" "animal" "location" "locationID"],'PowerFilt','A1')
xlswrite([folder 'AnimalPower.xlsx'],ID          ,'PowerFilt','A2')    
xlswrite([folder 'AnimalPower.xlsx'],["Delta" "Theta" "Beta" "Slow gamma" "Middle gamma" "Fast gamma" "Ripple" "Fast Ripple"],'PowerFilt',[columns(size(ID,2)+1) '1'])
xlswrite([folder 'AnimalPower.xlsx'],Power_export	,'PowerFilt',[columns(size(ID,2)+1) '2'])

xlswrite([folder 'AnimalPower.xlsx'],["factor1" "factor2" "group" "animal" "location" "locationID"]','Power','A1')
xlswrite([folder 'AnimalPower.xlsx'],ID'         ,'Power','B1')
xlswrite([folder 'AnimalPower.xlsx'],F_psd        ,'Power',['A' num2str(size(ID,2)+1)])
xlswrite([folder 'AnimalPower.xlsx'],PSD_export	,'Power',['B' num2str(size(ID,2)+1)])

disp('Done')

load handel
sound(y,Fs)

 
% [row,col] = find(Data);
% Power = [Power;PowerPer];
% PowerPer=[];
% F_power=[];
% clearvars -except
% ChannelsNames = string(who('AD01','AD02','AD03','AD04',...
%                         'AD05','AD06','AD07','AD08',...
%                         'AD09','AD10','AD11','AD12',...
%                         'AD13','AD14','AD15','AD16'));

