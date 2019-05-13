sigLen = 2048;
nfft = 20480;
fs = 44100;

win = hann(sigLen);
BM_smp = 2 * 2 * nfft / sigLen;

f1_smp = round(1000 * nfft / fs) - BM_smp / 2;
f2_smp = f1_smp + BM_smp;

f1Plot = fs * f1_smp / nfft;
f2Plot = fs * f2_smp / nfft;

% winSpec = real(fft(win, nfft));

winSpecDB = 20 * log10(abs(fft(win, nfft)));
winSpecDB = fftshift(winSpecDB);
winSpec1 = circshift(winSpecDB, f1_smp);
winSpec2 = circshift(winSpecDB, f2_smp);

f = linspace(-fs / 2, fs / 2, nfft);

fig1 = figure(1);
plot(f, winSpecDB);
hold on;
hold off;
ylim([-40, 80]);
xlim([-120, 120]);
ylabel('Magnitude (dB)');
xlabel('Frequency (Hz)');
annotation('doublearrow', [0.385, 0.658], [0.4, 0.4]);
text(-20, 10, 'B_{M} = Kb_{M}', 'FontSize', 14);
annotation('doublearrow', [0.66, 0.728], [0.3, 0.3]);
text(50, -20, 'b_{M}', 'FontSize', 14);
grid on;

fig2 = figure(2);
plot(f, winSpec1);
hold on;
plot(f, winSpec2);
yl = ylim;
plot([f1Plot, f1Plot], [-100, 100], '--', 'Color', 'Black');
plot([f2Plot, f2Plot], [-100, 100], '--', 'Color', 'Black');
hold off;
grid on;
xlim([850, 1150]);
ylim([-40, 80]);
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
annotation('doublearrow', [0.405, 0.625], [0.88, 0.88]);
text(978, 65, '\Deltaf = B_{M}', 'FontSize', 14);

% resizeFigure(fig1, 1, 1);
% filename = 'hann_main_lobe';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);

% resizeFigure(fig2, 1, 1);
% filename = 'min_separation';
% saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\other\\', filename, '.png']);
