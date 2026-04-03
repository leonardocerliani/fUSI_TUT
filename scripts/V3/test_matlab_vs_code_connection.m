%% Simple plot test
x = linspace(0, 2*pi, 100);
y1 = sin(x);
y2 = cos(x);

figure;
plot(x, y1, '-b', 'LineWidth', 2); hold on;
plot(x, y2, '--r', 'LineWidth', 2);
grid on;



xlabel('x');
ylabel('y');
title('Sine and Cosine Waves');
legend('sin(x)', 'cos(x)');

%% Another section (test running chunks)
z = sin(x) .* exp(-0.2*x);

figure;
plot(x, z, 'k', 'LineWidth', 2);
grid on;

title('Damped Sine Wave');
xlabel('x');
ylabel('z');

