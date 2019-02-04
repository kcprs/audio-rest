function output = makeGap(sig, gapLoc, gapLen)
    %MAKEGAP Introduce a gap of zeros in a given signal
    %   output = MAKEGAP(sig, gapLoc, gapLen) returns a copy of signal sig
    %   with gap of length gapLen starting at index gapLoc.

    output = sig;
    output(gapLoc:gapLoc + gapLen - 1) = zeros(gapLen, 1);
end
