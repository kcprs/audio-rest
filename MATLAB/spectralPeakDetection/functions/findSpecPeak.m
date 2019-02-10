function freq = findSpecPeak(sig, nfft, fs)
    %FINDSPECPEAK Estimate frequency of highest peak in signal spectrum
    %   freq = FINDSPECPEAK(sig, nfft, fs) returns frequency estimate of
    %   the most prominent spectral peak of the given signal sig, sampled at
    %   frequency fs. Magnitude spectrum is computed using fft of size nfft.
    %   Uses parabolic interpolation to increase accuracy.
    %
    %   freq = FINDSPECPEAK(sig) uses default values of fs = 44100 and
    %   nfft = max(length(sig), 8192)

    if nargin == 1
        fs = 44100;
        nfft = max(length(sig), 8192);
    end

    % Compute magnitude spectrum of the given signal
    sig = [sig; zeros(nfft - length(sig), 1)];
    mag = abs(fft(sig .* gausswin(nfft) .* kaiser(nfft)));

    % Find peak frequency bin
    [~, peakBin] = max(mag(1:ceil(nfft / 2)));

    % Apply parabolic interpolation
    % X. Serra, `A system for sound analysis/transformation/synthesis based
    % on a deterministic plus stochastic decomposition', PhD thesis,
    % Stanford University, 1989.
    a = 20 * log10(mag(peakBin - 1));
    c = 20 * log10(mag(peakBin + 1));
    b = 20 * log10(mag(peakBin));
    p = 0.5 * (a - c) / (a - 2 * b + c);
    freq = fs * (peakBin + p) / nfft;

    % %% Plotting
    % % Plot the fragment of the spectrum that contains the peak
    % xAxis = max(1, peakBin - 10):(peakBin + 10);
    % plot(xAxis, 20 * log10(mag(xAxis)), '.');
    % hold on;

    % % Plot the parabola used for interpolation
    % x = [peakBin - 1; peakBin; peakBin + 1];
    % y = [a; b; c];
    % cfs = polyfit(x, y, 2);
    % stp = 0.01;
    % xVec = ((peakBin - 1):stp:(peakBin + 1))';
    % yVec = cfs(1) * xVec.^2 + cfs(2) * xVec + cfs(3);
    % plot(xVec, yVec);

    % % Find and plot maximum of the parabola (for plotting purposes only)
    % [parMaxY, indx] = max(yVec);
    % plot(peakBin - 1 + stp * (indx - 1), parMaxY, 'x');

    % % Mark the frequency estimated by the algorithm with a vertical line
    % plot([peakBin + p, peakBin + p], [0, parMaxY + 10]);
    % hold off;
end
