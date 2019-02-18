function sig = getSineSig(len, freq, amp, phase, fs)
    %GETSINESIG Generate a sinewave
    %   sig = GETSINESIG(len, freq, amp, phase, fs) returns sine wave of
    %   frequency freq, amplitude amp, with specified initial phase and
    %   at a specifed sampling frequency fs. Arguments freq and amp can
    %   either be scalars or vectors of length len, mapping the value at
    %   each index to the frequency or amplitude at the corresponding sample
    %   of the generated signal.
    %
    %   sig = GETSINESIG(len, freq, amp, phase) uses default fs = 44100.
    %
    %   sig = GETSINESIG(len, freq, amp) uses default values: phase = 0
    %   and fs = 44100.
    %
    %   sig = GETSINESIG(len, freq) uses default values: amp = 1, phase = 0
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

    if length(freq) ~= 1 && length(freq) ~= len
        error('Frequency freq must be a scalar or a vector of length len!');
    end

    if length(amp) ~= 1 && length(amp) ~= len
        error('Amplitude amp must be a scalar or a vector of length len!');
    end

    % If freq is a scalar, convert to a vector.
    if length(freq) == 1
        freq = ones(len, 1) * freq;
    end

    % If amp is a scalar, convert to a vector.
    if length(amp) == 1
        amp = ones(len, 1) * amp;
    end

    % Generate signal
    sig = zeros(len, 1);

    for n = 1:len
        sig(n) = amp(n) * sin(phase);
        phase = getNextPhase(phase, freq(n), fs);
    end

end
