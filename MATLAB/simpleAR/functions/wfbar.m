function pred = wfbar(pre, post, gapLen, ord)
    %WFBAR Fix a gap in a signal using a weighted forward-backward predictor
    %   pred = wfbar(pre, post, gapLen, ord) returns prediction pred of
    %   length gapLen based on given pre- and post-gap sections using an AR
    %   model of order ord.

    %% Restoration
    % Predict the missing signal forward
    predFwd = burgPredict(pre, ord, length(pre) + 1, gapLen, length(pre));

    % Predict the missing signal backward
    predBwd = burgPredict(post, ord, 0, -gapLen, length(post));

    % Apply the crossfade
    pred = crossfade(predFwd, predBwd);
end
