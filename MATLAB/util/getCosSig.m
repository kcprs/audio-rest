function sig = getCosSig(len, freq, mag, phase, fs)
    %GETCOSSIG Generate a cosine wave
    %   sig = GETCOSSIG(len, freq, mag, phase, fs) returns cosine wave of
    %   frequency freq, magnitude mag (in dBFS), with specified initial
    %   phase and at a specifed sampling frequency fs. Arguments freq and
    %   mag can either be scalars or vectors of length len, mapping the
    %   value at each index to the frequency or magnitude at the
    %   corresponding sample of the generated signal.
    %
    %   sig = GETCOSSIG(len, freq, mag, phase) uses default fs = 44100.
    %
    %   sig = GETCOSSIG(len, freq, mag) uses default values: phase = 0
    %   and fs = 44100.
    %
    %   sig = GETCOSSIG(len, freq) uses default values: mag = 0, phase = 0
    %   and fs = 44100.
    
    if nargin < 5
        fs = 44100;
    end

    if nargin < 4
        phase = 0;
    end

    if nargin < 3
        mag = 0;
    end

    sig = getSineSig(len, freq, mag, phase + 0.5 * pi, fs);
end