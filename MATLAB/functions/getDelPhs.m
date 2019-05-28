function delPhs = getDelPhs(freq, fs)
    %GETDELPHS Compute phase increments
    %   delPhs = getDelPhs(freq, fs) returns phase increments between 
    %   consecutive samples of a sinusoidal signal with frequency values
    %   specified in freq.

    delPhs = mod(2 * pi * freq / fs, 2 * pi);
end
