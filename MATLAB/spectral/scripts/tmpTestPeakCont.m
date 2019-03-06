numTrk = 3;
numFrm = 5;

trks(1, numTrk) = SinTrack();

for iter = 1:numel(trks)
    trks(iter).allocate(numFrm);
end

pkFreq = [1, 4, 7, 10, 12;
    1, 5, 6, 9, 14;
    2, 4, 7, 8, 11;
    3, 4, 6, 9, 12;
    2, 5, 5, 10, 11];
pkMag = ones(size(pkFreq));
pkPhs = ones(size(pkFreq));

for iter = 1:size(pkFreq, 1)
    [trks.frmCursor] = deal(iter);
    peakCont(trks, pkFreq(iter, :), pkMag(iter, :), pkPhs(iter, :), iter);
end
