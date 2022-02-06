`default_nettype none

module spdif_frame_encoder #(parameter audio_width = 24)(
    input wire clk128,
    input wire reset,
    input wire i_valid,
    output wire i_ready,
    input wire i_is_left,
    input wire [audio_width-1:0] i_audio,
    input wire i_user,
    input wire i_control,
    output reg [8:0] next_sub_frame_number,
    output wire spdif);

    reg [26:0] data;
    reg is_valid_data;
    reg [3:0] stage;
    reg [3:0] stage_data;
    reg parity;

    assign i_ready = !is_valid_data;

    wire o_valid_bmc = is_valid_data;
    wire o_ready_bmc;
    wire is_underrun;
    spdif_bmc_encoder #(.width(4)) bmc_encoder_(
        .clk128(clk128), .reset(reset), .i_valid(o_valid_bmc), .i_ready(o_ready_bmc),
        .i_data(stage_data), .is_underrun(is_underrun), .q(spdif));

	function [23:0] getAlignAudio(input [audio_width-1:0] audio);
		localparam [23:0] ZERO = 0;
		if (audio_width > 24)
			getAlignAudio = audio[audio_width - 1:audio_width - 24];
		else if (audio_width < 24)
			getAlignAudio = { audio, ZERO[23 - audio_width:0] };
		else
			getAlignAudio = audio;
	endfunction

    wire is_sub_frame_left = !next_sub_frame_number[0];
    wire is_frame_start = !(|next_sub_frame_number);

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            data <= 0;
            is_valid_data <= 1'b0;
            stage <= 0;
            parity <= 1'b0;
            stage_data <= 0;
            next_sub_frame_number <= 0;
        end else if (is_valid_data) begin
            if (o_ready_bmc) begin
                case (stage)
                4'b0000: begin 
                    stage_data <= is_frame_start ? 4'b1100 : (is_sub_frame_left ? 4'b0011 : 4'b0110);
                    next_sub_frame_number <= next_sub_frame_number == 9'd383 ? 1'b0 : (next_sub_frame_number + 1'd1);
                end
                4'b1110: stage_data <= { 1'b1, data[0], 1'b1, parity ^ ^data[0] };
                4'b1111: is_valid_data <= 1'b0;
                default:
                    begin
                        parity <= parity ^ ^data[1:0];
                        stage_data <= { 1'b1, data[0], 1'b1, data[1] };
                        data <= data >> 2;
                    end
                endcase
                stage <= stage + 1'b1;
            end
        end else begin
            if (/* i_ready && */ i_valid) begin
                if (is_sub_frame_left == i_is_left) begin
                    data <= { i_control, i_user, 1'b0 /* valid bit */, getAlignAudio(i_audio) };
                    parity <= 0;
                    stage_data <= 4'b1001;
                    stage <= 0;
                    is_valid_data <= 1'b1;
                end
            end else begin
                is_valid_data <= 1'b0;
            end
        end
        if (is_underrun)
            next_sub_frame_number <= 0;
    end

endmodule
