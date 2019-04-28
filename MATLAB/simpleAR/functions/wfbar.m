function pred = wfbar(pre, post, gapLen, ord, rmDC)
    %WFBAR Fix a gap in a signal using a weighted forward-backward predictor
    %   pred = wfbar(pre, post, gapLen, ord, rmDC) returns prediction pred 
    %   of length gapLen based on given pre- and post-gap sections using
    %   an AR model of order ord.
    % 
    %   pred = wfbar(pre, post, gapLen, ord, rmDC) uses default value of
    %   rmDC = false.

    if nargin < 5
        rmDC = false;
    end

    %% Restoration
    % Predict the missing signal forward
    predFwd = burgPredict(pre, ord, length(pre) + 1, gapLen, ...
        length(pre), rmDC);

    % Predict the missing signal backward
    predBwd = burgPredict(post, ord, 0, -gapLen, length(post), rmDC);

    % Apply the crossfade
    pred = crossfade(predFwd, predBwd);
end
