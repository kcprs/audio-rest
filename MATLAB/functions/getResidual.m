function residual = getResidual(sig, trs, npks, smth)
    %GETRESIDUAL Subtract sinusoidal portion from a signal
    %   residual = getResidual(sig, trs, npks, smth)
    %   returns residual signal derived from the signal sig by finding npks
    %   spectral peaks above threshold trs and removing them. Set smth to
    %   true to smooth the residual spectrum.

    if nargin < 4
        smth = false;
    end

    % Signal sig spans a single frame
    frmLen = length(sig);

    % Find spectral peaks to remove
    [freq, mag, phs] = findSpecPeaks(sig, trs, npks);

    % Resynthesise the sinusoidal of the given frame.
    % Build the signal from the middle outwards since phase is known for
    % the middle of the frame
    sinSigFwd = resynth([freq; freq], [mag; mag], phs, frmLen / 2);
    sinSigBwd = resynth([freq; freq], [mag; mag], -phs, frmLen / 2 - 1);
    sinSig = [flipud(sinSigBwd); sinSigFwd(2:end)];

    % Subtract in frequency domain to avoid phase issues
    sinSigMag = abs(fft(sinSig .* hann(frmLen), frmLen));
    sigFT = fft(sig .* hann(frmLen));
    sigMag = abs(sigFT);
    sigPhs = angle(sigFT);
    resMag = sigMag - sinSigMag;

    % Apply smoothing
    if smth
        resMag = 20 * log10(abs(resMag));
        resMag = smoothdata(resMag, 'movmedian', 100);
        resMag = 10.^(resMag / 20);
    end

    % Scale to compensate for window spectrum height
    winMag = abs(fft(hann(frmLen)));
    resMag = resMag * frmLen / max(winMag);

    % Go back to time domain, use original phase
    residual = real(ifft(resMag .* exp(1j * sigPhs)));
end
