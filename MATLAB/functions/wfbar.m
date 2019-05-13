function [pred, ordFw, ordBw] = wfbar(pre, post, gapLen, ord, rmDC)
    %WFBAR Fix a gap in a signal using a weighted forward-backward predictor
    %   [pred, ordFw, ordBw] = wfbar(pre, post, gapLen, ord, rmDC) returns
    %   prediction pred of length gapLen based on given pre- and post-gap
    %   sections using an AR model of order ord. If ord is set to 0, optimal
    %   order for the AR model model will be found using getArOrd().
    %
    %   [pred, ordFw, ordBw] = wfbar(pre, post, gapLen, ord, rmDC) uses
    %   default value of rmDC = false.

    if nargin < 5
        rmDC = false;
    end

    ordFw = ord;
    ordBw = ord;

    %% Restoration
    % If requested, find optimal AR order for forward prediction
    if ord == 0
        ordFw = getArOrd(pre);
    end

    % Predict the missing signal forward
    [predFwd, fwdCoeffs] = burgPredict(pre, ordFw, length(pre) + 1, ...
        gapLen, length(pre), rmDC);

    % If requested, find optimal AR order for backward prediction
    if ord == 0
        ordBw = getArOrd(post);
    end

    % Predict the missing signal backward
    [predBwd, bwdCoeffs] = burgPredict(post, ordBw, 0, -gapLen, ...
        length(post), rmDC);

    % Apply the crossfade
    pred = crossfade(predFwd, predBwd);

    % Prepare data for plotting frequency response
    global arFwdFreqResp;
    global arBwdFreqResp;
    global arFreqVec;
    global arFwdCoeffs;
    global arBwdCoeffs;
    global fsGlobal;

    arFwdCoeffs = fwdCoeffs;
    arBwdCoeffs = bwdCoeffs;
    [arFwdFreqResp, arFreqVec] = freqz(1, fwdCoeffs, 1000, fsGlobal);
    [arBwdFreqResp, ~] = freqz(1, bwdCoeffs, 1000, fsGlobal);
end
