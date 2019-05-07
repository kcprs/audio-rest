function residual = getResidual(sig, trs, npks, smth)
    %GETRESIDUAL Subtract sinusoidal portion from a signal
    %   residual = getResidual(sig, trs, npks, smth) returns residual
    %   signal derived from the signal sig by finding npks spectral peaks
    %   above threshold trs and removing them. Set smth to true to smooth
    %   the residual spectrum. Default value for smth is false.

    if nargin < 4
        smth = false;
    end

    tukeyFactor = 0.01;

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
    sinSigMag = abs(fft(sinSig .* tukeywin(frmLen, tukeyFactor), frmLen));
    sigMag = abs(fft(sig .* tukeywin(frmLen, tukeyFactor)));
    resMag = sigMag - sinSigMag;

    % Apply smoothing
    if smth
        resMag = 20 * log10(abs(resMag));
        resMag = smoothdata(resMag, 'movmedian', 100);
        resMag = 10.^(resMag / 20);
    end

    % Use spectrum of original signal at high frequencies
    global fsGlobal;
    fs = fsGlobal;
    bin8k = round(frmLen * 8000 / fs);
    bin10k = round(frmLen * 10000 / fs);

    weight = [zeros(1, bin8k), linspace(0, 1, bin10k - bin8k), ...
            ones(1, frmLen / 2 - bin10k)].';
    weight = [weight; flipud(weight)];
    resMag = resMag .* (1 - weight) + sigMag .* weight;

    % Scale to compensate for window spectrum height
    winMag = abs(fft(tukeywin(frmLen, tukeyFactor)));
    resMag = resMag * frmLen / max(winMag);

    % Go back to time domain, use random phase
    residual = real(ifft(resMag .* exp(1j * 2 * pi * rand([frmLen, 1]))));
end
