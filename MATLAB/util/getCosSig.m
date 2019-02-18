function sig = getCosSig(len, freq, amp, phase, fs)
    %GETCOSSIG Generate a cosine wave
    %   sig = GETCOSSIG(len, freq, amp, phase, fs) returns cosine wave of
    %   frequency freq, amplitude amp, with specified initial phase and
    %   at a specifed sampling frequency fs. Arguments freq and amp can
    %   either be scalars or vectors of length len, mapping the value at
    %   each index to the frequency or amplitude at the corresponding sample
    %   of the generated signal.
    %
    %   sig = GETCOSSIG(len, freq, amp, phase) uses default fs = 44100.
    %
    %   sig = GETCOSSIG(len, freq, amp) uses default values: phase = 0
    %   and fs = 44100.
    %
    %   sig = GETCOSSIG(len, freq) uses default values: amp = 1, phase = 0
    %   and fs = 44100.
    
    if nargin < 5
        fs = 44100;
    end

    if nargin < 4
        phase = 0;
    end

    if nargin < 3
        amp = 1;
    end

    sig = getSineSig(len, freq, amp, phase + 0.5 * pi, fs);
end