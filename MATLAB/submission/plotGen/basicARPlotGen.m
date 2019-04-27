global ftmp
global ftlen

ftlen = 256;

for iterftlen = 1:3
    ftmp = 100;
    for iterftmp = 1:2
        basicAR
        ftmp = 800;
    end
    ftlen = ftlen * 2;
end