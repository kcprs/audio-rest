function sig = resynth(freqEst, ampEst, initPhs, hopLen)
    %RESYNTH Resynthesise signal based on spectral peak tracks

    freq = zeros((size(freqEst, 1) - 1) * hopLen + 1, size(freqEst, 2));
    amp = zeros((size(ampEst, 1) - 1) * hopLen + 1, size(ampEst, 2));

    for iter = 1:(size(freqEst, 1) - 1)

        for pkIter = 1:size(freqEst, 2)
            freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                linspace(freqEst(iter, pkIter), ...
                freqEst(iter + 1, pkIter), hopLen + 1).';
            amp((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                linspace(ampEst(iter, pkIter), ...
                ampEst(iter + 1, pkIter), hopLen + 1).';
        end

    end

    sig = zeros(size(freq, 1), 1);

    for iter = 1:size(freq, 2)
        sig = sig + getCosSig(size(freq, 1), freq(:, iter), ...
            amp(:, iter), initPhs(iter));
    end

end
