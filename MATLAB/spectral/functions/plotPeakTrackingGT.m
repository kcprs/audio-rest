function plotPeakTrackingGT(fgt, fEst, agt, aEst, smpl)
    % Strip zeros - NaN will not show on the plot
    fEst(fEst == 0) = NaN;
    aEst(aEst == 0) = NaN;

    subplot(2, 2, 1);
    semilogy(fgt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    semilogy(smpl, fEst);
    hold off;
    title('Frequency Estimation');
    xlabel('Time in samples');
    ylabel('Frequency in Hz');
    grid on;

    subplot(2, 2, 3);
    plot(agt, '--');
    hold on;
    set(gca, 'ColorOrderIndex', 1);
    plot(smpl, aEst);
    hold off;
    title('Amplitude Estimation');
    xlabel('Time in samples');
    ylabel('Amplitude of sinusoidal components');
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
    agtSmpl = agt(smpl, :);
    agtSmpl = [agtSmpl, zeros(size(aEst, 1), ...
                size(aEst, 2) - size(agtSmpl, 2))];
    aRelErr = (aEst - agtSmpl) ./ agtSmpl;
    aRelErr = 100 * aRelErr;
    plot(smpl, aRelErr);
    title('Amplitude Estimation - Relative Error');
    xlabel('Time in samples');
    ylabel('Relative error');
    grid on;
    ytickformat(gca, 'percentage');
end
