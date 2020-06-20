clc
clear
% load Data

[file,path] = uigetfile({'*.xlsx;*.xls','Excel files'},'Pick an Excel epochs file');

if ~ischar(file)
  disp('User pressed Cancel');
  return;
end

cd(path)
T = readtable(file); %load epoch info from xls file

% load epochs info
epoch = struct;
matfile = T.MatFile{1};
if ~exist('srate','var')
    [epoch.srate,epoch.dt] = samplerate(['ECG/' matfile]);
end
epoch.size = T.MatEnd(1) - T.MatStart(1);
epoch.timevec = 0:epoch.dt:epoch.size;

% vectors lengths
add = 5; % number of seconds to add for filtering
T.idx = [(T.MatStart-add)*epoch.srate (T.MatEnd+add)*epoch.srate]; %start and end for each epoch
cutvec = add*epoch.srate:(epoch.size+add)*epoch.srate; % interest section of the epoch

% load lfp data from mat files
T.filter = ones(height(T),1);
for i = 1:height(T)
    
    if strcmp(matfile,T.MatFile{i}) && i~=1
    else
        matfile = T.MatFile{i};
        load(['ECG/' matfile],'AD*'); clear *_*;
        channels = who('AD*');
    end
    
    if T.idx(i,1)<0 || T.idx(i,2)>length(eval(channels{1}))
        T.filter(i)=0;  % remove from data in the next step
    else
        for ch = 1:2 % length(channels)
            lfp_long(i,:,ch) = eval([channels{ch} '(T.idx(i,1):T.idx(i,2))']);
        end
    end

end
%%
%lfp plot
%     plot(epoch.timevec,lfp(cutvec))