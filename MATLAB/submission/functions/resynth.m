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

        for trIter = 1:size(freqEst, 2)

            if ~isnan(freqEst(iter, trIter)) && ...
                    isnan(freqEst(iter + 1, trIter))

                % Resynthesising a dying track
                % Keep frequency, fade out magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    freqEst(iter, trIter);
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    linspace(magEst(iter, trIter), ...
                    almostNegInf, hopLen + 1).';
            elseif isnan(freqEst(iter, trIter)) && ...
                    (~isnan(freqEst(iter + 1, trIter)))

                % Resynthesising a born track
                % Use frequency from next frame, fade in magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    freqEst(iter + 1, trIter);
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    linspace(almostNegInf, magEst(iter + 1, trIter), ...
                    hopLen + 1).';
            elseif isnan(freqEst(iter, trIter)) && ...
                    isnan(freqEst(iter + 1, trIter))

                % Continuing a dead track
                % Skip frequency and magnitude information
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = NaN;
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = NaN;
            else
                % Continuing an alive track
                % Linearly interpolate frequency and magnitude
                freq((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    linspace(freqEst(iter, trIter), ...
                    freqEst(iter + 1, trIter), hopLen + 1).';
                mag((iter - 1) * hopLen + 1:iter * hopLen + 1, trIter) = ...
                    linspace(magEst(iter, trIter), ...
                    magEst(iter + 1, trIter), hopLen + 1).';
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

        sig = sig + newSig;

    end

end
