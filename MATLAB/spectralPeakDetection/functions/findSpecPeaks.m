function specPeaks = serraSPD(sig, trshld, nfft, npks, fs)
    %FINDSPECPEAKS Find multiple spectral peaks in the given signal
    %   specPeaks = FINDSPECPEAKS(sig, trshld, nfft, npks, fs) returns
    %   a matrix containing information about npks most prominent frequency
    %   components of the given signal sig, that is all spectral peaks with 
    %   magnitude above the threshold trshld in dBFS. The returned matrix is
    %   empty if no peaks are found. Otherwise, the matrix is of size N x 2,
    %   where N is the number of peaks found. Matrix columns correspond to
    %   frequency and amplitude estimates, respectively. Analysis is done
    %   using fft of size nfft.
    %
    %   specPeaks = FINDSPECPEAKS(sig, trshld, nfft, npks) uses default
    %   value of fs = 44100.
    % 
    %   specPeaks = FINDSPECPEAKS(sig, trshld, nfft) uses default values
    %   of fs = 44100 and npeaks = 20.
    %
    %   specPeaks = FINDSPECPEAKS(sig, trshld) uses default values
    %   of fs = 44100, npeaks = 20 and nfft = length(sig).

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
        'MinPeakHeight', trshld, 'NPeaks', npks);

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
    intpFreq = fs * (intpLoc - 1) / nfft;

    % Calculate interpolated phase (intPhs)
    leftPhs = phs(floor(intpLoc));
    rightPhs = phs(floor(intpLoc + 1));
    intpFactor = intpLoc - peakLoc;
    intpFactor = (intpFactor > 0) .* intpFactor + (intpFactor < 0) ...
        .* (1 + intpFactor);
    diffPhs = unwrap2pi(rightPhs - leftPhs);
    intpPhs = leftPhs + intpFactor .* diffPhs;

    % Calculate interpolated amplitude (intpAmp)
    intpAdB = peakMag - 0.25 * (leftMag - rightMag) .* (intpLoc - peakLoc);
    intpAmp = 10.^(intpAdB / 20);

    % Combine results into one matrix
    specPeaks = [intpFreq, intpAmp, intpPhs];
end

function argUnwrap = unwrap2pi(arg)
    %ARGUNWRAP Heler function for unwrapping phase spectra
    arg = arg - floor(arg / 2 / pi) * 2 * pi;
    argUnwrap = arg - arg >= pi * 2 * pi;
end
