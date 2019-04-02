function plotPeakTracking(fEst, mEst, smpl)
    %PLOTPEAKTRACKING Helper function for plotting peak tracking information
    %   plotPeakTracking(fEst, mEst, smpl) plots peak tracking information
    %   based on vectors fEst (frequency estimates), mEst (magnitude
    %   estimates) and smpl (peak locations in time in samples).

    subplot(2, 1, 1);
    plot(smpl, fEst);
    title('Frequency Estimation');
    xlabel('Time in samples');
    ylabel('Frequency in Hz');
    grid on;

    subplot(2, 1, 2);
    plot(smpl, mEst);
    title('Magnitude Estimation');
    xlabel('Time in samples');
    ylabel('Magnitude of sinusoidal components in dBFS');
    grid on;
end
