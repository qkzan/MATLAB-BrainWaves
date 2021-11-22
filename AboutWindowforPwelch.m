% This code helps understand the difference between using different
% windows for pwelch

clear;clc;
load event
srate = 1000;
dt = 1/srate;
timevec = dt:dt:length(event)*dt;

nfft = []; 

winlength1 = 4*srate; %window size
winoverlap = winlength1/2; %window overlap
[P1,F1]=pwelch(event,winlength1,winoverlap,nfft,srate);

winlength2 = 2*srate; %window size
winoverlap = winlength2/2; %window overlap
[P2,F2]=pwelch(event,winlength2,winoverlap,nfft,srate);

figure(1)
subplot (3,1,1)
plot(timevec,event,'k')
xlabel('Time (s)')
ylabel('LFP (mV)')
xlim([0 20])
ylim([-0.5 0.5])
box off

subplot (3,1,[2 3])
plot(F1,P1,'k.-','MarkerSize',10)
hold on
plot(F2,P2,'r.-','MarkerSize',10)
hold off
xlabel('Frequency (Hz)')
ylabel('Power (mV²/Hz)')
xlim([100 150])
legend('4s window','2s window')
box off
