`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.09.2025 19:18:53
// Design Name: 
// Module Name: MIPS_Wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MIPS_Wrapper(input clk1,
                    input clk2);
reg [31:0] PC, IF_ID_IR, IF_ID_NPC; //IF _ID
reg [31:0] ID_EX_IR, ID_EX_A,ID_EX_B,ID_EX_Imm, ID_EX_NPC; // ID_EX
reg [31:0] EX_MEM_ALUout,EX_MEM_B,EX_MEM_IR; // EX_MEM
reg EX_MEM_cond; // single bit(for branch instruction)
reg [31:0] MEM_WB_ALUout,MEM_WB_LMD,MEM_WB_IR;// MEM_WB
reg [31:0]register[31:0]; // Register bank
reg [31:0]Mem[1024:0]; // Memory
reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; // to specify type of instr (RR,RI,LD,STR,BRCH)

parameter ADD=6'b000000, SUB=6'B000001, AND=6'B000010, OR=6'B000011, 
          SLT=6'B000100, MUL=6'B000101, HLT=6'B111111, LW=6'B001000,
          SW=6'B001001, ADDI=6'B001010, SUBI=6'B001011, SLTI=6'B001100,
          BNEQZ=6'B001101, BEQZ=6'B001110;
          
parameter RR_ALU=3'B000, RM_ALU=3'B001, LOAD=3'B010, STORE=3'B011, BRANCH=3'B100, HALT=3'B101;

reg halted;
reg branch_taken;

//Stage 1 : Instruction Fetch
always@(posedge clk1)
if(halted == 0)
    begin
        if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
            ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
            begin
            IF_ID_IR    <= #2 Mem[EX_MEM_ALUout];
            IF_ID_NPC   <= #2 EX_MEM_ALUout + 1;
            PC          <= #2 EX_MEM_ALUout + 1;
            branch_taken <= #2 1'b1;
            end
        else
            begin
            IF_ID_IR     <= #2 Mem[PC];
            IF_ID_NPC    <= #2 PC+1;
            PC           <= #2 PC+1;
            branch_taken <= #2 1'b0;
            end        
    end
            

// Stage 2 : Instruction Decode
always@(posedge clk2)
if(halted == 0)
begin 
    if(IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
    else ID_EX_A <= #2 register[IF_ID_IR[25:21]];
    
    if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
    else ID_EX_B <= #2 register[IF_ID_IR[20:16]];
    
    ID_EX_IR <= #2 IF_ID_IR;
    ID_EX_NPC<= #2 IF_ID_NPC;
    ID_EX_Imm<= #2 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};
    
    case(IF_ID_IR[31:26])
    ADD,SUB,MUL,AND,OR,SLT: ID_EX_type <= RR_ALU;
    ADDI,SUBI,SLTI        : ID_EX_type <= RM_ALU;
    LW                    : ID_EX_type <= LOAD;
    SW                    : ID_EX_type <= STORE;
    BEQZ, BNEQZ           : ID_EX_type <= BRANCH;
    HLT                   : ID_EX_type <= HALT;
    default               : ID_EX_type <= HALT;
    endcase
end


// Stage 3 : Execute
always@(posedge clk1)
if(halted == 0)
begin
    EX_MEM_IR   <= #2 ID_EX_IR;
    EX_MEM_type <= #2 ID_EX_type;
    branch_taken<= #2 0;
    case(ID_EX_type)
    RR_ALU  : begin
                case(ID_EX_IR[31:26])
                ADD  : EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_B;
                SUB  : EX_MEM_ALUout <= #2 ID_EX_A - ID_EX_B;
                MUL  : EX_MEM_ALUout <= #2 ID_EX_A * ID_EX_B;
                AND  : EX_MEM_ALUout <= #2 ID_EX_A & ID_EX_B;
                OR   : EX_MEM_ALUout <= #2 ID_EX_A | ID_EX_B;
                SLT  : EX_MEM_ALUout <= #2 (ID_EX_A < ID_EX_B);
                default : EX_MEM_ALUout <= #2 32'hxxxxxxxx;
                endcase
            end
            
    RM_ALU  : begin
                case(ID_EX_IR[31:26])
                ADDI : EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_Imm;
                SUBI : EX_MEM_ALUout <= #2 ID_EX_A - ID_EX_Imm;
                SLTI : EX_MEM_ALUout <= #2 (ID_EX_A < ID_EX_Imm);
                default : EX_MEM_ALUout <= #2 32'hxxxxxxxx;
                endcase
             end
    BRANCH  : begin
                case(ID_EX_IR[31:26])
                BEQZ : begin
                        EX_MEM_ALUout <= #2 ID_EX_NPC + ID_EX_Imm;
                        EX_MEM_cond   <= #2 (ID_EX_A == 0);
                      end
                BNEQZ: begin
                        EX_MEM_ALUout <= #2 ID_EX_NPC + ID_EX_Imm;
                        EX_MEM_cond   <= #2 !(ID_EX_A == 0);
                       end
                endcase
             end
    LOAD,STORE:begin
                 EX_MEM_ALUout  <= #2 ID_EX_NPC + ID_EX_Imm;
                 EX_MEM_B  <= #2 ID_EX_B;
               end        
    
    /* HLT      : begin
                 halted <= 1;
               end    
               This cannot be written because, there may be another instruction
                processing in next stages so only at write back stage it should be halted = 1; */
                
    endcase
end


// Stage 4: Memory access
always@(posedge clk2)
if(halted == 0)
begin
    MEM_WB_type <= #2 EX_MEM_type;
    MEM_WB_IR   <= #2 EX_MEM_IR;
    case(EX_MEM_type)
    RR_ALU,RM_ALU  : MEM_WB_ALUout <= #2 EX_MEM_ALUout ;
    LOAD           : MEM_WB_LMD    <= #2 Mem[EX_MEM_ALUout];            // <-- FIX: load data from memory (was address)
    STORE          : if(branch_taken == 0) Mem[EX_MEM_ALUout] <= #2 EX_MEM_B; // disable write when branch is taken
    endcase
end



// Stage 5 : Write Back 
always@(posedge clk1)
if(branch_taken == 0)
begin
    case(MEM_WB_type)
    RR_ALU  : register[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUout; // <-- FIX: write to register file (rd)
    
    RM_ALU  : register[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUout; // <-- FIX: write to register file (rt)
    
    LOAD    : register[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;  // <-- FIX: write to register file (rt)
    
    HALT     : halted <= #2 1'b1;
    endcase
end
    

endmodule
