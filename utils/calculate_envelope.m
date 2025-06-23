% E_TI = Calc_TI(E1,E2,ratio,Itot,n_pref)
%
% Calculates tTIS field strengths from two unit electric fields, 
% a current ratio and a current limit, for free and preferred direction. 
% Maximum current per electrode is set to 2 mA.
%
% Inputs:
%  <E1,E2> = n_cellx3 matrices with field strength for I = 1 mA
%  <ratio> = desired ratio of input currents: I2/I1
%  <Itot> = maximum total input current in mA: I1+I2
%  [n_pref] = n_cellx3 matrix with preferred field direction vectors
%
% Outputs:
%  <E_TI> = struct with fields free and pref, both n_cellx1 vectors

function [E_TI,info] = calculate_envelope(E1,E2,ratio,Itot,n_pref)
    
%% Scale electric fields
if ~isempty(ratio)
    Iind = 2; % maximum current per electrode
    I1 = Itot / (1+ratio);
    I2 = Itot - I1;
    scale = max([Iind I1 I2]) / Iind;
    I1 = I1 / scale; % scale current so that I1 and I2 <= Iind
    I2 = I2 / scale;
    E1 = I1 * E1; % scale electric fields with input currents
    E2 = I2 * E2;
end

%% TI_pref: tTIS field strength along preferred direction
if nargin==5
    E_TI.pref = abs( abs(dot(E1 + E2,n_pref,2)) - abs(dot(E1 - E2,n_pref,2)) );
else, E_TI.pref = [];
end

%% TI_free: max tTIS field strength over all directions
% calculate norms and angles:
E1n = vecnorm(E1,2,2); E2n = vecnorm(E2,2,2);
info.TI_free.angle = acosd( dot(E1,E2,2) ./ (E1n .* E2n) ); % angle between E1 and E2
E2(info.TI_free.angle>90,:) = -E2(info.TI_free.angle>90,:); % if angle>90, flip the field
angle = acosd( dot(E1,E2,2) ./ (E1n .* E2n) ); % calculate angle after flipping

% flag elements belonging to each of 4 cases:
case11 = E1n > E2n & E2n < E1n.*cosd(angle);
case12 = E1n > E2n & E2n >= E1n.*cosd(angle);
case21 = E2n >= E1n & E1n < E2n.*cosd(angle);
case22 = E2n >= E1n & E1n >= E2n.*cosd(angle);
info.TI_free.case = 1*case11 + 2*case12 + 3*case21 + 4*case22; % store case number per element

% calculate field strengths for 4 cases:
ETIn11 = 2 * E2n;
ETIn12 = 2 * vecnorm(cross(E2,(E1-E2)),2,2) ./ vecnorm(E1-E2,2,2); 
ETIn21 = 2 * E1n; 
ETIn22 = 2 * vecnorm(cross(E1,(E2-E1)),2,2) ./ vecnorm(E2-E1,2,2); 

% combine all cases to get field strength for all elements:
ETIn = nan(length(E1n),1);
ETIn(case11) = ETIn11(case11);
ETIn(case12) = ETIn12(case12);
ETIn(case21) = ETIn21(case21);
ETIn(case22) = ETIn22(case22);
E_TI.free = ETIn;