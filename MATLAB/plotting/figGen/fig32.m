close all;
fs = 44100;

frmLen = 2048;
gapLen = 2048;

sig = audioread("audio/Flute.nonvib.A4.wav");

[sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen);

plotWidth = gapLen * 5.2;
yPos = [0, -0.9, 0, 1.8];
preFrmPos = [gapStart - frmLen, 0, frmLen, 0];
postFrmPos = [gapEnd + 1, 0, frmLen, 0];

preCent = preFrmPos(1) + frmLen / 2;
postCent = postFrmPos(1) + frmLen / 2;

sigNaN = sig;
sigNaN(gapStart:gapEnd) = NaN;
plot(sigNaN);
hold on;
plot([preCent, preCent], [-0.9, 0.9], ':', 'Color', [198, 76, 0] / 256, ...
    'LineWidth', 2);
plot([postCent, postCent], [-0.9, 0.9], ':', 'Color', [55, 165, 0] / 256, ...
    'LineWidth', 2);
hold off;
rectangle('Position', preFrmPos + yPos, 'EdgeColor', [198, 76, 0] / 256, ...
    'LineWidth', 2);
rectangle('Position', postFrmPos + yPos, 'EdgeColor', [55, 165, 0] / 256, ...
    'LineWidth', 2);

plotMid = (gapStart + gapEnd) / 2;
ylim([-1, 1]);
xlim([plotMid - 0.5 * plotWidth, plotMid + 0.5 * plotWidth]);
ylabel("Amplitude");
xlabel("Time in samples");
grid on;

arrowLen = 0.1;
preArrStart = 0.295;
postArrStart = 0.742;

annotation('arrow', [preArrStart, preArrStart - arrowLen], [0.189, 0.189], ...
    'Color', [198, 76, 0] / 256, 'LineWidth', 2);
text(4.725e4, -0.74, 'Pre-section analysis direction', 'Color', [198, 76, 0] / 256);

annotation('arrow', [postArrStart, postArrStart + arrowLen], [0.189, 0.189], ...
    'Color', [55, 165, 0] / 256, 'LineWidth', 2);
text(5.562e4, -0.74, 'Post-section analysis direction', 'Color', [55, 165, 0] / 256);

resizeFigure(gcf, 2, 0.7);
% filename = 'spec_modelling_rest_analysis';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
