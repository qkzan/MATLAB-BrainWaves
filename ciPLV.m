clear
clc
load ciPLVsample

% Dados    = T1;
% Left     = Dados(Dados{:,4}=="CtxE",:);
% Right    = Dados(Dados{:,4}=="CtxD",:);
% Dados2CH = innerjoin(Left,Right,'Keys',[1:3]);

left  = M(2:2:10,:);    % trechos do canal 1
right = M(1:2:10,:);   % trechos do canal 2

srate = 1000;   % taxa de amostragem
dt    = 1/srate;
freq  = F_psd;     % vetor de frequencias de interesse

%% Definir limites de faixas de frequencias
F = { [1        4        4]         'Delta'     %(1)
      [4        12       12]        'Theta'     % (2)
      [12       30       25]        'Beta'      % (3) %% 25 para filtrar e 30 para power
      [30       50       50]        'SG'        %(4)
      [50       90       90]        'MG'        %(5)
      [90       150      150]       'FG' };     % (6)
  
%% wavelet com fcs diferentes por banda de frequencia (parte 1/2): construindo as escalas para cada faixa
nfreq = size(F,1);
idx = cell(nfreq,1);
wavelet(nfreq) = struct('frequencies',[],'Fc',[],'Fb',[],...
                        'motherwave',[],'scale',[],...
                        'mother_psi',[],'tt',[]);

for f=1:nfreq
    startpoint = F{f,1}(1);
    endpoint = F{f,1}(2);
    idx{f} = find(F_psd >= startpoint & F_psd < endpoint);
    wavelet(f).frequencies = F_psd(idx{f});
    
    wavelet(f).Fb = 2;
    wavelet(f).Fc = wavelet(f).frequencies(1);
            
    wavelet(f).motherwave = ['cmor' num2str(wavelet(f).Fb) '-' num2str(wavelet(f).Fc)];
    % [wavelet.mother_psi,wavelet.tt] = wavefun(wavelet.motherwave,20);
    % figure(2); plot(wavelet.tt,real(wavelet.mother_psi));
    wavelet(f).scale = centfrq(wavelet(f).motherwave)./(wavelet(f).frequencies*dt);
end

%% wavelet com central frequencies diferentes por banda de frequencia (parte 2/2)
for n=1:height(left)
    x = right(n,:);
    y = left(n,:);
    WavTransf1 = [];
    WavTransf2 = [];
    for f=1:nfreq
        wavtransf1 = cwt(x,wavelet(f).scale,wavelet(f).motherwave);
        wavtransf2 = cwt(y,wavelet(f).scale,wavelet(f).motherwave);
        WavTransf1 = [WavTransf1; wavtransf1];
        WavTransf2 = [WavTransf2; wavtransf2];
        clear wavtransf1 wavtransf2
    end
end

%% ciPLV
for n=1:height(left)
    Phase1 = angle(WavTransf1);
    Phase2 = angle(WavTransf2);
    pha_diff = Phase1-Phase2; %%%%%
    
    MeanVector = mean(exp(1i*pha_diff),2);
    
    ciPLV(n,:) = abs(imag(MeanVector)./sqrt(1-real(MeanVector).^2));
    
    ciPLV = [Dados2CH(:,1:3) table(ciPLV)];
end

%% saving data to excel
variable = 'ciPLV';
xlsfilemane = 'A:\OneDrive - Universidade Federal do Rio Grande do Sul\WARCrio\Manuscrito\Results\syncronyIndex_M\SynIdx.xlsx';
writetable(ciPLV,xlsfilename,'sheet',variable,'Range','A1')
%% savind data table
save ciPLV_table.mat ciPLV

%% Plot do grafico do espectro

% load ciPLV_table.mat

figure(3)
variable = 'ciPLV';
tab = eval(variable);
tab(:,end) = varfun(@log10,tab,'InputVariables',variable);

G_mean = varfun(@mean,tab,'InputVariables',variable,'GroupingVariables',{'Group'});
G_std = varfun(@std,tab,'InputVariables',variable,'GroupingVariables',{'Group'});

co = [  86  152 163 ;
        0   47  48  ;
        241 182 130 ;
        227 124 29  ]/255; %color code

for i=[2 4 3 1]
    sd=G_std{i,['std_' variable]}; %desvio padrão
    y=G_mean{i,['mean_' variable]}; %coerencia media do grupo
    plot (freq,y, 'color',co(i,:), 'linew',1);
    hold on
    fill([freq' fliplr(freq')],[y-sd fliplr(y+sd)],co(i,:),'FaceAlpha',0.06,'LineStyle','none');
end
hold off

box off
xlabel('Frequency (Hz)','FontSize',14,'FontName','Calibri');
ylabel(['log_{10}(' variable ')'],'FontSize',14,'FontName','Calibri');
ylim([-3.5 0])
set(gca,'FontSize',14,'XTick',[0 20 40 60 80 100 120 140]);
set(gcf,'Position',[75,257,1068,468],'PaperOrientation','landscape','PaperUnits','centimeters',...
    'PaperSize',[27.94 21.59])