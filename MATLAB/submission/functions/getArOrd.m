function ord = getArOrd(sig, mseTrs)

    if nargin < 2
        mseTrs = 0.0001;
    end

    sigLen = length(sig);
    divSmpl = floor(sigLen / 2);
    predLen = floor(sigLen / 2);

    sigFit = sig(1:divSmpl);
    sigTest = sig(divSmpl + 1:divSmpl + predLen);

    ord = 1;
    mseVal = Inf;

    while ord + 1 < predLen && mseVal > mseTrs
        ord = ord + 1;
        [pred, ~] = burgPredict(sigFit, ord, divSmpl + 1, predLen, divSmpl);

        mseVal = getMSE(pred, sigTest);
    end
end