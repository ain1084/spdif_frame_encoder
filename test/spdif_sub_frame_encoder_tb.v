`timescale 1 ns / 1 ns
`default_nettype none

module spdif_sub_frame_encoder_tb();

    parameter STEP = 1000000000 / (44100 * 128);
        
    reg clk128;
    initial begin
        $dumpfile("spdif_sub_frame_encoder_tb.vcd");
        $dumpvars;

        clk128 = 1'b0;
        forever #(STEP / 2) clk128 = ~clk128;
    end

    reg reset;
    reg i_valid;
    wire i_ready;
    wire is_underrun;
    reg [23:0] audio;
    reg is_frame_start;
    reg is_left;
    reg u;
    reg c;
    wire spdif;

    spdif_sub_frame_encoder encoder_inst(
        .clk128(clk128), .reset(reset), .i_valid(i_valid), .i_ready(i_ready),
        .i_is_frame_start(is_frame_start), .i_is_left(is_left),
        .i_audio(audio), .i_user(u), .i_control(c), .spdif(spdif));

    spdif_decoder_tb decoder_inst(
        .clk128(clk128), .reset(reset), .spdif(spdif));

    initial begin

        // reset
        reset = 1'b1;
        audio <= 0;
        is_frame_start <= 1'b1;
        is_left <= 1'b0;
        u <= 1'b0;
        c <= 1'b0;
        i_valid <= 1'b0;
        repeat (2) @(posedge clk128) reset <= 1'b1;
        repeat (2) @(posedge clk128) reset <= 1'b0;

        // sub-frame 1
        audio <= 24'hFFFFF8;
        is_frame_start <= 1'b1;
        is_left <= 1'b1;
        u <= 1'b1;
        c <= 1'b1;
        i_valid <= 1'b1;
        wait (i_ready) @(posedge clk128);
        i_valid <= 1'b0;
        @(posedge clk128);

        // sub-frame 2
        audio <= 24'h123456;
        is_frame_start <= 1'b0;
        is_left <= 1'b0;
        u <= 1'b0;
        c <= 1'b0;
        i_valid <= 1'b1;
        wait (i_ready) @(posedge clk128);
        i_valid <= 1'b0;
        @(posedge clk128);

        // sub-frame 3
        audio <= 24'h987655;
        is_frame_start <= 1'b0;
        is_left <= 1'b1;
        u <= 1'b0;
        c <= 1'b0;
        i_valid <= 1'b1;
        wait (i_ready) @(posedge clk128);
        i_valid <= 1'b0;
        @(posedge clk128);

        repeat (64 + 4) @(posedge clk128);

        $finish;
    end

endmodule
