function sine = getSineSig(freq, len, fs)
    %GETSINESIG Generate a sine wave of given frequency and length in samples
    %   sine = GETSINESIG(freq, len) uses default fs = 44100
    % 
    %   sine = GETSINESIG(freq, len, fs) returns sine wave at a
    %   specifed sampling frequency

    if nargin == 2
        fs = 44100;
    end

    n = 1:len;
    sine = sin(2 * pi * n * freq / fs);
end
