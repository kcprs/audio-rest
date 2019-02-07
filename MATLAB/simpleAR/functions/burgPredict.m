function pred = burgPredict(sig, ord, predStart, predLen, fitLen)
    %BURGPREDICT Predict signal using a Burg AR model
    %   pred = BURGPREDICT(sig, ord, predStart, predLen, fitLen) returns
    %   prediction pred of signal sig over predLen samples, starting from
    %   sample index predStart, based on fitLen neighbouring samples and
    %   using an AR model of order ord. For backwards prediction, pass index
    %   of the last gap sample as predStart and make predLen negative.

    % If direction is backwards, flip signal and predStart
    if predLen < 0
        sig = flipud(sig);
        predStart = length(sig) - predStart + 1;
    end

    % Select signal section for model fitting
    fitSect = sig(predStart - fitLen:predStart - 1);

    % Fit the model
    [a, e] = arburg(fitSect, ord);

    % Find initial conditions
    zinit = filtic(e, a, flipud(fitSect));

    % Prepare impulse input signal
    in = zeros(abs(predLen), 1);
    in(1) = 1;

    % Get prediction of missing signal
    pred = filter(e, a, in, zinit);

    % Flip prediction if direction is backwards
    if predLen < 0
        pred = flipud(pred);
    end

end
