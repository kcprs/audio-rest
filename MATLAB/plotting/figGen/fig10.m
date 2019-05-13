a = -1;
b = 2.3;
c = 2.1;

y = [a, b, c];
x = [-1, 0, 1];

pol = polyfit(x, y, 2);
xPlot = linspace(-1.5, 1.5, 1000);
yPlot = polyval(pol, xPlot);

[yp, p] = max(yPlot);
p = xPlot(p);

plot(x, y, 'o', 'MarkerSize', 8);
hold on;
plot(xPlot, yPlot, 'Color', 'Black');
hold off;
grid on;
ax = gca;
ax.FontSize = 14;
ax.GridLineStyle = '--';
ax.GridAlpha = 0.5;
xlabel('DFT bin number', 'FontSize', 11);
ylabel('Magnitude', 'FontSize', 11);
xlim([p - 1.7, p + 1.7]);
ylim([a - 0.2, yp + 0.2]);

xticks([-1, 0, p, 1]);
xticklabels({'-1', '0', 'p', '1'});

yticks([a, c, b, yp]);
yticklabels({'\alpha', '\gamma', '\beta', 'y(p)'});

resizeFigure(gcf, 1, 0.9);
% filename = 'qifft';
% saveas(gcf, ['figures\\other\\', filename, '.eps'], 'epsc');
% saveas(gcf, ['figures\\other\\', filename, '.png']);
