clear; clc; close all
co = [144/255 191/255 249/255;
    0 0 192/255;
    255/255 192/255 128/255;
    255/255 96/255 0/255];
set(0,'defaultaxesfontname','Arial','defaultaxesfontsize',11,'defaultAxesColorOrder',co,...
    'defaultlinelinewidth',1)

% % Carregar dados
% cd 'C:\Users\Leonardo\Documents\PendriveDeOuroDaQ\KitPower\Data'
cd 'C:\Users\queru\Documents\MATLAB\WARcrio\KitPower'
folder='Results_6_newWistar\';
mkdir(folder)

%% Escolher animal e parametros de analise (qual o acoplamento e fatores)
    %Início  fimPower  fimFiltro    nome
F = { [1        4        4]         'Delta'      %(1)
      [4        12       12]        'Theta'      % (2)
      [12       30       25]        'Beta'       % (3) %% 24 para filtrar e 30 para power
      [30       50       50]        'Slow gamma' %(4)
      [50       90       90]        'Middle gamma' %(5)
      [90       150      150]       'Fast gamma' };% (6)

n_surr = 200;
low_freq_idx = 1:3;
high_freq_idx = low_freq_idx(end)+1:size(F,1);

% Data
load comodulogramvariables srate timevec epochsize ID IDcode
dt=1/srate;
cutvec = 5000:5000+epochsize;
Data = table(IDcode(:,1),join(ID(:,2:4)),IDcode(:,2),ID(:,5),...
    'VariableNames',{'Epoch','Animal'      ,'Group'    ,'Placement'});
load Data

load 'IndividualPowerResults' 'F_psd' 'F_tfd'

%select some data to work with
% epochs = 1:5;
epochs = 1:height(Data);

% exclude outliers
UnitID = {'Epoch','Placement'};
outliers = table([0],...
                 {''},...
                 'VariableNames',UnitID);

Idx=[];
for i = 1:length(UnitID)
   Idx = [Idx find(strcmp(Data.Properties.VariableNames,UnitID(i)))];
end

[~,Idx] = setdiff(Data(:,Idx),outliers,'rows','stable');
T = Data(Idx(epochs),:);

% PSD parameters
func(1).name = 'PSD';
func(1).freq = F_psd; clear F_psd
func(1).winlength = 4*srate; %window size
func(1).winoverlap = func(1).winlength/2; %window overlap
func(1).function = @(x) pwelch(x',func(1).winlength,func(1).winoverlap,func(1).freq,srate)';

% TFD parameters
func(2).name = 'TFD';
func(2).freq = F_tfd; clear F_tfd
func(2).winlength = 2*srate; %window size
func(2).winoverlap = 0.5*func(2).winlength/2; %window overlap
func(2).function = @(x) spectrogram(x,func(2).winlength,func(2).winoverlap,func(2).freq,srate)';

%% Define os pontos que são de cada frequencia para o PSD e o TFD
for f=1:size(F,1)
    startpoint = F{f,1}(1);
    endpoint = F{f,1}(2);
    if f==1
        func(1).idx{f} = find(func(1).freq >= startpoint & func(1).freq <= endpoint);
        func(2).idx{f} = find(func(2).freq >= startpoint & func(2).freq <= endpoint);
    else
        func(1).idx{f} = find(func(1).freq > startpoint & func(1).freq <= endpoint);
        func(2).idx{f} = find(func(2).freq > startpoint & func(2).freq <= endpoint);
    end
end
%%
nfactors = width(T);
T1=table;

% alinha o lfp ao redor de 0 mV
T1.lfplong = detrend(selectedLFPs(epochs,:)','linear')';

% corta o trecho do lfp para o período desejado
lfp = T1.lfplong(:,cutvec);
T1.lfp = lfp;

% calcula o PSD de cada trecho
data = varfun(func(1).function,T1,'InputVariables','lfp');
T1 = addvars(T1,data.(1),'NewVariableNames','PSD');

% calcula o PSD de cada trecho em dB
T1.PSDdB = 10.*log10(T1.PSD);

%% calcula o TFD de cada trecho
data = cell2table(rowfun(func(2).function,T1,'InputVariables','lfp','OutputFormat','cell'));
T1 = addvars(T1,data.(1),'NewVariableNames','TFD'); clear data;

%% calcula o poder médio e a frequencia de pico para cada frequência  de cada trecho
FreqNames = cellfun(@(x) strrep(x,' ',''),F(:,2),'UniformOutput',false)';
variable = 'PSDdB';
col = T1{:,variable};
MeanPower = table(); PeakPowerFreq = table();

% calcula o mean power e a peak power freq para cada faixa de frequência
for f=1:size(F,1)
    I = func(1).idx{f};
    I2 = repmat(func(1).freq,1,size(col,1))';
    
    newname{f,1} = ([FreqNames{f} 'MeanPower']);
    MeanPower.(f) = mean(col(:,I),2);
    
    newname{f,2} = ([FreqNames{f} 'PeakPowerFreq']);
    PeakPowerFreq.(f) = I2(col(:,:)==max(col(:,I),[],2));
end
MeanPower.Properties.VariableNames = newname(:,1);
PeakPowerFreq.Properties.VariableNames = newname(:,2);

T2 = [T MeanPower PeakPowerFreq];
% salva a tabela com o mean power e o peak power freq
filename = [folder 'PowerDB_dB.xlsx'];
writetable(T2,filename)

%% Extracts coupling data
% filtra o sinal para cada frequencia e cada trecho com eegfilt
data = rowfun(@(x) filtering(x,F,srate),T1,'InputVariables','lfplong');
Filt=data.(1);
Filt.Properties.VariableNames = FreqNames;

% calcula a amplitude, phase e freq instantânea de cada trecho
% AnaliticSignal = varfun(@hilbert,Filt);
data = cellfun(@hilbert,table2cell(Filt),'UniformOutput',false);
AnaliticSignal = cell2table(data);
Amp = varfun(@abs,AnaliticSignal); 
Pha = varfun(@angle,AnaliticSignal); 
data = cellfun(@(x) abs(diff(unwrap(angle(x)))/(2*pi*dt)),table2cell(AnaliticSignal),'UniformOutput',false);
InstFreq = cell2table(data);

Pha.Properties.VariableNames = FreqNames;
Amp.Properties.VariableNames = FreqNames;
InstFreq.Properties.VariableNames = FreqNames;

for f=1:size(F,1)
    Filt.(f) = Filt.(f)(:,cutvec);
    Amp.(f) = Amp.(f)(:,cutvec);
    Pha.(f) = Pha.(f)(:,cutvec);
    InstFreq.(f) = InstFreq.(f)(:,cutvec);
end
T1 = addvars(T1,Filt,Amp,Pha,InstFreq);

%% Coupling
newname = {};
couptype = {'PhaPha','PhaAmp','PhaFreq','AmpAmp','AmpFreq','FreqFreq'};
% idx = 1:length(timevec);

for i=1:length(couptype)
    eval([couptype{i} '= table();']);
end

count=1;
for lf = low_freq_idx
    for hf = high_freq_idx
        i = 0;
        newname{count} = [FreqNames{lf} '_' FreqNames{hf}];
        
        % PhaPha
        
        data = rowfun(@(x,y) couplingMI2(x,y,'pa'),[Pha(:,lf) Amp(:,hf)],'OutputVariableNames',{'MI','Median','bins','step'});
        PhaAmp = addvars(PhaAmp,data,'NewVariableNames',newname{count});
%         MI.(1) = [MI.(1) data.(1)]
        
        data = rowfun(@(x,y) couplingMI2(x,y,'pf'),[Pha(:,lf) InstFreq(:,hf)],'OutputVariableNames',{'MI','Median','bins','step'});
        PhaFreq = addvars(PhaFreq,data,'NewVariableNames',newname{count});
        
        data  = rowfun(@(x,y) couplingMI2(x,y,'aa'),[Amp(:,lf) Amp(:,hf)],'OutputVariableNames',{'MI','Median','bins','step'});
        AmpAmp = addvars(AmpAmp,data,'NewVariableNames',newname{count});
        
        data = rowfun(@(x,y) couplingMI2(x,y,'af'),[Amp(:,lf) InstFreq(:,hf)],'OutputVariableNames',{'MI','Median','bins','step'});
        AmpFreq = addvars(AmpFreq,data,'NewVariableNames',newname{count});
        
        % FreqFreq
        
        count = count+1;
    end
end

Coupling = table(PhaAmp, PhaFreq, AmpAmp, AmpFreq);
couptype = Coupling.Properties.VariableNames;
MI = table('Size',[height(T) width(Coupling)],'VariableTypes',repmat({'table'},1,width(Coupling)),'VariableNames',Coupling.Properties.VariableNames);
%% 
filename = [folder 'CouplingBinMedian.xlsx'];
for i = 1:length(couptype)
    for coup = 1:length(newname)
        MI.(i) = addvars(MI.(i),Coupling.(i).(coup).MI,'NewVariableNames',newname{coup});
    end
    T3 = [T MI.(i)];
     writetable(T3,filename,'Sheet',couptype{i},'Range','B1')
end



%% plot power by animal and placement with group mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T2 = [T T1];
PSDbyAnimal = varfun(@mean,T2,'InputVariables',variable,'GroupingVariables',{'Group','Animal','Placement'});
ncol=width(PSDbyAnimal);
PSDbyGroup = varfun(@mean,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'Group','Placement'});
PSDstd = varfun(@std,PSDbyAnimal,'InputVariables',ncol','GroupingVariables',{'Group'});

close all
Place={'CtxE','CtxD'};
figure('Position',[0 0 800 500],'PaperOrientation','rotated')
figure('Position',[0 0 800 500],'PaperOrientation','rotated')
for i = 1:height(PSDbyAnimal)
    if strcmp(PSDbyAnimal.Placement(i),Place{1})
        figure(1);fig=1;
    else
        figure(2);fig=2;
    end
    switch PSDbyAnimal.Group(i)
        case 1
            ax(fig,1)=subplot(2,2,1); box off; hold on
        case 2
            ax(fig,2)=subplot(2,2,2); box off; hold on
        case 3
            ax(fig,3)=subplot(2,2,3); box off; hold on
        case 4
            ax(fig,4)=subplot(2,2,4); box off; hold on
    end
    plot(func(1).freq,PSDbyAnimal.mean_PSDdB(i,:))
end
for f = 1:size(F,1)
    for fig=1:2
        figure(fig)
        name = [F{f,2} ' ' Place{fig}];
        suptitle(name)
        cases{3} = strcmp(PSDbyAnimal.Placement,Place{fig});
        for i = 1:4
            cases{1} = PSDbyAnimal.Group==i & strcmp(PSDbyAnimal.Placement,Place{fig});
            cases{2} = PSDbyGroup.Group==i & strcmp(PSDbyGroup.Placement,Place{fig});
            plot(ax(fig,i),func(1).freq,PSDbyGroup.mean_mean_PSDdB(cases{2},:),'k')
            legend(ax(fig,i),PSDbyAnimal.Animal(cases{1})'); legend(ax(fig,i),'boxoff');
            xlabel(ax(fig,i),'Frequency (Hz)')
            ylabel(ax(fig,i),'Power (dB)')
            xlim(ax(fig,i),[F{f}(1:2)])
            ylim(ax(fig,i),[min(min(PSDbyAnimal.mean_PSDdB(:,func(1).idx{f}))) max(max(PSDbyAnimal.mean_PSDdB(:,func(1).idx{f})))])
        end
%         pause(1)
        saveas(figure(fig),[folder '\' name 'Power.pdf'])
    end
end

%% plot power by group
T2 = [T T1];
PSDbyAnimal = varfun(@mean,T2,'InputVariables',variable,'GroupingVariables',{'Group','Animal'});
ncol=width(PSDbyAnimal);
PSDbyGroup = varfun(@mean,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'Group'});
PSDstd = varfun(@std,PSDbyAnimal,'InputVariables',ncol','GroupingVariables',{'Group'});

close all
figure('Position',[20 20 620 920],'PaperOrientation','rotated');
for f = 1:size(F,1)
        a=subplot(3,2,f);
        idx = func(1).idx{f};
        x = func(1).freq';
        hold on
        for i = 1:height(PSDbyGroup)
            y = PSDbyGroup.mean_mean_PSDdB(i,:);
            sd = PSDstd.std_mean_PSDdB(i,:);
            patch('XData',[x fliplr(x)],'YData',[y-sd fliplr(y+sd)],'FaceColor',co(i,:),'FaceAlpha',0.7,'LineStyle','none')
        end
        plot(x,PSDbyGroup.mean_mean_PSDdB);
        hold off
        box off
        xlabel('Frequency (Hz)')
        ylabel({F{f,2} ;['Power (dB)']})
        xlim(F{f}(1:2))
           
        if f==4 || f==6
            a.XTick = (F{f}(1):(F{f}(2)-F{f}(1))/4:F{f}(2));
        end
        Y2 = max(max(PSDbyGroup.mean_mean_PSDdB(:,idx)+PSDstd.std_mean_PSDdB(:,idx)));
        Y1 = min(min(PSDbyGroup.mean_mean_PSDdB(:,idx)-PSDstd.std_mean_PSDdB(:,idx)))-1;
        a.YLim = [Y1 Y2];
        range = Y2-Y1;
        x=3;
        step = round(range/x,2);
        limit = Y1 + x*step+1;
        a.YLim = [Y1 limit];
        a.YTick = (Y1:step:limit);
        ytickformat('%.1f')
%         pause(1)
end
saveas(figure(1),[folder 'Power2.pdf'])


%% um plot por animal com seus trechos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;
fig=1;
ax(fig)=figure;
for i =149:height(T1)
    x = T2.PSD(i,:);
    if strcmp(T2.Animal(i),T2.Animal(i-1))
        hold on
        powerplot(func(1).freq,x,[0 100],[0 0.0001])
        legend = T2.Epoch(i);
    else
        ax(fig).Name = join([T2.Animal(i-1) T2.Placement(i-1)],' ');
        title = ax(fig).Name;
        hold off
        fig = fig+1;
        ax(fig)=figure;
        powerplot(func(1).freq,x,[0 100],[0 0.0001])
    end
end
ax(fig).Name = join([T2.Animal(i-1) T2.Placement(i-1)],' ');
title = ax(fig).Name;