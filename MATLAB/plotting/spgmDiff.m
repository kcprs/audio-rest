fs = 44100;
frmLen = 2048;
hopLen = 256;
overlap = frmLen - hopLen;
specType = 'power';
% specType = 'psd';
ylimkHz = [0, 20];

% sig = audioread("audio/fluteOrigTrim.wav");
% sigRest = audioread("audio/fluteWithResTrim.wav");
sig = getCosSig(fs, 200 * fs / frmLen);
sigRest = getSineSig(fs, 200 * fs / frmLen);

% plot the first spectrogram
subplot(2, 2, 1);
spectrogram(sig, hann(frmLen), overlap, frmLen, fs, 'yaxis', specType);
title('Original signal');
ylim(ylimkHz);

% plot the second spectrogram
subplot(2, 2, 3);
spectrogram(sigRest, hann(frmLen), overlap, frmLen, fs, 'yaxis', specType);
title('Restoration');
ylim(ylimkHz);

% plot their difference
subplot(2, 2, 2);
[~, ~, ~, pSig] = spectrogram(sig, hann(frmLen), overlap, frmLen, fs, specType);
[~, f, t, pSigRest] = spectrogram(sigRest, hann(frmLen), overlap, frmLen, fs, specType);

pDiff = diffSpectrogram(t, f, pSig, pSigRest, false, 'yaxis', specType, -Inf);
title('Power Difference (original - restoration)');
ylim(ylimkHz);

subplot(2, 2, 4);

if strcmp(specType, 'power')
    pDiffErr = sum(abs(pDiff), 1);
else
    winFreqSpan = fs / frmLen;
    pDiffErr = sum(abs(pDiff), 1) * winFreqSpan;
end

tms = t * 1000;
plot(tms, pDiffErr);
title('Total power error over all frequencies');
xlabel("Time (ms)");
ylabel("Power (dB)");
grid;

function pDiff = diffSpectrogram(t, f, p1, p2, isFsnormalized, faxisloc, esttype, threshold)

    if strcmpi(esttype, 'power')
        plotOpts.cblbl = getString(message('signal:dspdata:dspdata:PowerdB'));
    else

        if isFsnormalized
            plotOpts.cblbl = getString(message('signal:dspdata:dspdata:PowerfrequencydBradsample'));
        else
            plotOpts.cblbl = getString(message('signal:dspdata:dspdata:PowerfrequencydBHz'));
        end

    end

    %Threshold in dB
    plotOpts.freqlocation = faxisloc;
    plotOpts.threshold = 10 * log10(threshold + eps);
    plotOpts.isFsnormalized = logical(isFsnormalized);

    %Power in dB
    pDiff = 10 * (log10(abs(p1) + eps) - log10(abs(p2) + eps));
    signalwavelet.internal.convenienceplot.plotTFR(t, f, pDiff, plotOpts);

    minLim = min(pDiff, [], 'all');
    maxLim = max(pDiff, [], 'all');
    absLim = max(abs(minLim), abs(maxLim));
    caxis(gca, [-absLim, absLim]);

    lowCl = [0, 0, 1];
    midCl = [1, 1, 1];
    hiCl = [1, 0, 0];

    mapr = [linspace(lowCl(1), midCl(1), 50).'; linspace(midCl(1), hiCl(1), 50).'];
    mapg = [linspace(lowCl(2), midCl(2), 50).'; linspace(midCl(2), hiCl(2), 50).'];
    mapb = [linspace(lowCl(3), midCl(3), 50).'; linspace(midCl(3), hiCl(3), 50).'];
    map = [mapr, mapg, mapb];
    set(gca, 'colormap', map);
end
