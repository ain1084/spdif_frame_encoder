`default_nettype none

module spdif_sub_frame_encoder #(parameter audio_width = 24)(
    input wire clk128,
    input wire reset,
    input wire i_valid,
    output wire i_ready,
    input wire i_is_frame_start,
    input wire i_is_left,
    input wire [audio_width-1:0] i_audio,
    input wire i_user,
    input wire i_control,
    output wire is_underrun,
    output wire spdif);

    reg [26:0] data;
    reg is_valid_data;
    reg [3:0] stage;
    reg [3:0] stage_data;
    reg parity;
    reg is_data_frame_start;
    reg is_data_left;

    assign i_ready = !is_valid_data;

    wire o_valid_bmc = is_valid_data;
    wire o_ready_bmc;
    spdif_bmc_encoder #(.width(4)) bmc_encoder_(
        .clk128(clk128), .reset(reset), .i_valid(o_valid_bmc), .i_ready(o_ready_bmc),
        .i_data(stage_data), .is_underrun(is_underrun), .q(spdif));

	function [26:0] loadData(input control, input user, input [audio_width-1:0] audio);
		localparam [23:0] ZERO = 0;
		if (audio_width > 24)
			loadData = { control, user, 1'b0 /* valid bit */, audio[audio_width-1:audio_width-24] };
		else if (audio_width == 24)
			loadData = { control, user, 1'b0 /* valid bit */, audio};
		else
			loadData = { control, user, 1'b0 /* valid bit */, audio, ZERO[23-audio_width:0]};
	endfunction

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            data <= 0;
            is_valid_data <= 1'b0;
            stage <= 0;
            parity <= 1'b0;
            is_data_frame_start <= 1'b0;
            is_data_left <= 1'b0;
            stage_data <= 0;
        end else if (is_valid_data) begin
            if (o_ready_bmc) begin
                case (stage)
                4'b0000: stage_data <= is_data_frame_start ? 4'b1100 : (is_data_left ? 4'b0011 : 4'b0110);
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
            if (i_valid) begin
				data <= loadData(i_control, i_user, i_audio);
                is_data_frame_start <= i_is_frame_start;
                is_data_left <= i_is_left;
                parity <= 0;
                stage_data <= 4'b1001;
                stage <= 0;
                is_valid_data <= 1'b1;
            end else begin
                is_valid_data <= 1'b0;
            end
        end
    end

endmodule
