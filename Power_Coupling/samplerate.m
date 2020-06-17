function [srate,dt] = samplerate(myData)
%load a matlab data file and extracts it's sample rate and delta_t
    load(myData);
    namesDelta_t = who('*_ts_step');
    dt = eval(namesDelta_t{1}); % deltha t
    srate = 1/dt;               % sample rate
