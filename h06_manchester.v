
module h06_manchester (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    input  wire [7:0] uio_in,
    output wire [7:0] uo_out
);

    reg [7:0] data_reg;
    reg       convention;
    reg       busy;
    reg       half_phase;
    reg [2:0] bit_index;

    wire current_bit;
    wire first_half;
    wire manchester_out;

    assign current_bit = data_reg[bit_index];

    // Quy uoc 0: bit 0 = 01, bit 1 = 10
    // Quy uoc 1: dao nguoc quy uoc 0
    assign first_half = current_bit ^ convention;

    // half_phase = 0: nua dau
    // half_phase = 1: nua sau
    assign manchester_out =
        half_phase ? ~first_half : first_half;

    assign uo_out[0] = busy ? manchester_out : 1'b0;
    assign uo_out[1] = busy;
    assign uo_out[7:2] = 6'b000000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg   <= 8'b0;
            convention <= 1'b0;
            busy       <= 1'b0;
            half_phase <= 1'b0;
            bit_index  <= 3'd7;
        end else begin
            if (!busy) begin
                if (uio_in[0]) begin
                    data_reg   <= ui_in;
                    convention <= uio_in[1];
                    bit_index  <= 3'd7;
                    half_phase <= 1'b0;
                    busy       <= 1'b1;
                end
            end else begin
                if (!half_phase) begin
                    half_phase <= 1'b1;
                end else begin
                    half_phase <= 1'b0;

                    if (bit_index == 3'd0) begin
                        busy <= 1'b0;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                    end
                end
            end
        end
    end

endmodule
