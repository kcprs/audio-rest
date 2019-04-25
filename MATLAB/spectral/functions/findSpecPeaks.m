function [freqEst, magEst, phsEst] = findSpecPeaks(sig, trs, npks, fs)
    %FINDSPECPEAKS Find multiple spectral peaks in the given signal
    %   [freqEst, magEst, phsEst] = FINDSPECPEAKS(sig, trs, npks, fs)
    %   returns frequency, magnitude and phase information about npks most
    %   prominent frequency components of the given signal sig, i.e. all
    %   spectral peaks with magnitude above the threshold trs in dBFS.
    %   Set npks to 0 to find all peaks above threshold trs.
    %
    %   [freqEst, magEst, phsEst] = FINDSPECPEAKS(sig, trs, npks) uses
    %   default value of fs = 44100.

    if nargin < 4
        fs = 44100;
    end

    % Get magnitude and phase spectra
    [mag, phs, nfft] = getFT(sig);

    % Find highest peaks in magnitude spectrum
    if npks == 0
        [peakMag, peakLoc] = findpeaks(mag(1:(floor(nfft / 2) + 1)), ...
            'SortStr', 'descend', 'MinPeakHeight', trs, 'MinPeakWidth', 3);
    else
        [peakMag, peakLoc] = findpeaks(mag(1:(floor(nfft / 2) + 1)), ...
            'SortStr', 'descend', 'MinPeakHeight', trs, 'NPeaks', npks, ...
            'MinPeakWidth', 3);
    end

    % Interpolation method based on:
    % DAFX - Digital Audio Effects (2002), Chapter 10 - Spectral Processing
    % X. Amatriain, J. Bonada, A. Loscos, X. Serra

    % Calculate interpolated peak positions in bins (intpLoc)
    leftMag = mag((peakLoc - 1) .* ((peakLoc - 1) > 0) + ...
        ((peakLoc - 1) <= 0) .* 1);
    rightMag = mag((peakLoc + 1) .* ((peakLoc + 1) < nfft / 2) + ...
        ((peakLoc + 1) >= nfft / 2) .* (nfft / 2));
    intpLoc = peakLoc + 0.5 * (leftMag - rightMag) ./ (leftMag ...
        -2 * peakMag + rightMag);
    intpLoc = (intpLoc >= 1) .* intpLoc + (intpLoc < 1) .* 1;
    intpLoc = (intpLoc > nfft / 2 + 1) .* (nfft / 2 + 1) + ...
        (intpLoc <= nfft / 2 + 1) .* intpLoc;

    % Calculate corresponding frequencies
    freqEst = fs * (intpLoc - 1) / nfft;

    % Calculate interpolated phase (phsEst)
    leftPhs = phs(floor(intpLoc));
    rightPhs = phs(floor(intpLoc + 1));
    intpFactor = intpLoc - peakLoc;
    intpFactor = (intpFactor > 0) .* intpFactor + (intpFactor < 0) ...
        .* (1 + intpFactor);
    diffPhs = unwrap2pi(rightPhs - leftPhs);
    phsEst = leftPhs + intpFactor .* diffPhs;

    % Calculate interpolated magnitude (magEst)
    magEst = peakMag - 0.25 * (leftMag - rightMag) .* (intpLoc - peakLoc);

    % If fewer peaks detected than npks, pad with NaN to match expected size
    freqEst = [freqEst, NaN(1, npks - length(freqEst))];
    magEst = [magEst, NaN(1, npks - length(magEst))];
    phsEst = [phsEst, NaN(1, npks - length(phsEst))];
end

function argUnwrap = unwrap2pi(arg)
    %ARGUNWRAP Helper function for unwrapping phase spectra
    arg = arg - floor(arg / 2 / pi) * 2 * pi;
    argUnwrap = arg - arg >= pi * 2 * pi;
end
