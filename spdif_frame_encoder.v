`default_nettype none

module spdif_frame_encoder #(parameter audio_width = 24)(
    input wire reset,
    input wire clk128,
    input wire i_valid,
    output wire i_ready,
    input wire i_is_left,
    input wire [audio_width-1:0] i_audio,
    input wire i_user,
    input wire i_control,
    output reg [8:0] sub_frame_number,
    output wire spdif);

    reg sub_frame_encoder_i_valid;
    wire is_underrun;

    wire is_frame_start = sub_frame_number == 9'd0;
    wire is_left_request = is_frame_start || !sub_frame_number[0];

    spdif_sub_frame_encoder #(.audio_width(audio_width)) sub_frame_encoder_inst (
        .clk128(clk128), .reset(reset), .i_valid(sub_frame_encoder_i_valid), .i_ready(i_ready),
        .i_is_frame_start(is_frame_start), .i_is_left(i_is_left),
        .i_audio(i_audio), .i_user(i_user), .i_control(i_control), .is_underrun(is_underrun), .spdif(spdif));

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            sub_frame_number <= 0;
            sub_frame_encoder_i_valid <= 0;
        end else begin
            if (!sub_frame_encoder_i_valid) begin
                if (i_valid && i_ready) begin
                    if (is_underrun)
                        sub_frame_number <= 0;
                    if (is_left_request == i_is_left)
                        sub_frame_encoder_i_valid <= 1'b1;
                end
            end else if (i_ready) begin
                sub_frame_number <= sub_frame_number == 9'd383 ? 1'b0 : (sub_frame_number + 1'd1);
                sub_frame_encoder_i_valid <= 1'b0;
            end
        end
    end
endmodule