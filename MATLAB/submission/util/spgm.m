function spgm(sig, frmLen, hopLen, fs)
    %SPGM Plot a spectrogram using MATLAB's spectrogram function

    global fsGlobal;
    
    if nargin < 4
        fs = fsGlobal;
    end
    
    if nargin < 2
        frmLen = 2048;
    end

    if nargin < 3
        hopLen = round(0.25 * frmLen);
    end

    overlap = frmLen - hopLen;
        
    spectrogram(sig, hann(frmLen), overlap, frmLen, fs, 'yaxis');
end