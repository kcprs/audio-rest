classdef GetNextPhaseTest < matlab.unittest.TestCase

    methods (Test)

        function testDC(testCase)
            global fsGlobal;
            fs = fsGlobal;
            curPhase = 0;
            freq = 0;
            actual = getNextPhase(curPhase, freq, fs);
            expected = 0;
            
            testCase.verifyEqual(actual, expected);
        end
        
        function test1Hz(testCase)
            global fsGlobal;
            fs = fsGlobal;
            curPhase = 0;
            freq = 1;
            actual = getNextPhase(curPhase, freq, fs);
            expected = 1.4247e-04;

            testCase.verifyEqual(actual, expected, 'AbsTol', 1.0e-08);
        end        

    end

end