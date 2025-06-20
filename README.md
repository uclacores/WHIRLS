# WHIRLS
A DSP method for Wideband High-Resolution Labeling of Signals for Spectrum Sensing Applications

# Main files

`demo.m`: Main file to demonstrate how to use WHIRLS algorithm.

`generateLabels.m`: The main file for WHIRLS algorithm to generate time and frequency labels for all transmissions in a given wideband signal segment.

# Functions

`findTransmissions.m`: The function to detect all transmissions in time-domain.

`findFreqs.m`: The function to estimate the frequency parameters of a single transmission.

`freqFilter.m`: The function to bandpass/bandstop filter a signal.

`findStart.m`: The function to detect the first transmission start in a given signal segment.

`findEnd.m`: The functino to detect the first transmission end in a given signal segment, assuming the signal already starts with a transmission.
