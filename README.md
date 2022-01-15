# spdif_frame_encoder
S/PDIF frame encoder

![spdif_frame_encoder](https://user-images.githubusercontent.com/14823909/149629420-517c9b49-473a-4f2e-8fc8-c6729dc98471.png)

|Name|Direction|Description|
|--|--|--|
|reset|input|reset signal (active high)|
|clk128|input|x128Fs clock (Eg. Fs:44100Hz = 5.6448MHz)|
|i_valid|input|Data valid|
|i_audio[audio_width-1:0]|input|PCM audio data (2's complement)|
|i_is_left|input|i_audio channel (0: right / 1: left)|
|i_user|input|Value of sub frame 'U' bit|
|i_control|input|Value of sub frame 'C' bit|
|sub_frame_number[8:0]|output|Current sub frame number (0-383)|
|i_ready|output|Data incoming ready|
|spdif|output|S/PDIF signal output|
