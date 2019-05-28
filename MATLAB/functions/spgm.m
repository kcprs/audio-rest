function [t, f, psd] = spgm(sig, showFig, frmLen, hopLen, fs)
    %SPGM Plot a spectrogram using MATLAB's spectrogram function
    %   [t, f, psd] = spgm(sig, showFig, frmLen, hopLen, fs) returns time 
    %   vector t, frequency vector f and power spectral density matrix psd
    %   of the given signal sig. 
    %   Additional settings;
    %   showFig - Set to true to show spectrogram plot (true by default)
    %   frmLen - analysis frame length in samples (2048 by default)
    %   hopLen - analysis hop length in samples (256 by default)
    %   fs - sampling frequency of sig  (uses fsGlobal by default)

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

    % Transpose to stay consistent with convention:
    % time on vertical axis, frequency on horizontal axis
    psd = psd.';
end
