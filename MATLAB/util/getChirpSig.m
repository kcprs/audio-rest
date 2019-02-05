function chirpSig = getChirpSig(f0, f1, len, fs)
    %GETCHIRPSIG Create a linear cosine sweep
    %   chirpSig = GETCHIRPSIG(f0, f1, len) returns a cosine sweep starting
    %   at frequency f0 and linearly changing to f1 over len samples.
    %   Default sampling rate is 44100 Hz.
    % 
    %   chirpSig = GETCHIRPSIG(f0, f1, len, fs) returns a cosine sweep with
    %   a given sample rate fs.

    if nargin == 3
        fs = 44100;
    end

    t = linspace(0, len / fs, len)';
    chirpSig = chirp(t, f0, len / fs, f1);
end
