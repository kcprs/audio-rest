function pred = wfbar(pre, post, gapLen)
    %WFBAR Fix a gap in a signal using a weighted forward-backward predictor
    %   pred = wfbar(pre, post, gapLen) returns prediction pred of length
    %   gapLen based on given pre- and post-gap sections.

    %% Restoration
    % Predict the missing signal forward
    predFwd = burgPredict(pre, length(pre) - 1, length(pre) + 1, ...
        gapLen, length(pre));

    % Predict the missing signal backward
    predBwd = burgPredict(post, length(post) - 1, 0, -gapLen, length(post));

    % Apply the crossfade
    pred = crossfade(predFwd, predBwd);
end
