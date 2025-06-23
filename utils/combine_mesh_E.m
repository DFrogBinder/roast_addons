function combined = combine_mesh_E(nodes_all, nodeID, envelope)
%COMBINE_MESH_E  Combine mesh nodes, E-field and tissue labels for SCIRun
%
%  combined = combine_mesh_E(nodes_all, nodeID, Eflat, outputFile)
%
%  Inputs:
%    nodes_all  : M×4 matrix of [X Y Z Label] for all mesh nodes
%    nodeID     : K×1 vector of indices (into nodes_all) where you have E-values
%    Eflat      : K×1 (or K×3) matrix of E-field values at those nodes
%    outputFile : string filename to write combined data (e.g. 'mesh_with_E.txt')
%
%  Output:
%    combined   : M×(4+size(Eflat,2)) matrix [X Y Z E… Label]
%
%  The function:
%    1) Builds a full M×P E array with NaNs where no data exist
%    2) Concatenates [X Y Z E… Label]
%    3) Writes a space-delimited text file for SCIRun

    % Validate inputs
    M = size(nodes_all,1);
    if any(nodeID<1) || any(nodeID> M)
        error('nodeID contains out-of-range indices');
    end
    % How many field components?
    P = size(envelope,2);
    
    % 1) build full E array
    fullE = nan(M, P);
    fullE(nodeID, :) = envelope;
    
    % 2) stitch together [X Y Z E… Label]
    combined = [ nodes_all(:,1:3), fullE, nodes_all(:,4) ];
    
    % % 3) write to disk
    % %    use '%.6g' for compact numeric formatting (adjust as needed)
    % fmt = [repmat('%.6g ', 1, 3+P) '%.0f\n'];
    % fid = fopen(outputFile, 'wt');
    % if fid<0
    %     error('Could not open %s for writing.', outputFile);
    % end
    % fprintf(fid, fmt, combined');
    % fclose(fid);
    % 
    % fprintf('Wrote %d rows to %s\n', M, outputFile);
end
