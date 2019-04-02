function pitchEst = estPitch(pkFreqs, minHarm)
    %ESTPITCH Estimate pitch based on given spectral peaks
    %   pitchEst = estPitch(pkFreqs, minHarm) returns pitch estimate
    %   pitchEst in Hz based on spectral peak frequencies pkFreqs. Only
    %   those frequencies are considered as pitch estimate candidates for
    %   which at least minHarm potential harmonics are present in the vector
    %   pkFreqs.

    % Find pitch candidates - all given peak frequencies
    % and all differences between them
    pitchCand = [pkFreqs, reshape(pkFreqs - pkFreqs.', 1, [])].';

    % Limit to sensible musical values (lowest to highest piano notes)
    pitchCand = pitchCand(pitchCand > 27.5);
    pitchCand = pitchCand(pitchCand < 4186);
    pitchCand = unique(pitchCand);

    % Get pitch score for each candidate
    pScores = zeros(length(pitchCand), 1);

    for iter = 1:length(pitchCand)
        pScores(iter) = getPitchScore(pitchCand(iter), pkFreqs, minHarm);
    end

    % Return pitch with lowest score or NaN if no sufficiently
    % good estimates were found.
    [minScore, bestEstInd] = min(pScores);

    if minScore < 0.05
        pitchEst = pitchCand(bestEstInd);
    else
        pitchEst = NaN;
    end

end

function score = getPitchScore(pitch, pkFreqs, minHarm)
    fRatio = pkFreqs / pitch;

    % Only consider ratios > 0.99 to exclude any frequencies that are not
    % the fundamental (approximately) or potential harmonics
    fRatio = fRatio(fRatio > 0.99);

    % If more than minHarm potential harmonics were found, compute score
    if length(fRatio) >= minHarm
        % Use average relative distance to nearest harmonic as score
        relDist = min(fRatio - floor(fRatio), ceil(fRatio) - fRatio);
        score = sum(relDist) / length(relDist);
    else
        score = NaN;
    end

end
