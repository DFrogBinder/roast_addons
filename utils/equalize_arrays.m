function [E1, E2] = equalize_arrays(E1, E2, mode)
    % EQUALIZE_ARRAYS Ensures E1 and E2 have the same number of rows.
    %
    %   [E1, E2] = EQUALIZE_ARRAYS(E1, E2, MODE) either pads the shorter
    %   array with rows of NaN or truncates the longer array, depending on MODE.
    %
    %   Inputs:
    %       E1   - first array (size: nr×m)
    %       E2   - second array (size: nl×m)
    %       MODE - string flag, either:
    %                'pad'      to pad the shorter array up to the longer
    %                'truncate' to cut the longer array down to the shorter
    %
    %   Outputs:
    %       E1, E2 - modified arrays, both with the same number of rows
    %
    %   Example:
    %       [A, B] = equalize_arrays(A, B, 'pad');
    %       [A, B] = equalize_arrays(A, B, 'truncate');

    if nargin < 3
        error('You must provide three arguments: E1, E2, and mode (''pad'' or ''truncate'').');
    end

    % Number of rows in each input
    nr = size(E1, 1);
    nl = size(E2, 1);

    switch lower(mode)
        case 'pad'
            % Determine target length (the larger of the two)
            N = max(nr, nl);

            % Pad E1 if shorter
            if nr < N
                E1(nr+1:N, :) = NaN;
            end

            % Pad E2 if shorter
            if nl < N
                E2(nl+1:N, :) = NaN;
            end

        case 'truncate'
            % Determine target length (the smaller of the two)
            N = min(nr, nl);

            % Truncate E1 if longer
            if nr > N
                E1 = E1(1:N, :);
            end

            % Truncate E2 if longer
            if nl > N
                E2 = E2(1:N, :);
            end

        otherwise
            error('Invalid mode. Use ''pad'' to extend or ''truncate'' to cut down.');
    end
end
