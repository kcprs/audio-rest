fs = 44100;
frmLen = 2048;
hopLen = 256;
numFrm = 100;

for frmNum = 1:numFrm
    close all;

    sig = audioread("audio/Flute.nonvib.ff.A4.wav");
    sigFrgm = sig(frmLen * 5 + 1:frmLen * 10);
    frm = sigFrgm((frmNum - 1) * hopLen + 1:(frmNum - 1) * hopLen + frmLen);

    subplot(2, 1, 1);
    plot(sigFrgm);
    title('Signal - frames');
    xlabel('Time in samples');
    ylabel('Amplitude');
    hold on;
    amp = 0.6;
    r = rectangle('Position', [(frmNum - 1) * hopLen + 1, -amp, frmLen, 2 * amp]);
    hold off;

    subplot(2, 1, 2);
    [mag, ~] = getFT(frm);
    xVec = linspace(0, fs / 2, frmLen / 2);
    plot(xVec, mag(1:frmLen / 2));
    title('Spectrum of the selected frame');
    xlabel('Frequency in Hz');
    ylabel('Magnitude spectrum in dBFS');

    filename = strcat("anim/frame", num2str(frmNum), ".png");
    saveas(gcf, filename);
end
