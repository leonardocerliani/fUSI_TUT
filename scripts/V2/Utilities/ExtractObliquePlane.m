
[pointInd] = find(ESMapShockPartial>0.1);
[xi,yi,zi] = ind2sub(size(ESMapShockPartial),pointInd);
findobj = planarFit([xi,yi,zi]');

%%
point = [yi(1),xi(1),zi(1)];
normal = [findobj.normal(2),findobj.normal(1),findobj.normal(3)];

[B,x,y,z] = obliqueslice(ESMapShockPartial,point,normal);

pcolor(rot90(B,2))
shading interp

