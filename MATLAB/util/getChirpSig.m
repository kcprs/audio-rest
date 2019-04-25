function chirpSig = getChirpSig(f0, f1, len, fs)
    %GETCHIRPSIG Generate a linear cosine sweep
    %   chirpSig = GETCHIRPSIG(f0, f1, len) returns a cosine sweep starting
    %   at frequency f0 and linearly changing to f1 over len samples.
    %   Global sampling rate is used.
    % 
    %   chirpSig = GETCHIRPSIG(f0, f1, len, fs) returns a cosine sweep with
    %   a given sample rate fs.

    global fsGlobal
    
    if nargin == 3
        fs = fsGlobal;
    end

    t = linspace(0, len / fs, len)';
    chirpSig = chirp(t, f0, len / fs, f1);
end
