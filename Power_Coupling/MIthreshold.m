function [result] =  MIthreshold(MI,meanMI_surr,MIsdt_surr)

% [MI,p,bins,step] = couplingMI2(Pha,Amp,'pa');
% N_surr = 500;
% 
% mi_surr = MI; % rever
% 
% MI_surr = mean(mi_surr);
% MIsdt_surr = std(mi_surr);

z_surr = (MI - meanMI_surr)/MIsdt_surr;

z_threshold = 1.65; % para um teste unicaudal, com intervalo de confian�a de 95%

if z_surr > z_threshold
    result = 1; % sim, foi significativo
else 
    result = 0; % n�o, n�o foi significativo
end