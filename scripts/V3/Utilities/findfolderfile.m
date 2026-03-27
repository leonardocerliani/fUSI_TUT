% 获取主路径下所有的文件、子路径、子路径下文件
%
% 输入：
% folder 文件夹
% str 特定字符
%
% 输出：
% folder 子文件夹列表（文件夹）
% file 文件列表（文件-所在文件夹）
% list 关系总表（文件夹-子文件夹-文件）
%
% example:
% [folder,file,list] = findfolderfile('.\test\img','jpg');
%
% by HPC_ZY 20200105

%% 获取某文件夹下所有子文件列表，与含特定字符的所有文件列表
function [folder,file,list] = findfolderfile(folder,str)

% 利用递归获得子文件夹与文件
list = folderfile(folder,str,[]);

% 文件夹总表
folder = list(:,1);

% 文件总表
file = [];
for k = 1:size(list,1)
    if ~isempty(list(k,3))  
        for n = 1:length(list{k,3})
            file = cat(1,file,{list{k,1},list{k,3}{n}});
        end
    end    
end

end

%% ------------------递归搜索当前文件夹内子文件夹与文件-------------
function list = folderfile(folder,str,list)

    % 获取当前文件夹内的子文件夹和文件
    dirout = dir(fullfile(folder));
    [folder,subfolder,file] = listfolderfile(dirout,str);
    
    % 保存搜索结果
    list = cat(1,list,{folder,subfolder,file});

    % 搜索子文件夹
    if ~isempty(subfolder)
        for k = 1:length(subfolder)
            list = folderfile(fullfile(folder,subfolder{k}),str,list);  
        end
    end

end

%%------------- 分辨文件夹和文件，并去除./..文件-----------
function [folder,subfolder,file] = listfolderfile(list,str)

% 当前目录
folder = list(1).folder;
% 子目录
idx = cell2mat({list.isdir});
subfolder = {list(idx).name}';
% 文件
file = {list(~idx).name}';

% 剔除 ./..
for k = length(subfolder):-1:1
    if sum(strcmp(subfolder{k},{'.','..'}))
        subfolder(k) = [];
    end
end 

% 筛选指定
if ~isempty(str)
	for k = length(file):-1:1
    	if isempty(strfind(file{k},str))
       		file(k) = []; 
    	end
	end
end

end
