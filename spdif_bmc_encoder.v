`default_nettype none

module spdif_bmc_encoder #(parameter width = 4)(
    input wire clk128,
    input wire reset,
    input wire i_valid,
    output wire i_ready,
    input wire [width-1:0] i_data,
    output reg is_underrun,
    output reg q);

    reg is_valid_shift;
    reg [width-1:0] shift_data;
    reg [$clog2(width-1)-1:0] shift_count;

    assign i_ready = !is_valid_shift;

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            q <= 1'b0;
            shift_count <= 0;
            is_valid_shift <= 1'b0;
            shift_data <= 0;
            is_underrun <= 1'b0;
        end else begin
            if (is_valid_shift) begin
                shift_count <= shift_count - 1'b1;
                is_valid_shift <= shift_count != 0;
                shift_data <= shift_data << 1;
                q <= q ^ shift_data[width-1];
                is_underrun <= 1'b0;
            end else begin
                if (i_valid) begin
                    is_valid_shift <= 1'b1;
                    shift_data <= i_data << 1;
                    shift_count <= width - 2;
                    q <= q ^ i_data[width-1];
                    is_underrun <= 1'b0;
                end else begin
                    is_valid_shift <= 1'b0;
                    is_underrun <= 1'b1;
                end
            end
        end
    end
endmodule
