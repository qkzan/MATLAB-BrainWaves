clc
clear

[file,path] = uigetfile({'*.xlsx;*.xls','Excel files'},'Pick an Excel epochs file');

if ~ischar(file)
  disp('User pressed Cancel');
  return;
end

cd(path)
readtable(file) %creates a table by reading column oriented data from a file

% Select data
T = ans(end-4:end,:);
% T = ans;

if ~exist('srate','var')
    [srate,dt] = samplerate(['ECG/' T.MatFile{1}]);
end
%%
AnimalID = strcat( T.Factor1," ",T.Factor2," ",num2str(T.Animal_));
Data2 = table(T.TrechoID,...
              strcat( T.Factor1," ",T.Factor2," ",num2str(T.Animal_)),...
              T.Group_,...
              'VariableNames',{'Epoch','Animal'      ,'Group'});
Places = [T.AD10([1:3 5],:) ; T.AD12([1:3 5],:)];
T1 = [repmat(Data2([1:3 5],:),2,1), Places];
T1.Properties.VariableNames(end)={'Placement'};
Data = [Data(1:149,:); T1];
%%
load(['ECG/' T.MatFile{1}],'AD*'); clear *_*

for i= 1:height(T)
    teste(i,:) = AD10((T.MatStart_s_(i)-5)*srate:(T.MatEnd_s_(i)+5)*srate)';
    teste2(i,:) = AD12((T.MatStart_s_(i)-5)*srate:(T.MatEnd_s_(i)+5)*srate)';
end
lfp_wavelets = [teste([1:3 5],:); teste2([1:3 5],:)];
%% Filt

notchfilter = [59.5  60.5 
               119.4 120.4 
               179.5 180.5 
               239.3 240.3];
           
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


%%
selectedLFPs = [selectedLFPs(1:149,:); lfp_notchfilt];

save Data selectedLFPs Data