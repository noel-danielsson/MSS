function chi_d = ILOSchi(x,y,Delta,kappa,h,U,R_switch,wpt)
% chi_d = ILOSchi(x,y,Delta,kappa,h,U,R_switch,wpt) computes the desired 
% course angle when the path is straight lines going through the waypoints
% (wpt.pos.x, wpt.pos.y). The desired course angle chi_d is computed using 
% the ILOS guidance law by Lekkas and Fossen (2014),
%
%  chi_d = pi_p - atan( Kp * y_e + Ki y_int),  Kp = 1/Delta,  Ki = kappa * Kp  
%
%  d(y_int)/dt = U * y_e / sqrt( Delta^2 + (y_e + kappa * y_int)^2 )
%
% where pi_p is the path-tangential angle with respect to the North axis
% and y_e is the cross-track error expressed in NED.
%
% Initialization:
%   The active waypoint (xk, yk) where k = 1,2,...,n is a persistent
%   integer should be initialized to the first waypoint, k = 1, using 
%   >> clear ILOSchi
%
% Inputs:   
%   (x,y), craft North-East positions (m)
%   Delta, positive look-ahead distance (m)
%   kappa, positive integral gain constant, Ki = kappa * Kp
%   U, speed of the craft (m/s)
%   h, sampling time (s)
%   R_switch, go to next waypoint when the along-track distance x_e 
%             is less than R_switch (m)
%   wpt.pos.x = [x1, x2,..,xn]' array of waypoints expressed in NED (m)
%   wpt.pos.y = [y1, y2,..,yn]' array of waypoints expressed in NED (m)
%
% Feasibility citerion: 
%   The switching parameter R_switch > 0 must satisfy, R_switch < dist, 
%   where dist is the distance between the two waypoints at k and k+1:
%      dist = sqrt(  (wpt.pos.x(k+1)-wpt.pos.x(k))^2 
%                  + (wpt.pos.y(k+1)- wpt.pos.y(k))^2 );
%
% Outputs:  
%    chi_d, desired course angle (rad)
%
% For heading control use the functions LOSpsi.m and ILOSpsi.m.
%
% Ref. A. M. Lekkas and T. I. Fossen (2014). Integral LOS Path Following 
% for Curved Paths Based on a Monotone Cubic Hermite Spline Parametrization. 
% IEEE Transactions on Control Systems Technology 22(6), 2287–2301.
%  
% Author:    Thor I. Fossen
% Date:      2 June 2021
% Revisions: 

persistent k;      % active waypoint index (initialized by: clear LOSchi)
persistent xk;     % active waypoint (xk, yk) corresponding to integer k
persistent yk;
persistent y_int;  % integral state

%% Initialization of (xk, yk) and (xk_next, yk_next), and integral state 
if isempty(k)   
  
    % check if R_switch is smaller than the minimum distance between the waypoints
    if R_switch > min( sqrt( diff(wpt.pos.x).^2 + diff(wpt.pos.y).^2 ) )
        error("The distances between the waypoints must be larger than R_switch");
    end
    
    % check input parameters
    if (R_switch < 0)
        error("R_switch must be larger than zero");
    end
    if (Delta < 0)
        error("Delta must be larger than zero");
    end    
    if (U < 0)
        error("U must be larger than zero");
    end      
    
    y_int = 0;              % integral state
        
    k = 1;                  % set first waypoint as the active waypoint
    xk = wpt.pos.x(k);
    yk = wpt.pos.y(k);     
end

%% Read next waypoint (xk_next, yk_next) from wpt.pos 
n = length(wpt.pos.x);
if k < n                        % if there are more waypoints, read next one 
    xk_next = wpt.pos.x(k+1);  
    yk_next = wpt.pos.y(k+1);    
else                            % else, use the last one in the array
    xk_next = wpt.pos.x(end);
    yk_next = wpt.pos.y(end); 
end

%% Print active waypoint 
fprintf('Active waypoint:\n')
fprintf('  (x%1.0f, y%1.0f) = (%.2f, %.2f) \n',k,k,xk,yk);

%% Compute the desired course angle
pi_p = atan2(yk_next-yk, xk_next-xk);  % path-tangential angle w.r.t. to North

% along-track and cross-track errors (x_e, y_e) expressed in NED
x_e =  (x-xk) * cos(pi_p) + (y-yk) * sin(pi_p);
y_e = -(x-xk) * sin(pi_p) + (y-yk) * cos(pi_p);

% if the next waypoint satisfy the switching criterion, k = k + 1
d = sqrt( (xk_next-xk)^2 + (yk_next-yk)^2 );
if ( (d - x_e < R_switch) && (k < n) )
    k = k + 1;
    xk = xk_next;       % update active waypoint
    yk = yk_next; 
end

% ILOS guidance law
Kp = 1/Delta;
Ki = kappa * Kp;
chi_d = pi_p - atan( Kp * y_e + Ki * y_int );

% Euler integration
y_int = y_int + h * U * y_e / sqrt( Delta^2 + (y_e + kappa * y_int)^2 );

end

