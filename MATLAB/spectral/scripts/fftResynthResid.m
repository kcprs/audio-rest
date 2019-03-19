% FFTRESYNTHRESID Resynthesise residual through Fourier Transforms

fs = 44100;
mult = 1;
frmLen = 1024 * mult;
intpLen = 4 * fs;

% sig = audioread('audio/Flute.nonvib.ff.A4.wav');
% s1 = sig(fs:fs + frmLen - 1);
% s2 = sig(1.5 * fs:1.5 * fs + frmLen - 1);

s1 = getCosSig(frmLen, mult * 8 * fs / frmLen);
s2 = getCosSig(frmLen, mult * 16 * fs / frmLen);

amp1 = abs(fft(s1));
amp2 = abs(fft(s2));

fade = [linspace(0, 1, frmLen / 2), linspace(1, 0, frmLen / 2)].';

hopLen = floor(frmLen / 2);
numHop = ceil((intpLen - frmLen) / hopLen) + 1;

output = zeros(hopLen * (numHop - 1) + frmLen, 1);

for iter = 1:numHop
    weight = (iter - 1) / (numHop - 1);

    amp = amp1 * (1 - weight) + amp2 * weight;
    % phs = rand([frmLen, 1]);
    phs = zeros(frmLen, 1);

    frm = real(ifft(amp .* exp(1j * phs)));
    frm = fade .* frm;

    cursor = (iter - 1) * hopLen;
    output(cursor + 1:cursor + frmLen) = ...
        output(cursor + 1:cursor + frmLen) + frm;

    plot(output(1:cursor + frmLen));
end

soundsc(output, fs);
