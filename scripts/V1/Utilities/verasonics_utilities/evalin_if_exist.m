function out = evalin_if_exist(WS,expression)
    if evalin(WS, ['exist(''' expression ''',''var'')'])
            out = evalin(WS, expression);
    else
        out = 0;
    end
end