`timescale 1ns / 1ns
`default_nettype none

module spdif_decoder_tb(
    input wire clk128, input wire reset, input wire spdif);

    function [3:0] swap_4bit(input [0:3] in);
    begin
        swap_4bit = { in[3], in[2], in[1], in[0] };
    end
    endfunction

    reg stage;
    reg [7:0] count;
    reg error;
    reg [63:0] sub_frame_data;
    reg [0:27] decoded_sub_frame;
    reg is_filled_preamble;
    reg [7:0] preamble;
    reg [8:0] sub_frame_number;
    always @(posedge clk128 or posedge reset) begin
        if (reset) begin
            sub_frame_data = 0;
            preamble = 0;
            error = 0;
            decoded_sub_frame = 0;
            is_filled_preamble = 0;
            preamble = 0;
            stage = 0;
            count = 0;
            sub_frame_number = 0;
        end else begin
            sub_frame_data = { sub_frame_data[62:0], spdif };
            preamble = { sub_frame_data[7:0] };
            if (!is_filled_preamble && count < 8)
                count = count + 1;
            if (count == 8)
                is_filled_preamble = 1;

            if (is_filled_preamble) begin
                case (stage)
                    0: begin
                        case (preamble)
                            8'b11101000: begin
                                sub_frame_number = 0;
                                $write("#%03d B:", sub_frame_number);
                                ++sub_frame_number;
                                stage = 1;
                            end
                            8'b11100010: begin
                                $write("#%03d M:", sub_frame_number);
                                ++sub_frame_number;
                                stage = 1;
                            end
                            8'b11100100: begin
                                $write("#%03d W:", sub_frame_number);
                                ++sub_frame_number;
                                stage = 1;
                            end
                            //default: begin
                            //    if (!error) begin
                            //        $write("unknown preamble: %08b\n", preamble);
                            //        error = 1;
                            //    end
                            //end
                        endcase
                    end
                    1: begin
                        count = count + 1;
                        if (count[0] == 0) begin
                            decoded_sub_frame = { decoded_sub_frame[1:27], ^sub_frame_data[1:0] };
                        end
                        if (count == 64) begin
                            $write("%064b %028b <Aux:%h Sample:%h%h%h%h%h V:%b U:%b C:%b P:%b>",
                                sub_frame_data[63:0], decoded_sub_frame,
                                swap_4bit(decoded_sub_frame[0:3]),        // aux
                                swap_4bit(decoded_sub_frame[20:23]),      // audio 19-16
                                swap_4bit(decoded_sub_frame[16:19]),      // audio 15-12
                                swap_4bit(decoded_sub_frame[12:15]),      // audio 11- 8
                                swap_4bit(decoded_sub_frame[ 8:11]),      // audio  7- 4
                                swap_4bit(decoded_sub_frame[ 4: 7]),      // audio  3- 0
                                decoded_sub_frame[24], decoded_sub_frame[25], decoded_sub_frame[26], decoded_sub_frame[27]); 
                            if (^decoded_sub_frame == 0)
                                $write("\n");
                            else
                                $write(" parity error\n");
                            stage = 0;
                            count = 0;
                            error = 0;
                            is_filled_preamble = 0;
                        end
                    end
                endcase
            end
        end
    end
endmodule
