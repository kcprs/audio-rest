function [sigDmg, gapStart, gapEnd] = makeGap(sig, gapLen, gapStart)
    %MAKEGAP Introduce a gap of zeros in a given signal
    %   [sigDmg, gapStart, gapEnd] = MAKEGAP(sig, gapLen) returns a copy of
    %   signal sig with gap of length gapLen. Gap location is chosen so that
    %   the centre of the gap lies in the centre of signal sig.
    %
    %   [sigDmg, gapStart, gapEnd] = MAKEGAP(sig, gapLen, gapStart) returns
    %   a copy of signal sig with gap of length gapLen starting at
    %   index gapStart.

    if nargin == 2
        gapStart = floor((length(sig) - gapLen) / 2) + 1;
    end

    sigDmg = sig;
    sigDmg(gapStart:gapStart + gapLen - 1) = zeros(gapLen, 1);
    gapEnd = gapStart + gapLen - 1;
end
