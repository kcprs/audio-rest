fs = 44100;

sigLen = 256;
winLen = 20;

rectWin = ones(sigLen, 1);
hannWin = hann(sigLen);
hammWin = hamming(sigLen);

nfft = 4 * sigLen;

rectWinSpec = 20 * log10(abs(fft(ones(winLen, 1), nfft)));
rectWinSpec = fftshift(rectWinSpec);
hannWinSpec = 20 * log10(abs(fft(hann(winLen), nfft)));
hannWinSpec = fftshift(hannWinSpec);
hammWinSpec = 20 * log10(abs(fft(hamming(winLen), nfft)));
hammWinSpec = fftshift(hammWinSpec);

t = (1:sigLen) - sigLen / 2;

fig1 = figure(1);
p1 = plot(t, rectWin, 'DisplayName', 'Rectangular');
hold on;
set(gca, 'ColorOrderIndex', 1);
plot([ - sigLen / 2 - 1,  - sigLen / 2], [0, 1], '--');
set(gca, 'ColorOrderIndex', 1);
plot([sigLen / 2 + 1, sigLen / 2], [1, 0], '--');
p2 = plot(t, hannWin, 'DisplayName', 'Hann');
set(gca, 'ColorOrderIndex', 5);
p3 = plot(t, hammWin, 'DisplayName', 'Hamming');
hold off;
ylabel('Amplitude');
xticks([]);
ylim([-0.1, 1.1]);
legend([p1, p2, p3], 'Location', 'south');
grid on;

f = linspace(-0.5, 0.5, nfft);

fig2 = figure(2);
plot(f, rectWinSpec, 'DisplayName', 'Rectangular');
hold on;
plot(f, hannWinSpec, 'DisplayName', 'Hann');
set(gca, 'ColorOrderIndex', 5);
plot(f, hammWinSpec, 'DisplayName', 'Hamming');
ylabel('Magnitude (dB)');
xlabel('Normalised Frequency (cycles per sample)');
ylim([-80, 30]);
hold off;
legend;
grid on;

xlim([-0.5, 0.5]);

% resizeFigure(fig1, 1, 0.9);
% filename = 'windowing_functions_t';
% saveas(fig1, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig1, ['figures\\other\\', filename, '.png']);
% 
% resizeFigure(fig2, 1, 0.9);
% filename = 'windowing_functions_f';
% saveas(fig2, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(fig2, ['figures\\other\\', filename, '.png']);
