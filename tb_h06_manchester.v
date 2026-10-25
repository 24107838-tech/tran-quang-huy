`timescale 1ns/1ps

module tb_h06_manchester;

    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;

    integer errors;

    h06_manchester dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] data;
        input conv;
        integer i;
        reg first_value;
        begin
            @(negedge clk);
            ui_in  = data;
            uio_in = {6'b0, conv, 1'b1};

            @(negedge clk);
            uio_in[0] = 1'b0;

            wait (uo_out[1] == 1'b1);
            #1;

            for (i = 7; i >= 0; i = i - 1) begin
                first_value = data[i] ^ conv;

                if (uo_out[1] !== 1'b1 || uo_out[0] !== first_value) begin
                    $display("FAIL data=%02h conv=%0b bit=%0d first: uo_out=%02h",
                             data, conv, i, uo_out);
                    errors = errors + 1;
                end

                @(posedge clk);
                #1;

                if (uo_out[1] !== 1'b1 || uo_out[0] !== ~first_value) begin
                    $display("FAIL data=%02h conv=%0b bit=%0d second: uo_out=%02h",
                             data, conv, i, uo_out);
                    errors = errors + 1;
                end

                if (i > 0) begin
                    @(posedge clk);
                    #1;
                end
            end

            @(posedge clk);
            #1;

            if (uo_out[1] !== 1'b0) begin
                $display("FAIL data=%02h conv=%0b: busy did not return to 0",
                         data, conv);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("h06_manchester.vcd");
        $dumpvars(0, tb_h06_manchester);

        clk = 0;
        rst_n = 0;
        ui_in = 0;
        uio_in = 0;
        errors = 0;

        repeat (2) @(negedge clk);
        rst_n = 1;

        send_byte(8'h00, 1'b0);
        send_byte(8'h00, 1'b1);
        send_byte(8'hFF, 1'b0);
        send_byte(8'hFF, 1'b1);
        send_byte(8'hA5, 1'b0);
        send_byte(8'hA5, 1'b1);
        send_byte(8'h80, 1'b0);
        send_byte(8'h01, 1'b0);

        if (errors == 0)
            $display("PASS: all Manchester checks passed.");
        else
            $display("FAIL: %0d output checks failed.", errors);

        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "Timeout: simulation did not finish.");
    end

endmodule
