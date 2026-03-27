function HighlightRegions(ax,highlight)

vdat = 1:size(highlight,1); %vertical data
hdat = 1:size(highlight,2); %horizonatl

[x,y] = meshgrid(hdat, vdat);
x = interp2(x, 4); % change to 4 for round corners
y = interp2(y, 4); % change to 4 for round corners
contourlines = double(highlight==1);

contourlines = interp2(contourlines, 4, 'nearest');  % change to 4 and remove 'nearest' for round corners
dx = mean(diff(x(1, :))); % remove for round corners
dy = mean(diff(y(:, 1))); % remove for round corners

hold(ax,'on')
contour(ax,x+dx/2,y+dy/2,contourlines,2,'EdgeColor',[0.9 0.2 0.3],'LineWidth',1);

end