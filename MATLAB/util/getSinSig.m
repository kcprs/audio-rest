function sig = getSinSig(len, freq, mag, initPhs, fs)
    %GETSINSIG Generate a sinewave
    %   sig = GETSINSIG(len, freq, mag, initPhs, fs) returns sine wave of
    %   frequency freq, magnitude mag (in dBFS), with specified initial
    %   phase and at a specifed sampling frequency fs. Arguments freq and
    %   mag can either be scalars or vectors of length len, mapping the
    %   value at each index to the frequency or magnitude at the
    %   corresponding sample of the generated signal.
    %
    %   sig = GETSINSIG(len, freq, mag, initPhs) uses global fs value.
    %
    %   sig = GETSINSIG(len, freq, mag) uses default values: phase = 0
    %   and global fs value.
    %
    %   sig = GETSINSIG(len, freq) uses default values: mag = 0, phase = 0
    %   and global fs value.

    global fsGlobal
    
    if nargin < 5
        fs = fsGlobal;
    end

    if nargin < 4
        initPhs = 0;
    end

    if nargin < 3
        mag = 0;
    end

    initPhs = initPhs - 0.5 * pi;

    sig = getCosSig(len, freq, mag, initPhs, fs);

end
