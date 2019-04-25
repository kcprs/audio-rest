function [magSpec, phsSpec, nfft] = getFT(sig, nfft)
    %GETFT Compute magnitude and phase spectra of a signal
    %   [magSpec, phsSpec, nfft] = GETFT(sig, nfft) returns magnitude and
    %   phase spectra of the given signal sig using FFT of size nfft.
    %   The signal is first windowed by a Hann function specified by winType.
    %   The magnitude is returned in dBFS and corresponds to the magnitude
    %   of a sinusoid at a given bin frequency.
    %
    %   [magSpec, phsSpec, nfft] = GETFT(sig) uses function getNFFT() to
    %   determine the optimal nfft, based on precision requirements set
    %   in getNFFT.m

    sigLen = length(sig);

    if nargin < 2
        nfft = getNFFT(sigLen);
    end

    % Prepare window
    winLen = min(sigLen, nfft);
    win = hann(winLen);

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
