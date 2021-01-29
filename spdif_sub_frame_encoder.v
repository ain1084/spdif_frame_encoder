module spdif_sub_frame_encoder(
    input wire clk128,
    input wire reset,
    input wire i_valid,
    output wire i_ready,
    input wire i_is_frame_start,
    input wire i_is_left,
    input wire [23:0] i_audio,
    input wire i_user,
    input wire i_control,
    output wire is_underrun,
    output wire spdif);

    reg [26:0] data;
    reg is_data_valid;
    reg [4:0] stage;
    reg [3:0] stage_data;
    reg parity;
    reg is_data_frame_start;
    reg is_data_left;

    reg o_valid_bmc;
    wire o_ready_bmc;
    spdif_bmc_encoder #(.width(4)) bmc_encoder_(
        .clk128(clk128), .reset(reset), .i_valid(o_valid_bmc), .i_ready(o_ready_bmc),
        .i_data(stage_data), .is_underrun(is_underrun), .q(spdif));

    assign i_ready = !is_data_valid;

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            data <= 0;
            is_data_valid <= 1'b0;
            stage <= 0;
            parity <= 1'b0;
            is_data_frame_start <= 1'b0;
            is_data_left <= 1'b0;
            stage_data <= 0;
            o_valid_bmc <= 1'b0;
        end else if (is_data_valid && o_ready_bmc) begin
            if (stage == 5'b0000) begin
                parity <= 0;
                stage_data <= 4'b1001;
                is_data_valid <= 1'b1;
                o_valid_bmc <= 1'b1;
                stage <= stage + 1'b1;
            end else if (stage[3:0] == 4'b0001) begin
                parity <= 0;
                stage_data <= is_data_frame_start ? 4'b1100 : (is_data_left ? 4'b0011 : 4'b0110);
                is_data_valid <= 1'b1;
                o_valid_bmc <= 1'b1;
                stage <= stage + 1'b1;
            end else if (stage[3:0] == 4'b1111) begin
                parity <= 0;
                stage_data <= { 1'b1, data[0], 1'b1, parity ^ ^data[0] };
                is_data_valid <= 1'b1;
                o_valid_bmc <= 1'b1;
                stage <= stage + 1'b1;
            end else if (stage[4] == 1'b1) begin
                parity <= 0;
                stage_data <= 0;
                is_data_valid <= 1'b0;
                o_valid_bmc <= 1'b0;
                stage <= 0;
            end else begin
                stage_data <= { 1'b1, data[0], 1'b1, data[1] };
                parity <= parity ^ ^data[1:0];
                data <= data >> 2;
                is_data_valid <= 1'b1;
                o_valid_bmc <= 1'b1;
                stage <= stage + 1'b1;
            end
        end else if (i_ready && i_valid) begin
            data <= { i_control, i_user, 1'b0 /* valid bit */, i_audio };
            is_data_frame_start <= i_is_frame_start;
            is_data_left <= i_is_left;
            is_data_valid <= 1'b1;
        end
    end

endmodule
