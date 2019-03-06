function peakCont(trks, pkFreq, pkMag, pkPhs, smpl)
    % PEAKCONT Assign spectral peaks to best fitting SinTracks
    
    numTrk = numel(trks);
    numPk = length(pkFreq);
    pkScore = zeros(numTrk, numPk);
    
    % Compute peak closeness scores for each SinTrack
    % Save centre sample of current frame
    for trkIter = 1:numTrk
        pkScore(trkIter, :) = trks(trkIter).getPkScore(pkFreq);
        trks(trkIter).saveSmpl(smpl);
    end

    % Assign peaks to SinTracks by finding lowest closeness scores
    for trkIter = 1:numTrk
        % Find lowest closeness score and the corresponding track-peak pair
        minScore = min(pkScore, [], 'all');
        [trkInd, pkInd] = find(pkScore == minScore, 1);

        % Save peak values to its closest track
        trks(trkInd).setFMP(pkFreq(pkInd), pkMag(pkInd), pkPhs(pkInd));

        % Clear column and row corresponding to the selected track and peak,
        % respectively.
        pkScore(trkInd, :) = NaN;
        pkScore(:, pkInd) = NaN;
    end
end