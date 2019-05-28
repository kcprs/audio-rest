fs = 44100;
frmLen = 2048;
sigStart = 10000;

sig = audioread("audio/Trumpet.nonvib.A4.wav");
sig = sig(sigStart:sigStart + frmLen - 1);

[spec, ~] = getFT(sig);
[freqEst, magEst, ~] = findSpecPeaks(sig, -Inf, 0);


f = linspace(0, fs, length(spec));
plot(f, spec);
hold on;
plot(freqEst, magEst, 'x');
hold off;
ylabel("Magnitude (dBFS)");
xlabel("Frequency (Hz)");
grid on;
xlim([0, 10000]);

% resizeFigure(gcf, 2, 0.7);
% filename = 'peakDetect';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
