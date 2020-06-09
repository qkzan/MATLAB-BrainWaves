function y = filtering(x,F_range,srate)
    y=table;
    for f = 1:size(F_range,1)
        lf = F_range{f}(1);
        hf = F_range{f}(3);
        y.(f) = eegfilt(x,srate,lf,hf,0,4*fix(srate/lf));
    end
end