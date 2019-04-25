function nfft = getNFFT(sigLen)
    % Assuming Hann window and frequency accuracy of at least 0.1%
    nfft = 2^nextpow2(2.4 * sigLen);
end
