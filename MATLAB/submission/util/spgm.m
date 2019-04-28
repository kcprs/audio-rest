function [t, f, psd] = spgm(sig, showFig, frmLen, hopLen, fs)
    %SPGM Plot a spectrogram using MATLAB's spectrogram function

    global fsGlobal;

    if nargin < 5
        fs = fsGlobal;
    end

    if nargin < 3
        frmLen = 2048;
    end
    
    if nargin < 4
        hopLen = round(frmLen / 8);
    end
    
    if nargin < 2
        showFig = true;
    end

    overlap = frmLen - hopLen;

    % Plot if requested
    if showFig
        spectrogram(sig, hann(frmLen), overlap, frmLen, fs, 'yaxis');
    end

    [~, f, t, psd] = spectrogram(sig, hann(frmLen), overlap, frmLen, fs);
end
