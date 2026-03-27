function radius = GetPupilSize(pupilCoodinates)

% pupilCoodinates should be t by n by 2 matrix representing t points of time and
% n points of (x,y)
% coordinates that are used to fit the circle

radius = nan(size(pupilCoodinates,1),1);
for it = 1:size(pupilCoodinates)
    % Sample data points (x,y)
    x = squeeze(pupilCoodinates(it,:,1))';
    y = squeeze(pupilCoodinates(it,:,2))';

    if sum(isnan(x))>2 | sum(isnan(y))>2
        continue
    end
    x(isnan(x)) = [];
    y(isnan(y)) = [];
    % Number of points
    n = length(x);

    % Construct matrices for solving the circle parameters
    A = [2*x, 2*y, ones(n,1)];
    b = x.^2 +y.^2;

    % Solve the linear system A*params=b
    params = A \ b;

    % Extract the circle parameters
    a = params(1);
    b = params(2);
    radius(it) = sqrt(params(3)+a^2+b^2);
end