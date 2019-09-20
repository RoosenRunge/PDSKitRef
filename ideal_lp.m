function hd = ideal_lp(wc, L)
% Ideal low pass filter
% wc = cutoff frequency
% L = length of the window
%Wcnorm = wc/pi;
M=L-1;
alpha = (M)/2;
n = 0:(M);
m = n - alpha+1e-8;
%hd = Wcnorm*sinc(Wcnorm*m);
hd=sin(wc*m)./(pi*m);
