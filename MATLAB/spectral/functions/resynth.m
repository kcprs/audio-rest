function sig = resynth(freqEst, magEst, initPhs, hopLen)
    %RESYNTH Resynthesise signal based on spectral peak tracks

    freq = zeros((size(freqEst, 1) - 1) * hopLen + 1, size(freqEst, 2));
    mag = zeros((size(magEst, 1) - 1) * hopLen + 1, size(magEst, 2));

    for iter = 1:(size(freqEst, 1) - 1)

        for pkIter = 1:size(freqEst, 2)
            freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                linspace(freqEst(iter, pkIter), ...
                freqEst(iter + 1, pkIter), hopLen + 1).';
            mag((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                linspace(magEst(iter, pkIter), ...
                magEst(iter + 1, pkIter), hopLen + 1).';
        end

    end

    sig = zeros(size(freq, 1), 1);

    for iter = 1:size(freq, 2)
        sig = sig + getCosSig(size(freq, 1), freq(:, iter), ...
            mag(:, iter), initPhs(iter));
    end

end
