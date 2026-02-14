% Example data
A = rand(100,90,5000);

% Mean along 3rd dimension
meanImg = mean(A,3);

figure

% --- Image axes ---
ax1 = subplot(1,2,1);
hImg = imagesc(meanImg);
axis image
colormap gray
title('Mean Image')

set(hImg,'ButtonDownFcn',@clickCallback)

% --- Time course axes ---
ax2 = subplot(1,2,2);
title('Time Course')
xlabel('Time')
ylabel('Value')

% Store data
data.A = A;
data.ax1 = ax1;
data.ax2 = ax2;
data.marker = gobjects(1);   % initialize properly as graphics object
guidata(gcf,data);


% ================= Callback =================
function clickCallback(~,~)

    data = guidata(gcf);
    A = data.A;

    % Get click location
    cp = get(data.ax1,'CurrentPoint');
    x = round(cp(1,1));
    y = round(cp(1,2));

    % Bounds check
    if x>=1 && x<=size(A,2) && y>=1 && y<=size(A,1)

        % Extract time course
        timecourse = squeeze(A(y,x,:));

        % Plot time course
        axes(data.ax2)
        plot(timecourse)
        title(sprintf('Pixel (%d,%d)',y,x))
        xlabel('Time')
        ylabel('Value')

        % ---- Highlight pixel ----
        axes(data.ax1)
        hold on
        if isgraphics(data.marker)
            delete(data.marker)
        end
        data.marker = plot(x,y,'r.','MarkerSize',20);
        hold off

        guidata(gcf,data);
    end
end
