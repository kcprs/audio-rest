function sig = getSineSig(len, freq, mag, phase, fs)
    %GETSINESIG Generate a sinewave
    %   sig = GETSINESIG(len, freq, mag, phase, fs) returns sine wave of
    %   frequency freq, magnitude mag (in dBFS), with specified initial
    %   phase and at a specifed sampling frequency fs. Arguments freq and
    %   mag can either be scalars or vectors of length len, mapping the
    %   value at each index to the frequency or magnitude at the
    %   corresponding sample of the generated signal.
    %
    %   sig = GETSINESIG(len, freq, mag, phase) uses default fs = 44100.
    %
    %   sig = GETSINESIG(len, freq, mag) uses default values: phase = 0
    %   and fs = 44100.
    %
    %   sig = GETSINESIG(len, freq) uses default values: mag = 0, phase = 0
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

    if length(freq) ~= 1 && length(freq) ~= len
        error('Frequency freq must be a scalar or a vector of length len!');
    end

    if length(mag) ~= 1 && length(mag) ~= len
        error('Magnitude mag must be a scalar or a vector of length len!');
    end

    % If freq is a scalar, convert to a vector.
    if length(freq) == 1
        freq = ones(len, 1) * freq;
    end

    % If mag is a scalar, convert to a vector.
    if length(mag) == 1
        mag = ones(len, 1) * mag;
    end

    % Generate signal
    sig = zeros(len, 1);

    for n = 1:len
        sig(n) = 10^(mag(n) / 20) * sin(phase);
        phase = getNextPhase(phase, freq(n), fs);
    end

end
