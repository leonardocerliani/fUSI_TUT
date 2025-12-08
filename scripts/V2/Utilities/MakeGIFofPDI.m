%% make gif with PDI data
% select the trial to make gif
trl = 1;
% array = squeeze(PDI.trlPDI(:,:,trl,:));

% using whole sequence to make gif
array = squeeze(PDI.PDI(:,:,2700:2760));
timeFrame = PDI.time(2700:2760);


filename = [PDI.savepath filesep 'PDI' num2str(trl) '.gif']; % the filename of the gif you want
h = figure;
h.InvertHardcopy = 'off'; % Maintain the white background from the figure
size_z=PDI.Dim.dz;size_x=PDI.Dim.dx; % Defines the size of the pixels in meters
framecount=0;% Simple counter for the frame
for i = 1:1:size(array,3)% Here I am assuming that you are doing the scanning thing. It will take every 8th frame and display it. If you have a different array you have to change this
    framecount=framecount+1;

    % Log compress the array loaded and normalize by the max
%     logPDI = 20 * log(array(30:120, 60:230, i));
 logPDI = 50 * log(array(:, :, i));
    logPDI = logPDI - max(logPDI(:));

    imagesc(logPDI);% display the image
    caxis([-120 0]);% Coloraxis in dB (you can change this depending on your intensity range)
    daspect([1 size_x/size_z 1]);% This will scale the pixel according to their size
    colormap hot;% Defines the colormap
    title(['t= ', num2str(timeFrame(i)), ' s']);% This will print a title above the figure drawnow; pause(0.1)
    
    % Get the frame in the figure, then store it as an image
    frame = getframe(h);% Gets the frame from figure g
    im = frame2im(frame);% Converts it to an image
    [imind, cm] = rgb2ind(im, 256);% Convert the image to rgb

    % Write to the GIF File
    if framecount == 1 % If the frame count is 1 then it will need to create the file
        imwrite(imind, cm, filename, 'gif', 'Loopcount', inf);
    else % else it will simply append the frame to the original file
        imwrite(imind, cm, filename, 'gif', 'WriteMode', 'append');
    end

end
