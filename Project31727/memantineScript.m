% get epoch data, including lfp
clear;close;

resultspath = 'C:\Users\queru\OneDrive - Universidade Federal do Rio Grande do Sul\MATLAB\Gabi\20200805-revisão';
cd(resultspath) 
datapath = 'C:\Users\queru\OneDrive - Universidade Federal do Rio Grande do Sul\MATLAB\Gabi\Dados\';
Trechos; %load F;

srate = 1000; %Hz
count = 1;

for N = [1:4 6:length(animal)]
%     for N = [1:length(animal)]
    
    group = animal(N).grupo;
    
    if iscell(animal(N).arquivo)
        files = animal(N).arquivo;
        channels = animal(N).canais{1};
    else
        files = {animal(N).arquivo};
        channels = animal(N).canais;
    end
    disp(files)
    
    for CH = 1:length(channels)
        events_all = [];
        trecho = 1;
        for nfile = 1:length(files)
            if iscell(animal(N).inicio)
                starts = animal(N).inicio{nfile};
            else
                starts = animal(N).inicio;
            end
            ends = starts + 30*srate;
            
            filename = char(files{nfile});
            load([datapath filename])
            
            events=[];
            for i = 1:length(starts)
                canais(count,1) = channels(CH);
                lfp{count,1} = eval(['AD' num2str(channels(CH)) '(starts(i):ends(i))']);
                grupotto(count,1) = group;
                Nrato(count,1) = str2double(filename(6:7));
                Trecho(count,1) = trecho;
                switch trecho
                    case {1,2}
                        periodo = 1; %basal
                    case {3,4}
                        periodo = 2; %tto
                    case 5
                        periodo = 3; %pre ictal
                    case 6
                        periodo = 4; %pós ictal
                    otherwise
                        periodo = 5; %outros
                end
                period(count,1) = periodo;
                trecho = trecho + 1;
                count=count+1;
            end
        end
    end
end

Data = table(grupotto,Nrato,canais,period,lfp);
clearvars -except Data srate 
disp('Done')

%% fazer o psd
winlength = 4*srate; %window size
winoverlap = winlength/2; %window overlap

%DB1 F=2045
[~,f]=pwelch(Data.lfp{1,:},winlength,winoverlap,[],srate);
F = f(f<=59.5 | f>=60.5); clear f;
Data = [Data rowfun(@(x) pwelch(x,winlength,winoverlap,F,srate)',...
    Data(:,end),'OutputVariableNames','PSD')];

%DB2 F=2049
% [~,F]=pwelch(Data.lfp{1,:},winlength,winoverlap,[],srate);
% Data = [Data rowfun(@(x) pwelch(x,winlength,winoverlap,[],srate)',Data(:,end),'OutputVariableNames','PSD')];

% define as faixas de frequência
F_range = { find(F>=1   & F<=4) 'Delta'     % delta (1)
            find(F>4    & F<=12) 'Theta'    % theta (2)
            find(F>=30  & F<=50) 'Slowgamma'   % slow gamma (3)
            find(F>50 & F<=59.5 | F>=60.5 & F<=90) 'Middlegamma'   % middle gamma(4)
            find(F>90   & F<=150)  'Fastgamma'}; % fast gamma (5)

% band frequency mean before epochs mean
% for i=1:length(F_range)
%     Data = [Data rowfun(@(x) mean(x(F_range{i,1}),2),Data(:,'PSD'),'OutputVariableNames',F_range{i,2})];
% end

% DataMean = varfun(@(x) mean(x,1),Data,'InputVariables',{'PSD',F_range{:,2}},...
%     'GroupingVariables',{'grupotto','Nrato','canais','period'});
% DataMean.Properties.VariableNames = replace(DataMean.Properties.VariableNames,'Fun_','Mean');

% band frequency mean after epochs mean
DataMean = varfun(@(x) mean(x,1),Data,'InputVariables','PSD',...
    'GroupingVariables',{'grupotto','Nrato','canais','period'});
DataMean.Properties.VariableNames = replace(DataMean.Properties.VariableNames,'Fun_','Mean');

for i=1:length(F_range)
    Data4(:,i) = [rowfun(@(x) mean(x(F_range{i,1}),2),DataMean(:,'MeanPSD'))];
end
Data4.Properties.VariableNames = F_range(:,2);
DataMean = [DataMean(:,1:6) Data4];

disp('Done')

%% juntar com o filtro
nomedatable = [resultspath '\dados_brutos_TCC_vertical.xlsx'];
DataSPSS = readtable(nomedatable); 
DataSPSS = DataSPSS(:,[6:8 10 1]);

DB = innerjoin(DataMean,DataSPSS(:,1:5),'Keys',[1:4]);
save DBmediaPSD_antesBandasF DB srate F Data
% save DB DB srate F Data

%% plot data
clear; clc; close all

% load DB
load DBmediaPSD_antesBandasF

DB2 = DB(DB{:,'Filtro'}==1 & DB{:,'period'}<4,:);

% writetable(DB2(:,[1:5 7:12]),'QuantifPower3.xlsx')

folder = 'graficos2SEM/';
mkdir(folder)

co = [186/255 207/255 236/255;
    0 118/255 192/255;
    241/255 182/255 130/255;
    227/255 124/255 29/255];

variable = 'MeanPSD'; % média já calculada por animal, período e canal

% %calcula a média por animal e período
% PSDbyAnimal = varfun(@(x) mean(x,1),DB2(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','Nrato','period'});
% ncol=width(PSDbyAnimal);
% PSDbyGroup = varfun(@(x) mean(x,1),PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'grupotto','period'});
% PSDstd = varfun(@std,PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'grupotto','period'});

%calcula a média por grupo e período para período 2 e 3
PSDbyGroup = varfun(@(x) mean(x,1),DB2(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','period'});
PSDstd = varfun(@(x) std(x,0,1),DB2(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','period'});
PSDstd.SEM = PSDstd.Fun_MeanPSD./sqrt(PSDstd.GroupCount);
% PSDstd.SD = PSDstd.Fun_MeanPSD;
% %

f = F(F<=59.5 | F>=60.5)';
PSD = PSDbyGroup.(4)(:,F<=59.5 | F>=60.5);
errorbar = PSDstd.(5)(:,F<=59.5 | F>=60.5);

for period = 2:3
    figure(period)
    set(figure(period),'Position',[1,1,370,263],'PaperOrientation','rotated');
    idx = PSDbyGroup{:,'period'}==period;
    y = PSD(idx,:);
    sd = errorbar(idx,:);
    for i = 4:-1:1
        plot(f,y(i,:),'linew',2,'Color',co(i,:));
        hold on;
        patch([f fliplr(f)],[y(i,:)-sd(i,:) fliplr(y(i,:)+sd(i,:))],co(i,:),'FaceAlpha',0.4,'LineStyle','none')
    end
    ylabel('Power (mV²/Hz)')
    xlabel('Frequency (Hz)')
    switch period
        case 2
            title('Treatment')
        case 3
            title('Pre-ictal')
    end
    box off
    
    xlim([0 12])
    xticks(0:2:12)
    idxf = F>=0 & F<=12;
    ylim([min(min(y(:,idxf)-sd(:,idxf))) max(max(y(:,idxf)+sd(:,idxf)))])
    set(gca,'FontSize',16)
    saveas(gcf,[folder 'PSD_deltatheta_Period' num2str(period)],'pdf')
    saveas(gcf,[folder 'PSD_deltatheta_Period' num2str(period)],'jpeg')
    
    
    xlim([30 150])
    xticks(40:20:140)
    idxf = F>=30 & F<=150;
    ylim([min(min(y(:,idxf)-sd(:,idxf))) max(max(y(:,idxf)+sd(:,idxf)))])
    set(gca,'FontSize',16)
    saveas(gcf,[folder 'PSD_gamma_Period' num2str(period)],'pdf')
    saveas(gcf,[folder 'PSD_gamma_Period' num2str(period)],'jpeg')
end
% %
close all
DB3=DB2;

idx=find(DB3{:,1}==2);
DB3(idx,1)=table(ones(length(idx),1));

idx = find(DB3{:,1}==4|DB3{:,1}==3);
DB3(idx,1)=table(ones(length(idx),1)*3);

clear PSDbyAnimal PSDbyGroup PSDstd
%calcula a média por animal e período
% PSDbyAnimal = varfun(@(x) mean(x,1),DB3(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','Nrato','period'});
% ncol=width(PSDbyAnimal);
% PSDbyGroup = varfun(@(x) mean(x,1),PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'grupotto','period'});
% PSDstd = varfun(@(x) std(x,0,1),PSDbyAnimal,'InputVariables',ncol,'GroupingVariables',{'grupotto','period'});
% PSDstd.SEM = PSDstd.Fun_Fun_MeanPSD./sqrt(PSDstd.GroupCount);

%calcula a média por grupo e período para o período 1
PSDbyGroup = varfun(@(x) mean(x,1),DB3(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','period'});
PSDstd = varfun(@(x) std(x,0,1),DB3(:,1:6),'InputVariables',variable,'GroupingVariables',{'grupotto','period'});
PSDstd.SEM = PSDstd.Fun_MeanPSD./sqrt(PSDstd.GroupCount);
% %
f = F(F<=59.5 | F>=60.5)';
PSD = PSDbyGroup.(4)(:,F<=59.5 | F>=60.5);
errorbar = PSDstd.(5)(:,F<=59.5 | F>=60.5);

for period = 1
    figure(period)
    set(figure(period),'Position',[1,1,370,263],'PaperOrientation','rotated');
    idx = PSDbyGroup{:,'period'}==period;
    y = PSD(idx,:);
    sd = errorbar(idx,:);
    for i = 1:2
        plot(f,y(i,:),'linew',2,'Color',co(2*i-1,:)); hold on;
        patch([f fliplr(f)],[y(i,:)-sd(i,:) fliplr(y(i,:)+sd(i,:))],co(2*i-1,:),'FaceAlpha',0.4,'LineStyle','none');
    end
    ylabel('Power (mV²/Hz)')
    xlabel('Frequency (Hz)')
    title('Basal')
    box off
    
    xlim([0 12])
    xticks(0:2:12)
    idxf = F>=0 & F<=12;
    ylim([min(min(y(:,idxf)-sd(:,idxf))) max(max(y(:,idxf)+sd(:,idxf)))])
    set(gca,'FontSize',16)
    saveas(gcf,[folder 'PSD_deltatheta_Period' num2str(period)],'pdf')
    saveas(gcf,[folder 'PSD_deltatheta_Period' num2str(period)],'jpeg')
    
    
    xlim([30 150])
    xticks(40:20:140)
    idxf = F>=30 & F<=150;
    ylim([min(min(y(:,idxf)-sd(:,idxf))) max(max(y(:,idxf)+sd(:,idxf)))])
    set(gca,'FontSize',16)
    saveas(gcf,[folder 'PSD_gamma_Period' num2str(period)],'pdf')
    saveas(gcf,[folder 'PSD_gamma_Period' num2str(period)],'jpeg')
end


