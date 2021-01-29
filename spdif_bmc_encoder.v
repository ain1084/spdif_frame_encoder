module spdif_bmc_encoder #(parameter width = 4)(
    input wire clk128,
    input wire reset,
    input wire i_valid,
    output wire i_ready,
    input wire [width-1:0] i_data,
    output reg is_underrun,
    output reg q);


    reg [$clog2(width)-1:0] shift_count;

    reg is_valid_shift;
    reg [width-1:0] shift_data;

    reg is_valid_next;
    reg [width-1:0] next_data;

    assign i_ready = !is_valid_shift || !is_valid_next;

    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            q <= 1'b0;
            shift_count <= 0;
            is_valid_shift <= 1'b0;
            shift_data <= 0;
            is_valid_next <= 1'b0;
            next_data <= 0;
            is_underrun <= 1'b0;
        end else begin
            if (is_valid_shift) begin
                if (&shift_count) begin
                    if (is_valid_next) begin
                        shift_data <= next_data;
                        is_valid_next <= 1'b0;
                        is_underrun <= 1'b0;
                    end else begin
                        if (i_valid) begin
                            shift_data <= i_data;
                            is_underrun <= 1'b0;
                        end else begin
                            is_valid_shift <= 1'b0;
                            is_underrun <= 1'b1;
                            shift_data <= shift_data << 1;
                        end
                    end
                end else begin 
                    if (i_valid && !is_valid_next) begin
                        next_data <= i_data;
                        is_valid_next <= 1'b1;
                    end
                    shift_data <= shift_data << 1;
                    is_underrun <= 1'b0;
                end
                shift_count <= shift_count + 1'b1;
                q <= q ^ shift_data[width-1];
            end else begin
                if (i_valid) begin
                    shift_data <= i_data;
                     is_valid_shift <= 1'b1;
                    is_underrun <= 1'b0;
                end
            end
        end
    end
endmodule
