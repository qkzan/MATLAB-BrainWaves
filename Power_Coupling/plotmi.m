function [MI,p,bins,step,MI_surr,MI_threshold,sig] = misurr(lfdata,hfdata,type,N_surr,id)
% [MI,p,bins,step,lfdata] = couplingMI(lfdata,hfdata,type)
%
% coupling type is a char vector with these possible values:
%           'pp' - phase x phase coupling
%           'pa' - phase x amplitude coupling
%           'pf' - fase x frequency coupling
%           'aa' - amplitude x amplitude coupling
%           'af' - amplitude x frequency coupling
%           'ff' - frequency x frequency coupling
% lfdata and hfdata are same lfp data vectors filtered for different frequencies
% N_surr number of surrogates
% id is a label for the name of the graphic file

if strcmp(type,'pp')
    % circular mean is needed 
        disp('Not available yet')
        return
end

switch type(1)  
    case {'a','f'}
        label1 = 'amp ratio';  
    case {'p'}
        label1 = 'phase (º)';
end

switch type(2)
    case 'a'
        label2 = ["Median high f amp."; "(normalized)"];
    case 'f'
        label2 = ["Median high f inst. freq." ; "(normalized)"];
    case 'p'
        label2 = ["Median high f phase"; "(normalized)"];
end

[MI,p,bins,step,lfdata] = couplingMI(lfdata,hfdata,type);

%%
% return a matriz of n surrogates of phase for a phase original vector
% n will be the number rows and the columns are the timepoints

bins_surr = [bins bins(end)+step];

% % Getting the start and end point of each phase bin...
onoff_all=[];

for ibin = 1:length(bins_surr)-1
    idx = lfdata>bins_surr(ibin) & lfdata<=bins_surr(ibin+1);
    
    onset = find(diff(idx)==1)+1;
    offset = find(diff(idx)==-1);
    
    if offset(1)<onset(1)
        onset = [1 onset];
    end
    if onset(end)>offset(end)
        offset = [offset length(lfdata)];
    end
    
    onoff_all = [onoff_all; onset(:) offset(:)];
end

% % Building the new phase vector (repeat the following to each surrogate..)
for isurr=1:N_surr
    new_phase = [];
    
    % Get a random order vector with sort on random numbers
    [~, randorder] = sort(rand(1,size(onoff_all,1)));
        
    for i = randorder
        new_phase = [new_phase lfdata(onoff_all(i,1):onoff_all(i,2))];
    end
    
    newPhase(isurr,:) = new_phase;
end

for isurr = 1:N_surr
    [mi_surr(isurr)] = couplingMI(newPhase(isurr,:),hfdata,type);
end

%%
MI_surr = mean(mi_surr);
MIsdt_surr = std(mi_surr);

z_surr = (MI - MI_surr)/MIsdt_surr;

MI_threshold = 1.65*MIsdt_surr+MI_surr;

z_threshold = 1.65; % para um teste unicaudal, com intervalo de confiança de 95%

if z_surr > z_threshold
    sig = 1; % sim, foi significativo
else 
    sig = 0; % não, não foi significativo
end

% bar([bins bins+bins(end)],[p flip(p)],1,'k')
% xticks([min(Pha):10*step:2*max(lfdata)]-step/2)
% xlbl = min(lfdata):10*step:max(lfdata);
% xticklabels(round([xlbl flip(xlbl(1:end-1))]/max(lfdata),1))
% xlabel(['Normalized low f amplitude range'])
% ylabel(['Mean high f amplitude (normalized)'])
% ylim([0 0.10])
% box off
% title(['Modulation Index = ' num2str(MIaa)])

% subplot(1,2,1)
% bar([10:20:710],[p p],1,'k')
% set(gca,'xtick',0:90:720)
% xlim([0 720]); ylim([0 0.1]); box off
% xlabel(['Low f ' label1])
% ylabel(label2)
% title(id)
% 
% subplot(1,2,2)
% bar([1],[MI],1,'k')
% hold on
% plot([0 2], [MI_threshold MI_threshold],':r','linew',2)
% plot([0 2], [MI_surr+MIsdt_surr MI_surr+MIsdt_surr],':b','linew',2)
% axis tight
% ylim([0 0.1]); box off
% title(['Modulation Index = ' num2str(MI)])
% %%
% saveas(gcf,id,'pdf')
% saveas(gcf,id,'jpeg')  