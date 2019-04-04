function sig = getSawSig(len, freq, mag, fs)
    %GETSAWSIG Generate a sawtooth wave
    %   sig = GETSAWSIG(len, freq, mag, fs) returns sawtooth wave of
    %   frequency freq, magnitude mag (in dBFS) at a specifed sampling
    %   frequency fs. Arguments freq and mag can either be scalars or
    %   vectors of length len, mapping the value at each index to the
    %   frequency or magnitude at the corresponding sample of the generated
    %   signal.
    %
    %   sig = GETSAWSIG(len, freq, mag) uses default fs = 44100.
    %
    %   sig = GETSAWSIG(len, freq) uses default values: mag = 0, phase = 0
    %   and fs = 44100.

    if nargin < 4
        fs = 44100;
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
    freqHrm = freq;
    harmInd = 1;

    % Using additive synthesis as described in link below
    % (https://en.wikipedia.org/wiki/Sawtooth_wave)
    while any(2 * freqHrm < fs)
        harm = getSineSig(len, freqHrm, mag, 0, fs) .* (2 * freqHrm < fs);
        sig = sig + (-1) ^ harmInd * harm / harmInd;

        harmInd = harmInd + 1;
        freqHrm = freq * harmInd;
    end

    sig = 2 * sig / pi;
end