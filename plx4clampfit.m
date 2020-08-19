clear

[file,path] = uigetfile('.plx','Selecione o arquivo .plx para iniciar');
file = file(1:end-4);
filename = fullfile(path,file);
plx = readPLXFileC([filename '.plx'],'all');

%%
ADall = [];
Channels = [];
ampbybit = plx.ContMaxMagnitudeMV/plx.BitsPerContSample;

for i=1:length(plx.ContinuousChannels)
 if plx.ContinuousChannels(i).Enabled==1
     gain = plx.ContinuousChannels(i).ADGain*plx.ContinuousChannels(i).PreAmpGain;
     ADall = [ADall double(plx.ContinuousChannels(i).Values)/409.6];
     Channels = [Channels; plx.ContinuousChannels(i).Name];
     srate= plx.ContinuousChannels(i).ADFrequency;
 end
end

timevector = 1:size(ADall,1);

%% Cut files for Clampfit
dt=900000; %ms

% Save Cutted Files
N=floor(size(ADall,1)/dt);
for i=1:N
    disp(['Salvando arquivo ' num2str(i)])
    interval=1+(dt*(i-1)):dt+(dt*(i-1));
    csvwrite([filename '.-' num2str(i)],ADall(interval,:))
end
disp(['Salvando arquivo ' num2str(N+1)])
csvwrite([filename '.-' num2str(N+1)],ADall(N*dt+1:size(ADall,1),:))

save([filename '_full'],'ADall','Channels','timevector','srate','file','path')
disp('Pronto!')