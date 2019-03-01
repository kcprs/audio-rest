function [freqEst, ampEst, phsEst] = findSpecPeaks(sig, trs, nfft, npks, fs)
    %FINDSPECPEAKS Find multiple spectral peaks in the given signal
    %   [freqEst, ampEst, phsEst] = FINDSPECPEAKS(sig, trs, nfft, npks, fs)
    %   returns frequency, amplitude and phase information about npks most
    %   prominent frequency components of the given signal sig, i.e. all
    %   spectral peaks with magnitude above the threshold trs in dBFS.
    %   Analysis is done using fft of size nfft.
    %
    %   [freqEst, ampEst, phsEst] = FINDSPECPEAKS(sig, trs, nfft, npks)
    %   uses default value of fs = 44100.
    % 
    %   [freqEst, ampEst, phsEst] = FINDSPECPEAKS(sig, trs, nfft) uses
    %   default values of fs = 44100 and npeaks = 20.
    %
    %   [freqEst, ampEst, phsEst] = FINDSPECPEAKS(sig, trs) uses default
    %   values of fs = 44100, npeaks = 20 and nfft = length(sig).

    if nargin < 5
        fs = 44100;
    end

    if nargin < 4
        npks = 20;
    end

    if nargin < 3
        nfft = length(sig);
    end

    % Get magnitude and phase spectra
    [mag, phs] = getFT(sig, nfft, 'gausswin');

    % Find peaks in magnitude spectrum
    [peakMag, peakLoc] = findpeaks(mag(1:(nfft / 2 + 1)), ...
        'MinPeakHeight', trs, 'NPeaks', npks);

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

    % Calculate interpolated phase (intPhs)
    leftPhs = phs(floor(intpLoc));
    rightPhs = phs(floor(intpLoc + 1));
    intpFactor = intpLoc - peakLoc;
    intpFactor = (intpFactor > 0) .* intpFactor + (intpFactor < 0) ...
        .* (1 + intpFactor);
    diffPhs = unwrap2pi(rightPhs - leftPhs);
    phsEst = leftPhs + intpFactor .* diffPhs;

    % Calculate interpolated amplitude (ampEst)
    intpAdB = peakMag - 0.25 * (leftMag - rightMag) .* (intpLoc - peakLoc);
    ampEst = 10.^(intpAdB / 20);
end

function argUnwrap = unwrap2pi(arg)
    %ARGUNWRAP Heler function for unwrapping phase spectra
    arg = arg - floor(arg / 2 / pi) * 2 * pi;
    argUnwrap = arg - arg >= pi * 2 * pi;
end
