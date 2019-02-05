function pred = predictOneDir(sig, ord, gapStart, gapEnd, fitLen, dr)
    %PREDICTONEDIR Predict signal based on AR model
    %   pred = PREDICTONEDIR(sig, ord, gapStart, gapEnd, fitLen) returns
    %   prediction pred of signal sig over a gap (gapStart being the index
    %   of the first gap sample and gapEnd being the index of the last gap
    %   sample) using an AR model of order ord and model fitting section of
    %   length fitLen.
    % 
    %   pred = PREDICTONEDIR(sig, ord, gapStart, gapEnd, fitLen, dr) returns
    %   prediction forwards (based on section before the gap) for dr >= 0
    %   or backwards (based on section after the gap) for dr < 0.

    if nargin == 5
        dr = 1;
    end

    % If direction is backwards, flip signal and adjust gapLoc
    if dr < 0
        sig = flipud(sig);
        gapLoc = length(sig) - gapEnd + 1;
    else
        gapLoc = gapStart;
    end

    % Select signal section for model fitting
    fitSect = sig(gapLoc - fitLen:gapLoc - 1);

    % Fit the model
    [a, e] = arburg(fitSect, ord);

    % Find initial conditions
    zinit = filtic(e, a, flipud(fitSect));

    % Prepare white noise input signal
    gapLen = gapEnd - gapStart + 1;
    in = randn(gapLen, 1);

    % Get prediction of missing signal
    pred = filter(e, a, in, zinit);

    % Flip prediction if direction is backwards
    if dr < 0
        pred = flipud(pred);
    end

end
