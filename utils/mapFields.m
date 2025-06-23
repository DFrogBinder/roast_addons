function [e1r,e2r] = mapFields(nodes1, elems1, ef1, nodes2, elems2, ef2, spacing)
  % MATCHEFIELDS  Sample two tetrahedral fields onto the same regular grid
  %
  % [E1R,E2R] = MATCHEFIELDS(N1,E1,F1,N2,E2,F2,SPACING)
  %   1) Builds a regular 3D grid covering both meshes with resolution SPACING.
  %   2) Rasterises each field onto that grid via mesh2grid.
  %   3) Interpolates both grid‐fields back onto mesh1’s nodes.

  if nargin<7 || isempty(spacing)
    % automatic ~50‐voxel resolution on the smallest bbox edge:
    bb = max(nodes1)-min(nodes1);
    spacing = min(bb)/50;
  end

  % 1) make grid vectors
  xmin = min([nodes1(:,1); nodes2(:,1)]);
  xmax = max([nodes1(:,1); nodes2(:,1)]);
  ymin = min([nodes1(:,2); nodes2(:,2)]);
  ymax = max([nodes1(:,2); nodes2(:,2)]);
  zmin = min([nodes1(:,3); nodes2(:,3)]);
  zmax = max([nodes1(:,3); nodes2(:,3)]);

  xv = xmin:spacing:xmax;
  yv = ymin:spacing:ymax;
  zv = zmin:spacing:zmax;

  % 2) build full grid arrays
  [X, Y, Z] = meshgrid(xv, yv, zv);

  % 3) rasterise each mesh+field onto that grid
  V1 = mesh2grid(nodes1, elems1, ef1, X, Y, Z);  % evaluate ef1 at grid
  V2 = mesh2grid(nodes2, elems2, ef2, X, Y, Z);  % evaluate ef2 at grid

  % 4) turn those into griddedInterpolant objects
  F1 = griddedInterpolant(X, Y, Z, V1, 'linear', 'none');
  F2 = griddedInterpolant(X, Y, Z, V2, 'linear', 'none');

  % 5) sample both back at mesh1’s nodes
  e1r = F1(nodes1(:,1), nodes1(:,2), nodes1(:,3));
  e2r = F2(nodes1(:,1), nodes1(:,2), nodes1(:,3));
end

