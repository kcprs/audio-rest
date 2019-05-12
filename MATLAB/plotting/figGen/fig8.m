fs = 44100;

sigLen = 2048;
sig = audioread("audio/Trumpet.novib.mf.A4.wav");
sig = sig(10000: 10000 + sigLen - 1);


% sig = getCosSig(sigLen, 1000) + ...
%     getCosSig(sigLen, 800, -10, 0.1) + ...
%     getCosSig(sigLen, 200, -12, 0.9) + ...
%     getCosSig(sigLen, 3000, -2, 0.4) + ...
%     getCosSig(sigLen, 2614, -6, 0.2);

nfft = sigLen * 4;

dft = 20 * log10(abs(fft(sig .* hann(sigLen))));
f = linspace(0, fs, sigLen);

dftZP = 20 * log10(abs(fft(sig .* hann(sigLen), nfft)));
fZP = linspace(0, fs, nfft);

fig1 = figure(1);
plot(f, dft, 'DisplayName', 'No zero-padding');
hold on;
plot(fZP, dftZP, 'DisplayName', 'Zero-padding Z = 4');
hold off;
ylabel('Magnitude (dB)');
xlabel('Frequency (Hz)');
xlim([0, 1000]);
legend('Location', 'southeast');
grid on;

% resizeFigure(gcf, 2, 0.9);
% filename = 'zero_padding';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
