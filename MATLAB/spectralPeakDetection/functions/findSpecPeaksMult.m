function specPeaks = findSpecPeaksMult(sig, trshld, nfft, npks, fs)
    %FINDSPECPEAKSMULT Find multiple spectral peaks in the given signal
    %   specPeaks = FINDSPECPEAKSMULT(sig, trshld, nfft, npks, fs) returns
    %   a matrix containing information about npks most prominent frequency
    %   components of the given signal sig, that is all spectral peaks with 
    %   magnitude above the threshold trshld in dB. The returned matrix is
    %   empty if no peaks are found. Otherwise, the matrix is of size N x 3,
    %   where N is the number of peaks found. Matrix columns correspond to
    %   frequency, magnitude and amplitude estimates, respectively. Analysis
    %   is done using fft of size nfft.
    %
    %   specPeaks = FINDSPECPEAKSMULT(sig, trshld, nfft, npks) uses default
    %   value of fs = 44100.
    % 
    %   specPeaks = FINDSPECPEAKSMULT(sig, trshld, nfft) uses default values
    %   of fs = 44100 and npeaks = 20.
    %
    %   specPeaks = FINDSPECPEAKSMULT(sig, trshld) uses default values
    %   of fs = 44100, npeaks = 20 and nfft = length(sig).

    if nargin < 5
        fs = 44100;
    end

    if nargin < 4
        npks = 20;
    end

    nsig = length(sig);

    if nargin < 3
        nfft = nsig;
    end

    % Apply windowing to the given signal, as described by X. Serra (below)
    win = gausswin(nsig) .* kaiser(nsig);
    sig = sig .* win;

    % Add padding or remove samples to get fft of requested size
    if nsig < nfft
        sig = [sig; zeros(nfft - nsig, 1)];
    else
        sig = sig(1:nfft);
    end

    % Compute magnitude spectrum of the given signal
    mags = 20 * log10(abs(fft(sig)));

    % Find peaks in magnitude spectrum
    [~, peakBins] = findpeaks(mags(1:ceil(nfft / 2)), 'MinPeakHeight', ...
        trshld, 'NPeaks', npks);

    % Find frequency and amplitude estimates for each peak
    specPeaks = zeros(length(peakBins), 3);

    for iter = 1:length(peakBins)
        peakBin = peakBins(iter);

        if peakBin ~= 1
            % Apply parabolic interpolation
            % X. Serra, `A system for sound analysis/transformation/synthesis based
            % on a deterministic plus stochastic decomposition', PhD thesis,
            % Stanford University, 1989.
            a = mags(peakBin - 1);
            c = mags(peakBin + 1);
            b = mags(peakBin);
            p = 0.5 * (a - c) / (a - 2 * b + c);

            % Get peak frequency estimate.
            % Accommodate for the fact that MATLAB's indexing starts from 1.
            freq = fs * (peakBin - 1 + p) / nfft;

            % Get peak magnitude estimate.
            mag = (b - 0.25 * (a - c) * p);
        else
            % Skip interpolation if fft resolution is insufficient or the signal
            % is too short, causing the highest peak to be at DC bin.
            freq = 0;
            mag = 20 * log10(peakBinMag);
        end

        % Get sine wave amplitude based on peak fft magnitude.
        winMag = abs(fft(win));
        amp = 2 * 10^(mag / 20) / winMag(1);

        specPeaks(iter, :) = [freq, mag, amp];
    end

end
