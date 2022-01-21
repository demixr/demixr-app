# Demixr mobile application

> Music source separation on mobile

<p align="center">
	<img src="doc/screens.png" />
</p>

![Version badge](https://img.shields.io/github/v/release/demixr/demixr-app?color=orange&label=version&style=for-the-badge)
![Github build badge](https://img.shields.io/github/workflow/status/demixr/demixr-app/Build%20and%20release%20app?style=for-the-badge)



> :warning: This project is still in development, all the features might not work perfectly yet


| Platform | Support            |
| -------- | ------------------ |
| Android  | :white_check_mark: |
| IOS      | Coming soon        |



## Music source separation

> <TODO>



## Features

* Load songs from the device
  * Supported formats: `mp3` and `wav`
* Download songs from Youtube
* Source separation in 4 different stems: `Vocals`, `Bass`, `Drums` and `Other`
* Local library of unmixed songs
* Integrated music player with the ability to mute / unmute each stem



## Demixing

The **demixing** is made using `Pytorch Mobile` and a source separation model optimized for mobile.



### Models

[Open-Unmix](https://github.com/sigsep/open-unmix-pytorch) is a deep neural network reference implementation for music source separation in [Pytorch](https://pytorch.org/).

The models are trained on the [MUSDB18](https://sigsep.github.io/datasets/musdb.html) dataset.




Two of the models are available in the application:

| Model   | Description                                                  |
| ------- | ------------------------------------------------------------ |
| `umxl`  | A model that was trained on extra data which significantly improves the performance, especially generalization. |
| `umxhq` | Default model trained on [MUSDB18-HQ](https://sigsep.github.io/datasets/musdb.html#uncompressed-wav), which comprises the same tracks as in MUSDB18 but un-compressed which yield in a full bandwidth of 22050 Hz. |


In order to use the models on mobile, they are transformed to [torchscript](https://pytorch.org/docs/stable/jit.html) then optimized for mobile and for the `Pytorch Mobile` lite interpreter: https://github.com/demixr/openunmix-torchscript.



Latest mobile build of the models: https://github.com/demixr/openunmix-torchscript/releases/latest/.



## Download Demixr

You can download and install the Android application from the [latest Github release](https://github.com/demixr/demixr-app/releases/latest/) by selecting the appropriate platform `apk` file.



## Contributing

> <TODO>
