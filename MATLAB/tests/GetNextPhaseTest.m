classdef GetNextPhaseTest < matlab.unittest.TestCase

    methods (Test)

        function testDC(testCase)
            curPhase = 0;
            freq = 0;
            fs = 44100;
            actual = getNextPhase(curPhase, freq, fs);
            expected = 0;

            testCase.verifyEqual(actual, expected);
        end

        function testDefaultFs(testCase)
            curPhase = 0;
            freq = 17;
            actual = getNextPhase(curPhase, freq);
            expected = 0.0024;

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-04);
        end

        function test1Hz(testCase)
            curPhase = 0;
            freq = 1;
            actual = getNextPhase(curPhase, freq);
            expected = 1.4247e-04;

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-08);
        end        

    end

end