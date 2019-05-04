function sig = resynth(freqEst, magEst, initPhs, hopLen, endPhs)
    %RESYNTH Resynthesise signal based on spectral peak tracks
    %   sig = resynth(freqEst, magEst, initiPhs, hopLen, endPhs) returns
    %   signal resynthesised from frequency and magnitude estimate matrices
    %   freqEst and magEst. Vector initPhs contains initial phases for each
    %   track and endPhs contains target end phases of each track. Set
    %   endPhs to NaN to skip the phase matching stage.
    %   Hop length between frames (in samples) is given by hopLen.

    if nargin < 5
        endPhs = NaN;
    end

    almostNegInf = -100; % Approximation of negative infinity in dB

    %% Allocate matrices for sample-by-sample values of freq and mag
    freq = zeros((size(freqEst, 1) - 1) * hopLen + 1, size(freqEst, 2));
    mag = zeros((size(magEst, 1) - 1) * hopLen + 1, size(magEst, 2));
    initPhs(isnan(initPhs)) = 0;

    %% Prepare frequency and magnitude matrices
    % (Converting from frame-by-frame to sample-by-sample changes)
    for iter = 1:(size(freqEst, 1) - 1)

        for pkIter = 1:size(freqEst, 2)

            if ~isnan(freqEst(iter, pkIter)) && ...
                    isnan(freqEst(iter + 1, pkIter))
                % Resynthesising a dying track
                % Keep frequency, fade out magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    freqEst(iter, pkIter);
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    linspace(magEst(iter, pkIter), ...
                    almostNegInf, hopLen + 1).';
            elseif isnan(freqEst(iter, pkIter)) && ...
                    (~isnan(freqEst(iter + 1, pkIter)))
                % Resynthesising a born track
                % Use frequency from next frame, fade in magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    freqEst(iter + 1, pkIter);
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    linspace(almostNegInf, magEst(iter + 1, pkIter), ...
                    hopLen + 1).';
            elseif isnan(freqEst(iter, pkIter)) && ...
                    isnan(freqEst(iter + 1, pkIter))
                % Continuing a dead track
                % Skip frequency and magnitude information
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = NaN;
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = NaN;
            else
                % Continuing an alive track
                % Linearly interpolate frequency and magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    linspace(freqEst(iter, pkIter), ...
                    freqEst(iter + 1, pkIter), hopLen + 1).';
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, pkIter) = ...
                    linspace(magEst(iter, pkIter), ...
                    magEst(iter + 1, pkIter), hopLen + 1).';
            end

        end

    end

    %% Alter frequency trajectories to match end phase
    if ~all(isnan(endPhs))

        for iter = 1:size(freq, 2)
            freq(:, iter) = matchEndPhase(freq(:, iter), initPhs(iter), ...
                    endPhs(iter));
        end

    end

    %% Synthesise the signal
    sig = zeros(size(freq, 1), 1);

    for iter = 1:size(freq, 2)
        newSig = getCosSig(size(freq, 1), freq(:, iter), ...
            mag(:, iter), initPhs(iter));

        if (all(~isnan(newSig)))
            sig = sig + newSig;
        end

    end

end
