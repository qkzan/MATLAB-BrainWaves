function powerplot(freq,x,xlimiters,ylimiters,scale,normal)
if nargin<6
    label = 'Power (mV²/Hz)';
elseif strcmp(scale,'dB')
    label = 'Power (dB)';
elseif normal == 's'
    if strcmp(scale,'dB')
        label = 'Normalized power';
    else
        label = 'Normalized dB power';
    end
end
for i = 1:size(x,1)
    plot(freq,x)
    legend;
    legend('boxoff');
    xlabel('Frequency (Hz)')
    ylabel(label)
    xlim(xlimiters)
    ylim(ylimiters)
end

end