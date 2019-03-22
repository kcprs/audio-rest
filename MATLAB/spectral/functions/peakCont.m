function peakCont(trks, pkFreq, pkMag, pkPhs, smpl, pitchEst)
    % PEAKCONT Assign spectral peaks to best fitting SinTracks

    numTrk = numel(trks);
    numPk = length(pkFreq);
    pkScore = zeros(numTrk, numPk);
    trksDone = zeros(1, min(numTrk, numPk));

    % If no pitch estimate given, use lowest peak frequency
    if isnan(pitchEst)
        pitchEst = min(pkFreq);
    end

    % Compute peak closeness scores for each SinTrack
    % Save centre sample of current frame
    for trkIter = 1:numTrk
        pkScore(trkIter, :) = trks(trkIter).getPkScore(pkFreq, ...
            pkMag, pitchEst / 2);
        trks(trkIter).saveSmpl(smpl);
    end

    % Assign peaks to SinTracks by finding lowest closeness scores
    for trkIter = 1:numTrk
        % Find lowest closeness score and the corresponding track-peak pair
        minScore = min(pkScore, [], 'all');
        [trkInd, pkInd] = find(pkScore == minScore, 1);

        if isempty(minScore) || isnan(minScore)
            break;
        end

        % Save peak values to its closest track
        trks(trkInd).setFMP(pkFreq(pkInd), pkMag(pkInd), pkPhs(pkInd));

        % Clear column and row corresponding to the selected track and peak,
        % respectively.
        pkScore(trkInd, :) = NaN;
        pkScore(:, pkInd) = NaN;

        % Save index of track
        trksDone(trkIter) = trkInd;
    end

    % disp(['Tracks assigned: ', num2str(sum(trksDone ~= 0))]);

    % Kill tracks for which peks could not be found
    for trkIter = 1:numTrk

        if ~ismember(trkIter, trksDone)
            trks(trkIter).setFMP(NaN, NaN, NaN);
        end

    end

end
