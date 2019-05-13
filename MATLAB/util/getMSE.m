function mseVal = getMSE(sig, pred)
    %GETMSE return mean squared error between signal and its prediction
    %   mseVal = getMse(sig, pred) returns MSE between signal sig and
    %   prediction pred
    
    if length(sig) ~= length(pred)
        error('Length mismatch: sig and pred should be the same length!');
    end

    mseVal = sum((sig - pred).^2) / length(sig);
end