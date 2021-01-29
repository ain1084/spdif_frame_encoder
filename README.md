# spdif_encoder
S/PDIF encoder

![spdif_encoder](https://user-images.githubusercontent.com/14823909/106313479-9e517400-62ab-11eb-9b72-e70e1a751065.png)

|Name|Direction|Description|
|--|--|--|
|reset|input|reset signal (active high)|
|clk128|input|x128Fs clock (Eg. Fs:44100Hz = 5.6448MHz)|
|i_valid|input|Data valid|
|i_audio[23:0]|input|PCM audio data|
|i_is_left|input|i_audio channel (0: right / 1: left)|
|i_user|input|Value of sub frame 'U' bit|
|i_control|input|Value of sub frame 'C' bit|
|sub_frame_number[8:0]|output|Current sub frame number (0-383)|
|i_ready|output|Data incoming ready|
|spdif|output|S/PDIF signal output|
