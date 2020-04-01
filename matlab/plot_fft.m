function plot_fft(y, fs)
sig_len = length(y);
h1 = blackmanharris(sig_len);
NFFT = sig_len;

fft1 = abs(fft(y.*h1'))/NFFT;
f = linspace(0, fs, NFFT);
%fsig = round(freq/f(2));
%for i = 2:100
%	fft1(fsig*i+1) = 0;
%end
%fft1 = abs(fft(y))/sig_len;
loglog(f(1:round(NFFT/2)), fft1(1:round(NFFT/2)), '-s');
grid on;
end
