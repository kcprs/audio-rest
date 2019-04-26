function nextPhase = getNextPhase(curPhase, freq, fs)
    %GETNEXTPHASE Compute phase of next sample in sinusoidal signal
    %   nextPhase = GETNEXTPHASE(curPhase, freq, fs) returns the phase of
    %   next samplein a sinusoidal signal based on the current
    %   phase curPhase, sine frequency freq and sampling frequency fs.

    nextPhase = mod(curPhase + 2 * pi * freq / fs, 2 * pi);
end