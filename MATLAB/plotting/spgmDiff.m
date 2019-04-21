fs = 44100;
frmLen = 2048;
hopLen = 256;
overlap = frmLen - hopLen;
ylimkHz = [0, 20];

% sig = audioread("audio/fluteOrigTrim.wav");
% sigRest = audioread("audio/fluteWithResTrim.wav");
sig = getCosSig(fs, 100 * fs / frmLen);
sigRest = getCosSig(fs, 100 * fs / frmLen, 0, pi);
% sig = randn([fs, 1]);
% sigRest = randn([fs, 1]);

% plot the first spectrogram
subplot(2, 2, 1);
spectrogram(sig, hann(frmLen), overlap, frmLen, fs, 'yaxis');
title('Original signal');
ylim(ylimkHz);

% plot the second spectrogram
subplot(2, 2, 3);
spectrogram(sigRest, hann(frmLen), overlap, frmLen, fs, 'yaxis');
title('Restoration');
ylim(ylimkHz);

% plot their difference
subplot(2, 2, 2);
[~, ~, ~, pSig] = spectrogram(sig, hann(frmLen), overlap, frmLen, fs);
[~, f, t, pSigRest] = spectrogram(sigRest, hann(frmLen), overlap, frmLen, fs);

pDiff = diffSpectrogram(t, f, pSigRest, pSig, false, 'yaxis', 'psd', -Inf);
title('PSD Difference (restoration - original)');
ylim(ylimkHz);
xlimSpgm = xlim;

subplot(2, 2, 4);
pDiffMean = mean(pDiff, 1);

tms = t * 1000;
plot(tms, pDiffMean);
title('Average PSD error per FFT bin');
xlabel("Time (ms)");
ylabel("Power/frequency (dB/Hz)");
xlim(xlimSpgm);
grid;

%% Compare with code below to check if pDiffMean is calculated correctly
% subplot(2, 2, 3);
% powf = 10 * log10(sum(abs(pSig), 1) * fs / frmLen);

% plot(tms, powf);
% title('Power calc in freq domain');
% xlabel("Time (ms)");
% ylabel("Power (dB)");
% grid;

% subplot(2, 2, 1);
% powt = zeros(length(t), 1);
% frmCurs = 1;
% powCurs = 1;

% while frmCurs + frmLen < length(sig)
%     powt(powCurs) = 10 * log10(sum(sig(frmCurs:frmCurs + frmLen).^2) / frmLen);
%     frmCurs = frmCurs + hopLen;
%     powCurs = powCurs + 1;
% end

% plot(tms, powt);
% title('Power calc in time domain');
% xlabel("Time (ms)");
% ylabel("Power (dB)");
% grid;

% Code below adapted from MATLAB'S pspectrogram.m file (lines 152 - 171)
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
