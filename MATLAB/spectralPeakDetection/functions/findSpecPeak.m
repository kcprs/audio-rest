function freq = findSpecPeak(sig, nfft, fs)
    %FINDSPECPEAK Estimate frequency of highest peak in signal spectrum
    %   freq = FINDSPECPEAK(sig, nfft, fs) returns frequency estimate of
    %   the most prominent spectral peak of the given signal sig, sampled at
    %   frequency fs. Magnitude spectrum is computed using fft of size nfft.
    %   Uses parabolic interpolation to increase accuracy.
    %
    %   freq = FINDSPECPEAK(sig, nfft) uses default value of fs = 44100.
    % 
    %   freq = FINDSPECPEAK(sig) uses default values of fs = 44100 and
    %   nfft = length(sig).

    if nargin < 3
        fs = 44100;
    end

    if nargin < 2
        nfft = length(sig);
    end
    
    % Apply windowing to the given signal, as described by X. Serra (below)
    sig = sig .* gausswin(length(sig)) .* kaiser(length(sig));

    % Add padding or remove samples to get fft of requested size
    if length(sig) < nfft
        sig = [sig; zeros(nfft - length(sig), 1)];
    else
        sig = sig(1:nfft);
    end

    % Compute magnitude spectrum of the given signal
    mag = abs(fft(sig));

    % Find peak frequency bin
    [~, peakBin] = max(mag(1:ceil(nfft / 2)));

    % Skip interpolation if fft resolution is insufficient or the signal
    % is too short, causing the highest peak to be at DC bin.
    if peakBin == 1
        freq = 0;
        return
    end

    % Apply parabolic interpolation
    % X. Serra, `A system for sound analysis/transformation/synthesis based
    % on a deterministic plus stochastic decomposition', PhD thesis,
    % Stanford University, 1989.
    a = 20 * log10(mag(peakBin - 1));
    c = 20 * log10(mag(peakBin + 1));
    b = 20 * log10(mag(peakBin));
    p = 0.5 * (a - c) / (a - 2 * b + c);

    % Get frequency estimate.
    % Accommodate for the fact that MATLAB's indexing starts from 1.
    freq = fs * (peakBin - 1 + p) / nfft;

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
