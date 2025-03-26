function setup(baseFolder)
% ADDALLFOLDERS Recursively adds a folder and its sub-folders to the MATLAB path.
%
%   addAllFolders(baseFolder) adds the specified folder and all its sub-folders
%   to the MATLAB search path.
%
%   If no input argument is provided, the current working directory is used.
%
%   Example:
%       addAllFolders('C:\MyFunctions');

    % If no folder is specified, use the current working directory.
    if nargin < 1
        baseFolder = pwd();
    end

    % Add the specified folder and all its sub-folders to the MATLAB path.
    addpath(genpath(baseFolder));

    % Display a confirmation message.
    fprintf('All folders and sub-folders under:\n%s\nhave been added to the MATLAB path.\n', baseFolder);
end
