function sine = getSineSig(freq, len, phase, fs)
    %GETSINESIG Generate a sine wave of given frequency and length in samples
    %   sine = GETSINESIG(freq, len, phase, fs) returns sine wave of
    %   of frequency freq, with specified initial phase and at a specifed
    %   sampling frequency fs. 
    % 
    %   sine = GETSINESIG(freq, len, phase) uses default fs = 44100
    % 
    %   sine = GETSINESIG(freq, len) uses default fs = 44100 and phase = 0

    if nargin < 4
        fs = 44100;
    end

    if nargin < 3
        phase = 0;
    end

    n = (1:len)';
    sine = sin(2 * pi * (n - 1) * freq / fs + phase);
end
