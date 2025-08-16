# WHIRLS
A DSP method for Wideband High-Resolution Labeling of Signals for Spectrum Sensing Applications

## Main files

`demo.m`: Main file to demonstrate how to use WHIRLS algorithm.

`generateLabels.m`: The main file for WHIRLS algorithm to generate time and frequency labels for all transmissions in a given wideband signal segment.

## Functions

`findTransmissions.m`: The function to detect all transmissions in time-domain.

`findFreqs.m`: The function to estimate the frequency parameters of a single transmission.

`freqFilter.m`: The function to bandpass/bandstop filter a signal.

`findStart.m`: The function to detect the first transmission start in a given signal segment.

`findEnd.m`: The function to detect the first transmission end in a given signal segment, assuming the signal already starts with a transmission.

## Citation

If you use the WHIRLS code or any (modified) part of them, please cite our paper [1].

We test the WHIRLS algorithm on an OTA dataset, which can be accessed at: <a href="https://cores.ee.ucla.edu/downloads/datasets/uavsig/">UAVSig dataset</a>. If you use the UAVSig dataset/code or any (modified) part of them, please cite our paper [2].

## References

[1] T. Zhao, B. W. Domae, C. Steigerwald, L. B. Paradis, T. Chabuk and D. Cabric, "WHIRLS: Wideband High-Resolution Labeling of Signals for Spectrum Sensing Applications," accepted to MILCOM 2025, 2025.
```bibtex
@misc{WHIRLS2025,
  author       = {Zhao, Tianyi and Domae, Benjamin W. and Steigerwald, Connor and Paradis, Luke B. and Chabuk, Tim and Cabric, Danijela},
  title        = {WHIRLS: Wideband High-Resolution Labeling of Signals for Spectrum Sensing Applications},
  year         = {2025},
  howpublished = {accepted to MILCOM 2025}, 
}
```

[2] T. Zhao, B. W. Domae, C. Steigerwald, L. B. Paradis, T. Chabuk and D. Cabric, "Drone RF Signal Detection and Fingerprinting: UAVSig Dataset and Deep Learning Approach," MILCOM 2024 - 2024 IEEE Military Communications Conference (MILCOM), Washington, DC, USA, 2024, pp. 431-436, doi: 10.1109/MILCOM61039.2024.10773837.
```bibtex
@INPROCEEDINGS{UAVSig2024,
  author    = {Zhao, Tianyi and Domae, Benjamin W. and Steigerwald, Connor and Paradis, Luke B. and Chabuk, Tim and Cabric, Danijela},
  booktitle = {MILCOM 2024 - 2024 IEEE Military Communications Conference (MILCOM)}, 
  title     = {Drone RF Signal Detection and Fingerprinting: UAVSig Dataset and Deep Learning Approach}, 
  year      = {2024},
  pages     = {431-436},
  doi       = {10.1109/MILCOM61039.2024.10773837}}
```

