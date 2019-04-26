global ftmp
global ftlen

ftlen = 256;

for iterftlen = 1:3
    ftmp = 50;
    for iterftmp = 1:7
        basicAR
        ftmp = 2 * ftmp;
    end
    ftlen = ftlen * 2;
end