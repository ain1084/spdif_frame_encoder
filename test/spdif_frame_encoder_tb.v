`timescale 1 ns / 1 ns
`default_nettype none

module spdif_frame_encoder_tb();

    parameter STEP = 1000000000 / (44100 * 128);
        
    reg clk128;
    initial begin
        $dumpfile("spdif_frame_encoder_tb.vcd");
        $dumpvars;

        clk128 = 1'b0;
        forever #(STEP / 2) clk128 = ~clk128;
    end

    reg reset;
    reg i_valid;
    wire i_ready;
    wire is_underrun;
    reg [23:0] audio;
    reg is_left;
    reg u;
    reg c;
    wire spdif;

    spdif_frame_encoder encoder_inst(
        .clk128(clk128), .reset(reset), .i_valid(i_valid), .i_ready(i_ready),
        .i_is_left(is_left),
        .i_audio(audio), .i_user(u), .i_control(c), .next_sub_frame_number(), .spdif(spdif));

    spdif_decoder_tb decoder_inst(
        .clk128(clk128), .reset(reset), .spdif(spdif));


    task output_with_wait(input w_is_left, input w_u, input w_c, input [23:0] w_audio);
        begin
            audio <= w_audio;
            is_left <= w_is_left;
            u <= w_u;
            c <= w_c;
            i_valid <= 1'b1;
            wait (i_ready) @(posedge clk128);    // transfer
            i_valid <= 1'b0;
            @(posedge clk128);
        end
    endtask

    initial begin

        // reset
        reset = 1'b1;
        audio <= 0;
        is_left <= 1'b0;
        u <= 1'b0;
        c <= 1'b0;
        i_valid <= 1'b0;
        repeat (2) @(posedge clk128) reset <= 1'b1;
        repeat (2) @(posedge clk128) reset <= 1'b0;

        // sub-frame 1
        output_with_wait(1'b1, 1'b1, 1'b1, 24'hFFFFF8);

        // repeat (128 + 4) @(posedge clk128);

        // sub-frame 2
        output_with_wait(1'b0, 1'b0, 1'b0, 24'h123456);

        // sub-frame 3
        output_with_wait(1'b1, 1'b0, 1'b0, 24'h987655);

        repeat (64 + 8) @(posedge clk128);

        $finish;
    end

endmodule
