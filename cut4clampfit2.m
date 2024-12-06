% Especialmente desenvolvido para dados .mat com os dados na variável
% "data" e com a dimensão da amplitude em "tickrate". 
clear all
clc

ADall = [];
nfiles = inputdlg('Quantos .mat para o mesmo Clampfit?','Input',[1 40]);

for j=1:str2num(nfiles{1}) %ativar para agrupar dados de diferentes arquivos
    if j>1
        addname='ctxhip';
    else
        addname='';
    end
    
    [file,path] = uigetfile('*.mat','Selecione o arquivo .mat para iniciar');
    file = file(1:end-4);
    filename = fullfile(path,file);
    load(filename)
    
    dt=900000; %ms
    
    % Channel detection
    Channels = [];
    nCHs = 16;
    
    for CH = 1:nCHs
        if exist(['AD' num2str(CH,'%02d')])
            Channels = [Channels; 'AD' num2str(CH,'%02d')];
        end
    end
    
    % All Channels
    if isempty(Channels)
        ADall = [ADall data'];
    else
        for CH = 1:size(Channels,1)
            AD = Channels(CH,1:4);
            ADall = [ADall eval(AD)];
        end
    end
end

ADall=ADall*tickrate;

% Save Cutted Files
N=floor(size(ADall,1)/dt);
for i=1:N
    disp(['Salvando arquivo ' num2str(i)])
    interval=1+(dt*(i-1)):dt+(dt*(i-1));
    csvwrite([filename addname '.-' num2str(i)],ADall(interval,:))
end
disp(['Salvando arquivo ' num2str(N+1)])
csvwrite([filename addname '.-' num2str(N+1)],ADall(N*dt+1:size(ADall,1),:))

%save(filename_full,'ADall','Channels','timevector','srate','file','path')

disp('Pronto!')