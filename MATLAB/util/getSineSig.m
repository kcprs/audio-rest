function sig = getSineSig(freq, len, amp, phase, fs)
    %GETSINESIG Generate a sinewave of given frequency and length in samples
    %   sig = GETSINESIG(freq, len, amp, phase, fs) returns sine wave of
    %   frequency freq, amplitude amp, with specified initial phase and
    %   at a specifed sampling frequency fs. Arguments freq and amp can
    %   either be scalars or vectors of length len, mapping the value at
    %   each index to the frequency or amplitude at corresponding sample of
    %   the generated signal. If freq is given as a vector, the phase
    %   argument is interpreted as the phase at index 0 (the sample
    %   preceeding the generated signal).
    %
    %   sig = GETSINESIG(freq, len, amp, phase) uses default fs = 44100.
    %
    %   sig = GETSINESIG(freq, len, amp) uses default values: phase = 0
    %   and fs = 44100.
    %
    %   sig = GETSINESIG(freq, len) uses default values: amp = 1, phase = 0
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
        skipFirstPhase = false;
    else
        % If freq is a vector, treat the phase argument as the phase of the
        % preceeding sample.
        skipFirstPhase = true;
    end

    % If amp is a scalar, convert to a vector.
    if length(amp) == 1
        amp = ones(len, 1) * amp;
    end

    % Initialise
    sig = zeros(len, 1);
    n = 1;

    % Generate signal
    while n <= len

        if skipFirstPhase
            phase = getNextPhase(phase, freq(n), fs);
        end

        sig(n) = amp(n) * sin(phase);
        n = n + 1;
        skipFirstPhase = true;
    end

end
