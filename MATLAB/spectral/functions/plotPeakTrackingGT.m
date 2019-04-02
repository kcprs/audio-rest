function plotPeakTrackingGT(fgt, fEst, mgt, mEst, smpl)
    %PLOTPEAKTRACKINGGT Plot peak estimates and ground truth over time
    %   plotPeakTrackingGT(fgt, fEst, mgt, mEst, smpl) plots peak tracking
    %   information and ground truth information based on vectors fgt
    %   (frequency ground truth), fEst (frequency estimates), mgt (magnitude 
    %   ground truth), mEst (magnitude estimates) and smpl (peak locations
    %   in time in samples).

    subplot(2, 2, 1);
    plot(fgt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    plot(smpl, fEst);
    hold off;
    title('Frequency Estimation');
    xlabel('Time in samples');
    ylabel('Frequency in Hz');
    grid on;

    subplot(2, 2, 3);
    plot(mgt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    plot(smpl, mEst);
    hold off;
    title('Magnitude Estimation');
    xlabel('Time in samples');
    ylabel('Magnitude of sinusoidal components in dBFS');
    grid on;

    subplot(2, 2, 2);
    fgtSmpl = fgt(smpl, :);
    fgtSmpl = [fgtSmpl, zeros(size(fEst, 1), ...
                size(fEst, 2) - size(fgtSmpl, 2))];
    fRelErr = (fEst - fgtSmpl) ./ fgtSmpl;
    fRelErr = 100 * fRelErr;
    plot(smpl, fRelErr);
    title('Frequency Estimation - Relative Error');
    xlabel('Time in samples');
    ylabel('Relative error');
    grid on;
    ytickformat(gca, 'percentage');

    subplot(2, 2, 4);
    mgtSmpl = mgt(smpl, :);
    mgtSmpl = [mgtSmpl, zeros(size(mEst, 1), ...
                size(mEst, 2) - size(mgtSmpl, 2))];
    mErr = mEst - mgtSmpl;
    plot(smpl, mErr);
    title('Magnitude Estimation - Absolute Error');
    xlabel('Time in samples');
    ylabel('Absolute error (dBFS)');
    grid on;
end
