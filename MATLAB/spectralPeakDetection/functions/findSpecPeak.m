function [freq, amp] = findSpecPeak(sig, nfft, fs)
    %FINDSPECPEAK Estimate frequency and magnitude of highest spectrum peak
    %   [freq, amp] = FINDSPECPEAK(sig, nfft, fs) returns frequency
    %   estimate freq in Hz of the most prominent spectral peak of the given
    %   signal sig, sampled at frequency fs. Amplitude estimate amp is also 
    %   returned for the corresponding sinusoid component. Magnitude
    %   spectrum is computed using fft of size nfft. Parabolic interpolation
    %   is used to increase accuracy.
    %
    %   [freq, amp] = FINDSPECPEAK(sig, nfft) uses default value
    %   of fs = 44100.
    %
    %   [freq, amp] = FINDSPECPEAK(sig) uses default values
    %   of fs = 44100 and nfft = length(sig).

    if nargin < 3
        fs = 44100;
    end
    
    nsig = length(sig);

    if nargin < 2
        nfft = nsig;
    end

    % Get magnitude spectrum in dBFS
    mags = fftMag(sig, nfft, 'gausswin');

    % Find peak frequency bin
    [peakBinMag, peakBin] = max(mags(1:ceil(nfft / 2)));

    if peakBin ~= 1
        % Apply parabolic interpolation
        % X. Serra, `A system for sound analysis/transformation/synthesis
        % based on a deterministic plus stochastic decomposition',
        % PhD thesis, Stanford University, 1989.
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
        mag = peakBinMag; 
    end

    % Get sine wave amplitude in linear scale
    amp = 10^(mag / 20);

    % %% Plotting
    % % Plot the fragment of the spectrum that contains the peak
    % xAxis = max(1, peakBin - 10):(peakBin + 10);
    % plot(xAxis, mags(xAxis), '.');
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
    % plot([peakBin + p, peakBin + p], [parMaxY - 10, parMaxY + 10]);
    % hold off;
end
