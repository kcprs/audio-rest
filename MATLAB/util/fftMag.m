function magSpec = fftMag(sig, nfft, winType)

    if nargin < 3
        winType = 'hann';
    end

    sigLen = length(sig);

    % Prepare window
    winLen = min(sigLen, nfft);

    if strcmp(winType, 'gausswin')
        win = gausswin(winLen) .* kaiser(winLen);
    else
        win = hann(winLen);
    end

    % Add padding or remove samples to get fft of requested size.
    % Window the signal.
    if sigLen < nfft
        sigWin = [sig .* win; zeros(nfft - sigLen, 1)];
    else
        sigWin = sig(1:nfft) .* win;
    end

    % Compute magnitude spectrum of the given signal. Normalise so that
    % magnitudes are independent of nfft and equal to amplitudes of
    % corresponding sinusoidal components in dBFS.
    winMag = abs(fft(win));
    magSpec = 20 * log10(2 * abs(fft(sigWin)) / winMag(1));
end
