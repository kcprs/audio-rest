arOrder = 2;
sigLen = 1000;
contLen = 1000;
preLen = 100;
fs = 44100;

sig = getSineSig(440, sigLen/fs);

pre = sig(end - preLen:end);
[a, e] = arburg(pre, arOrder);

subplot(2, 1, 1);
zplane(1, a);

zi = filtic(e, a, fliplr(pre));
imp = zeros(contLen, 1);
imp(1) = 1;
cont = filter(e, a, imp, zi);

subplot(2, 1, 2);
plot(sig);
hold on;
plot(sigLen+1:sigLen+contLen, cont);
hold off;