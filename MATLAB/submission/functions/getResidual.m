function residual = getResidual(sig, freq, mag, phs)
    %GETRESIDUAL Subtract sinusoidal portion from a signal
    %   residual = getResidual(sig, freq, mag, phs, frmLen) returns residual
    %   signal derived from the signal sig and spectral peak information
    %   given as a vector of frequency locations (freq), magnitudes (mags)
    %   and phases (phs) of peaks.

    % TODO: Take spectrum changes into account
    
    % Signal sig spans a single frame
    frmLen = length(sig);
    
    % Resynthesise the sinusoidal of the given frame.
    % Build the signal from the middle outwards since phase is known for
    % the middle of the frame
    sinSigFwd = resynth([freq; freq], [mag; mag], phs, frmLen / 2);
    sinSigBwd = resynth([freq; freq], [mag; mag], -phs, frmLen / 2 - 1);
    sinSig = [flipud(sinSigBwd); sinSigFwd(2:end)];

    % Subtract in frequency domain to avoid phase issues
    sinSigMag = abs(fft(sinSig, length(sig)));
    sigFT = fft(sig);
    sigMag = abs(sigFT);
    sigPhs = angle(sigFT);

    resMag = sigMag - sinSigMag;
    residual = real(ifft(resMag .* exp(1j * sigPhs)));
end
