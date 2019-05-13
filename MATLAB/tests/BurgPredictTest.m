classdef BurgPredictTest < matlab.unittest.TestCase

    methods (Test)

        function testShapeGapLenFwd(testCase)
            ord = 2;
            sigLen = 1000;
            gapLen = 500;
            fitLen = 200;
            sig = getSinSig(sigLen, 440);
            [dam, gapStart, ~] = makeGap(sig, gapLen);

            testCase.assumeSize(dam, [sigLen, 1]);
            pred = burgPredict(dam, ord, gapStart, gapLen, fitLen);

            testCase.verifySize(pred, [gapLen, 1]);
        end

        function testShapeGapLenBwd(testCase)
            ord = 2;
            sigLen = 1000;
            gapLen = 500;
            fitLen = 200;
            sig = getSinSig(sigLen, 440);
            [dam, ~, gapEnd] = makeGap(sig, gapLen);

            testCase.assumeSize(dam, [sigLen, 1]);
            pred = burgPredict(dam, ord, gapEnd, -gapLen, fitLen);

            testCase.verifySize(pred, [gapLen, 1]);
        end

        function testShapeArbLenFwd(testCase)
            ord = 2;
            sigLen = 1000;
            gapLen = 500;
            fitLen = 200;
            predLen = 200;
            sig = getSinSig(sigLen, 440);
            [dam, gapStart, ~] = makeGap(sig, gapLen);

            testCase.assumeSize(dam, [sigLen, 1]);
            pred = burgPredict(dam, ord, gapStart, predLen, fitLen);

            testCase.verifySize(pred, [predLen, 1]);
        end

        function testShapeArbLenBwd(testCase)
            ord = 2;
            sigLen = 1000;
            gapLen = 500;
            fitLen = 200;
            predLen = 200;
            sig = getSinSig(sigLen, 440);
            [dam, ~, gapEnd] = makeGap(sig, gapLen);

            testCase.assumeSize(dam, [sigLen, 1]);
            pred = burgPredict(dam, ord, gapEnd, -predLen, fitLen);

            testCase.verifySize(pred, [predLen, 1]);
        end
    end

end