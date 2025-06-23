function [nodeID, E] = load_pos_data(filepath)
%LOAD_POS_DATA  Load per-node electric field from a .pos file
%   [nodeID, E] = load_pos_data(filepath) reads either
%     • simple format: 
%         Line 1 = N  (number of nodes)
%         Lines 2–N+1 = idx Ex Ey Ez
%       or
%     • Gmsh style:
%         header up to “{”
%         inside braces: idx, Ex, Ey, Ez,
%
%   Returns:
%     nodeID = N×1 vector of node indices
%     E      = N×3 matrix of [Ex, Ey, Ez]

    fid = fopen(filepath, 'rt');
    if fid<0
        error('Could not open file: %s', filepath);
    end

    firstLine = fgetl(fid);
    if ~ischar(firstLine)
        fclose(fid);
        error('File is empty: %s', filepath);
    end

    % Does first line consist solely of an integer count?
    trimmed = strtrim(firstLine);
    if ~isempty(regexp(trimmed, '^\d+$', 'once'))
        % --- Simple count + whitespace-delimited rows ---
        % Now read the remaining lines as four whitespace-delimited floats
        C = textscan(fid, '%f %f %f %f', 'CollectOutput', true);
    else
        % --- Gmsh brace style: skip until “{” ---
        tline = firstLine;
        while ischar(tline) && ~contains(tline, '{')
            tline = fgetl(fid);
        end
        if ~ischar(tline)
            fclose(fid);
            error('Unrecognized .pos format: no node count or “{” found in %s', filepath);
        end
        % Read until closing brace; allow commas or whitespace as delimiters
        C = textscan(fid, '%f %f %f %f', ...
                     'Delimiter', {',',' ','\t'}, ...
                     'CollectOutput', true, ...
                     'CommentStyle', '}');
    end

    fclose(fid);

    if isempty(C) || isempty(C{1})
        error('No numeric data found in %s', filepath);
    end

    data   = C{1};    % N×4
    nodeID = data(:,1);
    E      = data(:,2:4);
end
