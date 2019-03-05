function [magSpec, phsSpec] = getFT(sig, nfft, winType)
    %GETFT Compute magnitude and phase spectra of a signal
    %   [magSpec, phsSpec] = GETFT(sig, nfft, winType) returns magnitude and
    %   phase spectra of the given signal sig using FFT of size nfft.
    %   The signal is first windowed by a function specified by winType.
    %   The magnitude is returned in dBFS and corresponds to the magnitude
    %   of a sinusoid at given bin frequency.
    %
    %   [magSpec, phsSpec] = GETFT(sig, nfft) uses Hann windowing by default
    %
    %   [magSpec, phsSpec] = GETFT(sig) uses Hann windowing and
    %   nfft = length(sig)

    if nargin < 3
        winType = 'hann';
    end

    sigLen = length(sig);

    if nargin < 2
        nfft = sigLen;
    end

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

    % Apply circular shift to obtain phase spectrum in relation to the
    % middle of the frame.
    sigWin = circshift(sigWin, -ceil(sigLen / 2));

    % Transpose from vertical to horizontal vector - by convention vertical
    % dimension is reserved for time.
    sigFT = fft(sigWin).';
    phsSpec = angle(sigFT);

    % Compute magnitude spectrum of the given signal. Normalise so that
    % magnitudes are independent of nfft and equal to magnitudes of
    % corresponding sinusoidal components in dBFS.
    winMag = abs(fft(win));
    magSpec = 20 * log10(2 * abs(sigFT) / winMag(1));
end
