function plotPeakTracking(fEst, mEst, smpl)

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
