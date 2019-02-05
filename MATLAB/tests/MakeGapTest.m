classdef MakeGapTest < matlab.unittest.TestCase

    methods (Test)

        function testGapInMiddleEvenEven(testCase)
            gapLen = 2;
            sig = [1; 1; 1; 1];
            expectedOutput = [1; 0; 0; 1];
            expectedGapLoc = 2;

            [actualOutput, actualGapLoc] = makeGap(sig, gapLen);
            testCase.verifyEqual(actualOutput, expectedOutput);
            testCase.verifyEqual(actualGapLoc, expectedGapLoc);
        end

        function testGapInMiddleOddOdd(testCase)
            gapLen = 3;
            sig = [1; 1; 1; 1; 1];
            expectedOutput = [1; 0; 0; 0; 1];
            expectedGapLoc = 2;

            [actualOutput, actualGapLoc] = makeGap(sig, gapLen);
            testCase.verifyEqual(actualOutput, expectedOutput);
            testCase.verifyEqual(actualGapLoc, expectedGapLoc);
        end

        function testGapInMiddleEvenOdd(testCase)
            gapLen = 3;
            sig = [1; 1; 1; 1];
            expectedOutput = [0; 0; 0; 1];
            expectedGapLoc = 1;

            [actualOutput, actualGapLoc] = makeGap(sig, gapLen);
            testCase.verifyEqual(actualOutput, expectedOutput);
            testCase.verifyEqual(actualGapLoc, expectedGapLoc);
        end

        function testGapInMiddleOddEven(testCase)
            gapLen = 2;
            sig = [1; 1; 1; 1; 1];
            expectedOutput = [1; 0; 0; 1; 1];
            expectedGapLoc = 2;

            [actualOutput, actualGapLoc] = makeGap(sig, gapLen);
            testCase.verifyEqual(actualOutput, expectedOutput);
            testCase.verifyEqual(actualGapLoc, expectedGapLoc);
        end

        function testGapSpecLoc(testCase)
            gapLen = 1;
            gapLoc = 4;
            sig = [1; 1; 1; 1; 1];
            expectedOutput = [1; 1; 1; 0; 1];

            actualOutput = makeGap(sig, gapLen, gapLoc);
            testCase.verifyEqual(actualOutput, expectedOutput);
        end
    end

end
