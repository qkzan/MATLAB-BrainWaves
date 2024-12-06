clear all
clc

[file,path] = uigetfile('*.mat','Selecione o arquivo .mat para iniciar');
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
for CH = 1:size(Channels,1)
    AD = Channels(CH,1:4);
    ADall(:,CH) = eval(AD);
end

% Save Cutted Files
N=floor(size(ADall,1)/dt);
for i=1:N
    disp(['Salvando arquivo ' num2str(i)])
    interval=1+(dt*(i-1)):dt+(dt*(i-1));
    csvwrite([filename(1:end-4) '.-' num2str(i)],ADall(interval,:))
end
disp(['Salvando arquivo ' num2str(N+1)])
csvwrite([filename(1:end-4) '.-' num2str(N+1)],ADall(N*dt+1:size(ADall,1),:))

srate = 1/eval([Channels(1,1:4) '_ts_step']);
timevector = (0:length(eval(Channels(1,1:4)))-1)/srate;
timevector = timevector+eval([Channels(1,1:4) '_ts']);

save([filename(1:end-4) '_full.mat'],'ADall','Channels','timevector','srate','file','path')

disp('Pronto!')