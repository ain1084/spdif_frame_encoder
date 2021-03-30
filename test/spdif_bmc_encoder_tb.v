`timescale 1 ns / 1 ns
`default_nettype none

module spdif_bmc_encoder_tb();

    parameter STEP = 1000000000 / (44100 * 128);

    initial begin
        $dumpfile("spdif_bmc_encoder_tb.vcd");
        $dumpvars(0, bmc_encoder_);
    end
        
    reg mclk;
    initial begin
        mclk = 1'b0;
        forever #(STEP / 2) mclk = ~mclk;
    end

    reg reset;
    reg i_valid;
    wire i_ready;
    wire is_underrun;
    reg [3:0] data;
    wire spdif;
    spdif_bmc_encoder bmc_encoder_(
        .clk128(mclk), .reset(reset), .i_valid(i_valid), .i_ready(i_ready), .i_data(data), .is_underrun(is_underrun), .q(spdif));
    spdif_decoder_tb decoder_tb_(
        .clk128(mclk), .reset(reset), .spdif(spdif));

    task output_with_wait(input reg [3:0] w_data);
        begin
            i_valid <= 1'b1;
            data <= w_data;
            wait (i_ready) @(posedge mclk);    // transfer
            i_valid <= 1'b0;
            @(posedge mclk);
        end
    endtask

    task output_with_wait_multi(input [3:0] data1, input [3:0] data2);
        begin
            i_valid <= 1'b1;
            data <= data1;
            wait (i_ready) @(posedge mclk);    // transfer
            @(posedge mclk);
            data <= data2;
            wait (i_ready) @(posedge mclk);    // transfer (burst)
            i_valid <= 1'b0;
            @(posedge mclk);
        end
    endtask

    initial begin

        // reset
        reset = 1'b0;
        i_valid = 1'b0;
        repeat (2) @(posedge mclk) reset = 1'b1;
        @(posedge mclk) reset <= 1'b0;
        repeat (4) @(posedge mclk);

        output_with_wait_multi(4'h9, 4'hC);
//      output_with_wait(4'hC);
        output_with_wait(4'hA);
        output_with_wait(4'hA);
        output_with_wait(4'hA);
        output_with_wait(4'hA);
        output_with_wait(4'hE);
        output_with_wait(4'hA);
        output_with_wait(4'hE);
        output_with_wait(4'hB);
        output_with_wait(4'hE);
        output_with_wait(4'hB);
        output_with_wait(4'hA);
        output_with_wait(4'hB);
        output_with_wait(4'hA);
        output_with_wait(4'hA);

        repeat (64) @(posedge mclk);

        $finish;

    end

endmodule
