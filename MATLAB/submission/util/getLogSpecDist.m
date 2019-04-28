function lsd = getLogSpecDist(psd1, psd2)
    % https://en.wikipedia.org/wiki/Log-spectral_distance
    % This is wrong! Normalised frequency!
    lsd = sqrt(1 / (2 * pi) * sum((10 * log10(psd1 ./ psd2)).^2, 1));
end