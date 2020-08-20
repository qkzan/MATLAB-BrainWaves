% This code helps understand the difference between using default frequency
% vector and selected frequecy vector for pwelch function
% use with event.mat

clear;clc;
load event
srate = 1000;

winlength = 4*srate; %window size
winoverlap = winlength/2; %window overlap

% default
nfft = []; 
[P,F]=pwelch(event,winlength,winoverlap,nfft,srate);

% default resultant F
[P2,F2]=pwelch(event,winlength,winoverlap,F,srate);

% default resultant F with negative and positive range
FF = unique(sort([-F; F])); 
[P3,F3]=pwelch(event,winlength,winoverlap,FF,srate);
ff = find(F3>=0);

n=1; % select event if there is more than one
y=max(P(F>=30,n));

figure(1)
subplot 311
plot(event(:,n),'k')
xlabel('Time (ms)')
ylabel('LFP (mV)')

subplot 312
plot(F,P(:,n),'b')
hold on
plot(F3,P3(:,n),'k')
hold off
xlabel('Frequency (Hz)')
ylabel('Power (mV²/Hz)')
xlim([-90 90])
ylim([0 0.00005])
legend('pwelch''s default','[-F +F]')
title('Power is calculated for + and - frequencies')

subplot(3,2,[5 6])
plot(F,P(:,n),'b',F2,P2(:,n),'r',F2,2*P2(:,n),'r.');
% plot(F,P(:,n),'b',F3(ff),P3(ff,n),'k',F3(ff),2*P3(ff,n),'k.');
xlim([30 50])
ylim([0 y])
legend('default freq vector pwelch','with selected freq vector','2 x power (-F + F)')
ylabel('Power mV²/Hz')
xlabel('Frequency (Hz)')
ylabel('Power (mV²/Hz)')
title('By default pwelch sum the + and - power of each frequency')