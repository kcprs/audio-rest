function [output, gapLoc] = makeGap(sig, gapLen, gapLoc)
    %MAKEGAP Introduce a gap of zeros in a given signal
    %   [output, gapLoc] = MAKEGAP(sig, gapLen) returns a copy of signal sig
    %   with gap of length gapLen. Gap location is chosen so that the centre
    %   of the gap lies in the centre of signal sig.
    % 
    %   [output, gapLoc] = MAKEGAP(sig, gapLen, gapLoc) returns a copy of
    %   signal sig with gap of length gapLen starting at index gapLoc.

    if nargin == 2
        gapLoc = floor((length(sig) - gapLen) / 2);
    end

    output = sig;
    output(gapLoc:gapLoc + gapLen - 1) = zeros(gapLen, 1);
end
