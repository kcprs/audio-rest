function sweepSig = getSweepSig(len, f0, f1, fs)
    %GETSWEEPSIG Generate a linear cosine sweep
    %   sweepSig = getSweepSig(len, f0, f1) returns a cosine sweep starting
    %   at frequency f0 and linearly changing to f1 over len samples.
    %   Global sampling rate is used.
    % 
    %   sweepSig = getSweepSig(len, f0, f1, fs) returns a cosine sweep with
    %   a given sample rate fs.

    global fsGlobal
    
    if nargin == 3
        fs = fsGlobal;
    end

    t = linspace(0, len / fs, len)';
    sweepSig = chirp(t, f0, len / fs, f1);
end
