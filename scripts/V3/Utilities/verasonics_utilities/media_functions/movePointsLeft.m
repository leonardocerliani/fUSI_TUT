function movePointsLeft
    %
    % Copyright 2001-2017 Verasonics, Inc.  All world-wide rights and remedies under all intellectual property laws and industrial property laws are reserved.  Verasonics Registered U.S. Patent and Trademark Office.
    %
    % movePoints moves the x location of points in the Media.Pts array in a
    % sinusoidal pattern.

    persistent tval
    delta = 2 * pi / 30; % change in tval between successive calls
    amp = 10; % amplitude of displacement in wavelengths

    if isempty(tval)
        tval = 0;
    end

    if evalin('base', 'exist(''Media'',''var'')')
        Media = evalin('base', 'Media');
    else
        disp('Media object not found in workplace.');
        return
    end

    % Modify x position of all media points
    Media.MP(:, 1) = Media.MP(:, 1) - 0.5; % mv pts with half wavelength

    assignin('base', 'Media', Media);

    return
