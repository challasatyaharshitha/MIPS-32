`timescale 1ns / 1ps

module tb();

   //declarations
    reg clk1, clk2;
    integer i;

    //instatiation
    MIPS_Wrapper dut (
        .clk1(clk1),
        .clk2(clk2)
    );

  
    initial begin
        clk1 = 0;
        clk2 = 0;
    end

    // 10ns clocks (both same phase for simplicity)
    always #5 clk1 = ~clk1;
    always #5 clk2 = ~clk2;

    
    initial begin
        $dumpfile("mips_wrapper.vcd");
        $dumpvars(0, tb);   // fixed module name

        // Reset memory
        for (i = 0; i < 1024; i = i + 1)
            dut.Mem[i] = 32'd0;

        // Reset registers
        for (i = 0; i < 32; i = i + 1)
            dut.register[i] = 32'd0;

        // Initial processor state
        dut.PC = 0;
        dut.halted = 0;
        dut.branch_taken = 0;

      

        // R1 = 5
        dut.Mem[0] = {6'b001010, 5'd0, 5'd1, 16'd5};

        // R2 = 10
        dut.Mem[1] = {6'b001010, 5'd0, 5'd2, 16'd10};

        // R3 = R1 + R2 = 15
        dut.Mem[2] = {6'b000000, 5'd1, 5'd2, 5'd3, 11'd0};

        // Mem[20] = R3
        dut.Mem[3] = {6'b001001, 5'd3, 5'd0, 16'd20};

        // R4 = Mem[20]
        dut.Mem[4] = {6'b001000, 5'd0, 5'd4, 16'd20};

        // Branch if R4 == 0 (won't happen)
        dut.Mem[5] = {6'b001110, 5'd4, 5'd0, 16'd2};

        // R5 = 1
        dut.Mem[6] = {6'b001010, 5'd0, 5'd5, 16'd1};

        // Stop execution
        dut.Mem[7] = {6'b111111, 26'd0};

        $display("=== Simulation Started ===");
    end

    
    always @(posedge clk1) begin
        $display("PC=%0d | IF=%h | ID=%h | EX=%h | MEM=%h | HALT=%b",
                 dut.PC,
                 dut.IF_ID_IR,
                 dut.ID_EX_IR,
                 dut.EX_MEM_IR,
                 dut.MEM_WB_IR,
                 dut.halted);
    end

   //stop cond
    always @(posedge clk1) begin
        if (dut.halted) begin
            $display("=== Program Finished ===");
            #20;
            $finish;
        end
    end

endmodule