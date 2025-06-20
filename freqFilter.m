function filtered_data = freqFilter(data, fs, flo, fhi, filter_type, wrapped_signal)
arguments
    data
    fs
    flo
    fhi
    filter_type = "bandstop"
    wrapped_signal = false
end

% Bandpass or bandstop filter a signal.
% Set wrapped_signal to true if the transmission exists on the edge of the targeted band
% (i.e., if flo and fhi are calculated by findWrappedFreqs).

if wrapped_signal
    filtered_data = fft(data);
    fft_start = max(floor(length(filtered_data)/fs*(flo)), 1);
    fft_end = min(ceil(length(filtered_data)/fs*(fhi)), length(filtered_data));
else
    filtered_data = fftshift(fft(data));
    fft_start = max(floor(length(filtered_data)/fs*(flo + fs/2)), 1);
    fft_end = min(ceil(length(filtered_data)/fs*(fhi + fs/2)), length(filtered_data));
end

if filter_type == "bandpass"
    filtered_data(1:fft_start) = filtered_data(1:fft_start)/sqrt(1e8);
    filtered_data(fft_end:end) = filtered_data(fft_end:end)/sqrt(1e8);
elseif filter_type == "bandstop"
    filtered_data(fft_start:fft_end) = filtered_data(fft_start:fft_end)/sqrt(1e8);else
    filtered_data = [];
end

if wrapped_signal
    filtered_data = ifft(filtered_data);
else
    filtered_data = ifft(fftshift(filtered_data));


end