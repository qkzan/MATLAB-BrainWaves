function [MI,MeanAmp,bins,step] = couplingMI2(lfdata,hfdata,type)
% [MI] = couplingMI(couplingType,t,lfp1,lfp2)
%
% coupling type is a char vector with these possible values:
%           'pp' - phase x phase coupling
%           'pa' - phase x amplitude coupling
%           'pf' - fase x frequency coupling
%           'aa' - amplitude x amplitude coupling
%           'af' - amplitude x frequency coupling
%           'ff' - frequency x frequency coupling
% lfp1 and lfp2 are same original data vectors to be analysed filtered for different frequencies
% graphics = 'on' or 'off'
% sflabel = slow frequency label
% hflabel = high frequency label

switch type
    
    case {'aa','af','ff'}
        step = 0.05*(max(lfdata)-min(lfdata));
        bins = min(lfdata):step:max(lfdata)-step;
    
    case {'pa','pf'}
        if max(lfdata)<=pi
            lfdata = rad2deg(lfdata);
        end
        step = 20;
        bins = -180:step:160;
    
    case 'pp' % circular mean is needed 
        disp('Not available yet')
%https://www.mathworks.com/matlabcentral/fileexchange/10676-circular-statistics-toolbox-directional-statisticshttps://www.mathworks.com/matlabcentral/fileexchange/10676-circular-statistics-toolbox-directional-statistics
%         if max(lfdata)<=pi
%             lfdata = rad2deg(lfdata);
%         end
%         if max(hfdata)<=pi
%             lfdata = rad2deg(hfdata);
%         end
%         
%         step = 20;
%         bins = -180:step:160;
    otherwise
        disp('Enter a valid coupling method: pa, pf, pp, aa, af or ff')
end

count=0;
for bin = bins
    count = count+1;
%     if strcmp(type,'pp')
%     else
    MeanAmp(count) = median(hfdata(lfdata > bin & lfdata <= bin+step));
%     end
end

p = MeanAmp/sum(MeanAmp);
H = -sum(p(p>0).*log(p(p>0)));
N = length(MeanAmp);
Hmax=log(N);
MI = (Hmax-H)/Hmax;
