function psdDiff = spgmDiff(t, f, psd1, psd2)
        %SPGMDIFF Plot difference between two spectrograms
        %   psdDiff = spgmDiff(t, f, psd1, psd2) returns the difference between
        %   power spectral densities psd1 and psd2. Plots the spectrogram of the
        %   PSD difference. Arguments t and f are respectively time and
        %   frequency vectors used for the axes of the spectrogram.
    %
    %   Code adapted from MATLAB'S pspectrogram.m file (lines 152 - 171)

    plotOpts.freqlocation = 'yaxis';
    plotOpts.isFsNorm = false;

    psdDiff = 10 * (log10(abs(psd1) + eps) - log10(abs(psd2) + eps));

    % Convert to MATLAB's convention of time-frequency matrices
    psdDiff = psdDiff.';

    signalwavelet.internal.convenienceplot.plotTFR(t, f, psdDiff, plotOpts);

    minLim = min(psdDiff, [], 'all');
    maxLim = max(psdDiff, [], 'all');
    absLim = max(abs(minLim), abs(maxLim));
    caxis(gca, [-absLim, absLim]);

    lowCl = [0, 0, 1];
    midCl = [1, 1, 1];
    hiCl = [1, 0, 0];

    mapr = [linspace(lowCl(1), midCl(1), 50).'; ...
            linspace(midCl(1), hiCl(1), 50).'];
    mapg = [linspace(lowCl(2), midCl(2), 50).'; ...
            linspace(midCl(2), hiCl(2), 50).'];
    mapb = [linspace(lowCl(3), midCl(3), 50).'; ...
            linspace(midCl(3), hiCl(3), 50).'];
    map = [mapr, mapg, mapb];

    set(gca, 'colormap', map);

    hcb = colorbar;
    hcb.Label.String = "PSD Difference (dB/Hz)";

end
