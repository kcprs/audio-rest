function avErrPSD = getAvErrPSD(psd1, psd2)
    pDiff = 10 * (log10(abs(psd1)) - log10(abs(psd2)));
    avErrPSD = mean(pDiff, 1);
end