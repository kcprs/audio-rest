function freqMtch = matchEndPhase(freq, initPhs, endPhs)
    %MATCHENDPHASE Modify frequency trajectory to finish at given phase
    %   freqMtch = matchEndPhase(freq, initPhs, endPhs) modifies given
    %   frequency trajectory vector freq (containing sample-by-sample
    %   frequency values) so that if resynthesis starts with initial phase
    %   initPhs, the phase of the last sample will be endPhs.

    global fsGlobal
    fs = fsGlobal;
    w = 2 * pi * freq / fs;
    curEndPhs = initPhs + sum(w);

    phsDiff = mod(endPhs - curEndPhs, 2 * pi);

    if phsDiff > pi
        phsDiff = phsDiff - 2 * pi;
    end

    fCorr = fs * phsDiff / (length(freq) * 2 * pi);

    freqMtch = freq + fCorr;
end
