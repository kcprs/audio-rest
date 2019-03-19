fs = 44100;
intpLen = 4 * fs;
frmLen = 1024;

sig = audioread('audio/Flute.nonvib.ff.A4.wav');
s1 = sig(fs:fs + frmLen - 1);
s2 = sig(1.5 * fs:1.5 * fs + frmLen - 1);

res = wfbar(s1, s2, intpLen);