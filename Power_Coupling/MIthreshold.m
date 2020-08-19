function [result] =  MIthreshold(MI,meanMI_surr,MIsdt_surr)
% Esta função serve para indicar se passou de um limiar de dados aleatórios
% para MI
% [MI,p,bins,step] = couplingMI2(Pha,Amp,'pa');
% N_surr = 500;
% 
% mi_surr = MI; % rever
% 
% MI_surr = mean(mi_surr);
% MIsdt_surr = std(mi_surr);

z_surr = (MI - meanMI_surr)/MIsdt_surr;

z_threshold = 1.65; % para um teste unicaudal, com intervalo de confiança de 95%

if z_surr > z_threshold
    result = 1; % sim, foi significativo
else 
    result = 0; % não, não foi significativo
end