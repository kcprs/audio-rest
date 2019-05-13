classdef MakeGapTest < matlab.unittest.TestCase

    methods (Test)

        function testGapInMiddleEvenEven(testCase)
            gapLen = 2;
            sig = [1; 1; 1; 1];
            expOutput = [1; 0; 0; 1];
            expGapStart = 2;
            expGapEnd = 3;

            [actOutput, actGapStart, actGapEnd] = makeGap(sig, gapLen);
            testCase.verifyEqual(actOutput, expOutput);
            testCase.verifyEqual(actGapStart, expGapStart);
            testCase.verifyEqual(actGapEnd, expGapEnd);
        end

        function testGapInMiddleOddOdd(testCase)
            gapLen = 3;
            sig = [1; 1; 1; 1; 1];
            expOutput = [1; 0; 0; 0; 1];
            expGapStart = 2;
            expGapEnd = 4;

            [actOutput, actGapStart, actGapEnd] = makeGap(sig, gapLen);
            testCase.verifyEqual(actOutput, expOutput);
            testCase.verifyEqual(actGapStart, expGapStart);
            testCase.verifyEqual(actGapEnd, expGapEnd);
        end

        function testGapInMiddleEvenOdd(testCase)
            gapLen = 3;
            sig = [1; 1; 1; 1];
            expOutput = [0; 0; 0; 1];
            expGapStart = 1;
            expGapEnd = 3;

            [actOutput, actGapStart, actGapEnd] = makeGap(sig, gapLen);
            testCase.verifyEqual(actOutput, expOutput);
            testCase.verifyEqual(actGapStart, expGapStart);
            testCase.verifyEqual(actGapEnd, expGapEnd);
        end

        function testGapInMiddleOddEven(testCase)
            gapLen = 2;
            sig = [1; 1; 1; 1; 1];
            expOutput = [1; 0; 0; 1; 1];
            expGapStart = 2;
            expGapEnd = 3;

            [actOutput, actGapStart, actGapEnd] = makeGap(sig, gapLen);
            testCase.verifyEqual(actOutput, expOutput);
            testCase.verifyEqual(actGapStart, expGapStart);
            testCase.verifyEqual(actGapEnd, expGapEnd);
        end

        function testGapSpecLoc(testCase)
            gapLen = 1;
            gapStart = 4;
            sig = [1; 1; 1; 1; 1];
            expOutput = [1; 1; 1; 0; 1];
            expGapStart = 4;
            expGapEnd = 4;

            [actOutput, actGapStart, actGapEnd] = ...
                makeGap(sig, gapLen, gapStart);
            testCase.verifyEqual(actOutput, expOutput);
            testCase.verifyEqual(actGapStart, expGapStart);
            testCase.verifyEqual(actGapEnd, expGapEnd);
        end

    end

end
