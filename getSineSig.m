function sine = getSineSig(freq, duration, fs)
    %GETSINESIG Generate a sine wave of given frequency and length
    %   sine = GETSINESIG(freq, duration) uses default fs = 44100
    % 
    %   sine = GETSINESIG(freq, duration, fs) returns sine wave at a
    %   specifed sampling frequency

    if nargin == 2
        fs = 44100;
    end

    n = 1:(fs * duration);
    sine = sin(2 * pi * n * freq / fs);
end
