classdef GetDelPhsTest < matlab.unittest.TestCase

    methods (Test)

        function testDC(testCase)
            global fsGlobal;
            fs = fsGlobal;
            freq = 0;
            actual = getDelPhs(freq, fs);
            expected = 0;

            testCase.verifyEqual(actual, expected);
        end

        function test1Hz(testCase)
            global fsGlobal;
            fs = fsGlobal;
            freq = 1;
            actual = getDelPhs(freq, fs);
            expected = 1.4247e-04;

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-08);
        end

    end

end
