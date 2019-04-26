function sig = getCosSig(len, freq, mag, phs, fs)
    %GETCOSSIG Generate a cosine wave
    %   sig = GETCOSSIG(len, freq, mag, phs, fs) returns cosine wave of
    %   frequency freq, magnitude mag (in dBFS), with specified initial
    %   phase and at a specifed sampling frequency fs. Arguments freq and
    %   mag can either be scalars or vectors of length len, mapping the
    %   value at each index to the frequency or magnitude at the
    %   corresponding sample of the generated signal.
    %
    %   sig = GETCOSSIG(len, freq, mag, phs) uses global fs.
    %
    %   sig = GETCOSSIG(len, freq, mag) uses default values: phase = 0
    %   and global fs.
    %
    %   sig = GETCOSSIG(len, freq) uses default values: mag = 0, phase = 0
    %   and global fs.
    
    global fsGlobal
    
    if nargin < 5
        fs = fsGlobal;
    end

    if nargin < 4
        phs = 0;
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
        if isnan(freq(n))
            sig(n) = 0;
        else
            sig(n) = 10^(mag(n) / 20) * cos(phs);
            phs = getNextPhase(phs, freq(n), fs);
        end
    end
end