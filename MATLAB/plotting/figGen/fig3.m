sig = audioread("audio/adsr.wav");

fs = 44100;
t = 1000 * (1:length(sig)) / fs;

startNote = 50;
attack = 120;
decayT = 250;
sustain = 660;
endNote = 1278;

atInd = [startNote, attack];
dcInd = [attack, decayT];
susInd = [decayT, sustain];
relInd = [sustain, endNote];

[env, ~] = envelope(sig, 200, 'peak');

at = env(round(atInd * fs / 1000));
dc = env(round(dcInd * fs / 1000));
sus = env(round(susInd * fs / 1000));
rel = env(round(relInd * fs / 1000));

plot(t, sig)
hold on;
plot(atInd, at, 'Color', [196, 29, 0] / 256, 'LineWidth', 2);
plot(dcInd, dc, 'Color', [51, 60, 165] / 256, 'LineWidth', 2);
plot(susInd, sus, 'Color', [65, 178, 0] / 256, 'LineWidth', 2);
plot(relInd, rel, 'Color', [198, 55, 134] / 256, 'LineWidth', 2);
xlabel('Time (ms)');
ylabel('Amplitude');
xlim([-50, 1300]);
grid on;

text(-35, 0.08, 'Attack', 'Color', [196, 29, 0] / 256);
text(200, 0.12, 'Decay', 'Color', [51, 60, 165] / 256);
text(400, 0.11, 'Sustain', 'Color', [65, 178, 0] / 256);
text(900, 0.07, 'Release', 'Color', [198, 55, 134] / 256);
hold off;

resizeFigure(gcf, 1, 0.7);

% filename = 'adsr';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
