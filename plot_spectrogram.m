function [] = plot_spectrogram(data, fs, freq_resolution, ...
                               frequency_unit, time_unit, ...
                               start_idx, end_idx, fcs, bws, ids)
arguments
    data
    fs
    freq_resolution = 1e6
    frequency_unit = 1e6
    time_unit = 1e3
    start_idx = []
    end_idx = []
    fcs = []
    bws = []
    ids = []
end
% Compute the resulted PSD and find the bandwidth accordingly.
fft_window = fs/freq_resolution;
exponents = ceil(log2(fft_window));
fft_window = 2^exponents;
fft_window = min(fft_window, length(data));
noverlap = 0;
[s, f, t] = spectrogram(data, fft_window, noverlap, fft_window, fs, 'centered');
f = f/frequency_unit;
t = t*time_unit;

fig = figure;
fig.Position = [100 200 800 600];
imagesc(t, f, 20*log10(abs(s)));
cb = colorbar();
ylabel(cb, 'Power (dB/Hz)', 'FontSize', 15);
xlabel('Time (ms)', 'FontSize', 15);
ylabel('Frequency (MHz)', 'FontSize', 15);

if ~isempty(start_idx)
    for idx=1:length(start_idx)
        cur_start = start_idx(idx);
        cur_end = end_idx(idx);
        if cur_end > length(data)
            break;
        end
        cur_bw = bws(idx);
        cur_fc = fcs(idx);
        t_cor = cur_start/fs*time_unit;
        w = (cur_end - cur_start)/fs*time_unit;
        f_cor = cur_fc-cur_bw/2;
        f_cor = f_cor/frequency_unit;
        h = cur_bw/frequency_unit;
        rectangle('Position', [t_cor, f_cor, w, h], 'EdgeColor', 'r', 'LineWidth', 1);
        if ~isempty(ids)
            text(t_cor, f_cor - 1, ids(idx), 'Color', 'r', 'FontSize', 12);
        end
    end
end