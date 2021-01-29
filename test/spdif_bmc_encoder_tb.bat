@echo off
iverilog ../spdif_bmc_encoder.v spdif_bmc_encoder_tb.v spdif_decoder_tb.v
if not errorlevel 1 (
	vvp a.out
	del a.out
)
