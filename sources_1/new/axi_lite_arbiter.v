`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/21/2025 12:15:32 PM
// Design Name: 
// Module Name: axi_lite_arbiter
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


/***************************************************************
 * AXI4-Lite Round-Robin Arbiter
 ***************************************************************/
module axi_lite_arbiter #(
    parameter NUM_MASTERS = 3,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                           clk,
    input                           resetn,
    // Master inputs
    input       [NUM_MASTERS-1:0]                    i_m_axi_awvalid,    // Master Write Address Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_awready,    // Master Write Address Ready
    input       [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_awaddr,     // Master Write Address

    input       [NUM_MASTERS-1:0][2:0]               i_m_axi_awprot,     // Master Write Protection
    input       [NUM_MASTERS-1:0]                    i_m_axi_wvalid,     // Master Write Data Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_wready,     // Master Write Data Ready
    input       [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    i_m_axi_wdata,      // Master Write Data
    input       [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0]  i_m_axi_wstrb,      // Master Write Strobe

    output      [NUM_MASTERS-1:0]                    o_m_axi_bvalid,     // Master Write Response Valid
    input       [NUM_MASTERS-1:0]                    i_m_axi_bready,     // Master Write Response Ready

    input       [NUM_MASTERS-1:0]                    i_m_axi_arvalid,    // Master Read Address Valid
    output      [NUM_MASTERS-1:0]                    o_m_axi_arready,    // Master Read Address Ready
    input       [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]    i_m_axi_araddr,     // Master Read Address
    input       [NUM_MASTERS-1:0][2:0]               i_m_axi_arprot,     // Master Read Protection
    output      [NUM_MASTERS-1:0]                    o_m_axi_rvalid,     // Master Read Data Valid
    input       [NUM_MASTERS-1:0]                    i_m_axi_rready,     // Master Read Data Ready
    output      [NUM_MASTERS-1:0][DATA_WIDTH-1:0]    o_m_axi_rdata,      // Master Read Data

    // Arbiter outputs
    output                                           o_s_axi_awvalid,    // Master Write Address Valid
    input                                            i_s_axi_awready,    // Master Write Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_awaddr,     // Master Write Address

    output                       [2:0]               o_s_axi_awprot,     // Master Write Protection
    output                                           o_s_axi_wvalid,     // Master Write Data Valid
    input                                            i_s_axi_wready,     // Master Write Data Ready
    output                       [DATA_WIDTH-1:0]    o_s_axi_wdata,      // Master Write Data
    output                       [DATA_WIDTH/8-1:0]  o_s_axi_wstrb,      // Master Write Strobe

    input                                            i_s_axi_bvalid,     // Master Write Response Valid
    output                                           o_s_axi_bready,     // Master Write Response Ready

    output                                           o_s_axi_arvalid,    // Master Read Address Valid
    input                                            i_s_axi_arready,    // Master Read Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_araddr,     // Master Read Address
    output                       [2:0]               o_s_axi_arprot,     // Master Read Protection
    input                                            i_s_axi_rvalid,     // Master Read Data Valid
    output                                           o_s_axi_rready,     // Master Read Data Ready
    input                        [DATA_WIDTH-1:0]    i_s_axi_rdata       // Master Read Data
);
 
    //Label State
    localparam  START   =   'd0,
                DECODE  =   'd1,

                S1      =   'd10,
                S2      =   'd11,
                S3      =   'd12,
                S4      =   'd13,
                S5      =   'd14,
                S6      =   'd15,
                S7      =   'd16,

                //state child
                S1_0    =   'd31,

                S2_1    =   'd32,
                
                S3_0    =   'd33,
                S3_1    =   'd34,

                S4_2    =   'd35,

                S5_0    =   'd36,
                S5_2    =   'd37,

                S6_1    =   'd38,
                S6_2    =   'd39,

                S7_0    =   'd40,
                S7_1    =   'd41,
                S7_2    =   'd42;
        


    //variable
    reg     [63:0]              state_reg, state_next;
    reg     [NUM_MASTERS-1:0]   capture_awvalid_reg;
    reg                         active_capture_reg, active_capture_next;

    //reg_IO
    reg     [ADDR_WIDTH-1:0]    select_s_axi_awaddr_reg, select_s_axi_awaddr_next;
    reg                         select_s_axi_awvalid_reg, select_s_axi_awvalid_next;
    reg     [NUM_MASTERS-1:0]   select_m_axi_awready_reg, select_m_axi_awready_next;

    reg     [2:0]               select_s_axi_awprot_reg, select_s_axi_awprot_next;
    reg                         select_s_axi_wvalid_reg, select_s_axi_wvalid_next;
    reg     [NUM_MASTERS-1:0]   select_m_axi_wready_reg, select_m_axi_wready_next;
    reg     [DATA_WIDTH-1:0]    select_s_axi_wdata_reg, select_s_axi_wdata_next;
    reg     [DATA_WIDTH/8-1:0]  select_s_axi_wstrb_reg, select_s_axi_wstrb_next;
    
    reg                         select_s_axi_bready_reg, select_s_axi_bready_next;
    reg     [NUM_MASTERS-1:0]   select_m_axi_bvalid_reg, select_m_axi_bvalid_next; 

    //sequential circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            state_reg <= START;
            active_capture_reg <= 0;
            capture_awvalid_reg <= 0;

            select_s_axi_awaddr_reg <= 0;
            select_s_axi_awvalid_reg <= 0;
            select_m_axi_awready_reg <= 0;
            select_s_axi_awprot_reg  <= 0;
            select_s_axi_wvalid_reg <= 0;
            select_m_axi_wready_reg <= 0;
            select_s_axi_wdata_reg <= 0;
            select_s_axi_wstrb_reg <= 0;
            select_s_axi_bready_reg <= 0;
            select_m_axi_bvalid_reg <= 0;
        end
        else begin
            if (active_capture_reg) begin
                capture_awvalid_reg <= i_m_axi_awvalid;
            end
            state_reg <= state_next;
            active_capture_reg <= active_capture_next;

            select_s_axi_awaddr_reg <= select_s_axi_awaddr_next;
            select_s_axi_awvalid_reg <= select_s_axi_awvalid_next;
            select_m_axi_awready_reg <= select_m_axi_awready_next;
            select_s_axi_awprot_reg  <= select_s_axi_awprot_next;
            select_s_axi_wvalid_reg <= select_s_axi_wvalid_next;
            select_m_axi_wready_reg <= select_m_axi_wready_next;
            select_s_axi_wdata_reg <= select_s_axi_wdata_next;
            select_s_axi_wstrb_reg <= select_s_axi_wstrb_next;
            select_s_axi_bready_reg <= select_s_axi_bready_next;
            select_m_axi_bvalid_reg <= select_m_axi_bvalid_next;
        end
        
    end


    //combi circuit
    always @(*) begin
        active_capture_next = 0;
        state_next = state_reg;

        select_s_axi_awaddr_next = select_s_axi_awaddr_reg;
        select_s_axi_awvalid_next = select_s_axi_awvalid_reg;
        select_m_axi_awready_next = select_m_axi_awready_reg;
        select_s_axi_awprot_next  = select_s_axi_awprot_reg;
        select_s_axi_wvalid_next = select_s_axi_wvalid_reg;
        select_m_axi_wready_next = select_m_axi_wready_reg;
        select_s_axi_wdata_next = select_s_axi_wdata_reg;
        select_s_axi_wstrb_next = select_s_axi_wstrb_reg;
        select_s_axi_bready_next = select_s_axi_bready_reg;
        select_m_axi_bvalid_next = select_m_axi_bvalid_reg;
        case (state_reg)
            START: begin
                if (|i_m_axi_awvalid == 1) begin
                    active_capture_next = 1;
                    state_next = DECODE;   
                end  
            end 
            DECODE: begin
                active_capture_next = 0;
                case (capture_awvalid_reg)
                    'b001: begin
                        state_next = S1_0;   
                    end 
                    'b010: begin
                        state_next = S2_1;   
                    end 
                    'b011: begin
                        state_next = S3_0;   
                    end 
                    'b100: begin
                        state_next = S4_2;   
                    end 
                    'b101: begin
                        state_next = S5_0;   
                    end 
                    'b110: begin
                        state_next = S6_1;   
                    end 
                    'b111: begin
                        state_next = S7_0;   
                    end

                    default: state_next = START;
                endcase

            end
            S1_0, S3_0, S5_0, S7_0: begin
                select_s_axi_awaddr_next = i_m_axi_awaddr[0];
                select_s_axi_awvalid_next = i_m_axi_awvalid[0];
                select_m_axi_awready_next = {'b0, 'b0, i_s_axi_awready};

                select_s_axi_awprot_next = i_m_axi_awprot[0];
                select_s_axi_wvalid_next = i_m_axi_wvalid[0];
                select_m_axi_wready_next = {'b0, 'b0, i_s_axi_wready};
                select_s_axi_wdata_next = i_m_axi_wdata[0];
                select_s_axi_wstrb_next = i_m_axi_wstrb[0];

                select_m_axi_bvalid_next = {'b0, 'b0, i_s_axi_bvalid};
                select_s_axi_bready_next = i_m_axi_bready[0];

                //branch
                if (state_reg == S1_0) begin
                    if (select_m_axi_bvalid_reg[0] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S3_0) begin
                    if (select_m_axi_bvalid_reg[0] == select_s_axi_bready_reg)
                        state_next = S3_1;
                end
                if (state_reg == S5_0) begin
                    if (select_m_axi_bvalid_reg[0] == select_s_axi_bready_reg)
                        state_next = S5_2;
                end
                if (state_reg == S7_0) begin
                    if (select_m_axi_bvalid_reg[0] == select_s_axi_bready_reg)
                        state_next = S7_1;
                end
            end

            S2_1, S3_1, S6_1, S7_1: begin
                select_s_axi_awaddr_next = i_m_axi_awaddr[1];
                select_s_axi_awvalid_next = i_m_axi_awvalid[1];
                select_m_axi_awready_next = {'b0, i_s_axi_awready, 'b0};

                select_s_axi_awprot_next = i_m_axi_awprot[1];
                select_s_axi_wvalid_next = i_m_axi_wvalid[1];
                select_m_axi_wready_next = {'b0, i_s_axi_wready, 'b0};
                select_s_axi_wdata_next = i_m_axi_wdata[1];
                select_s_axi_wstrb_next = i_m_axi_wstrb[1];

                select_m_axi_bvalid_next = {'b0, i_s_axi_bvalid, 'b0};
                select_s_axi_bready_next = i_m_axi_bready[1];

                //branch
                if (state_reg == S2_1) begin
                    if (select_m_axi_bvalid_reg[1] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S3_1) begin
                    if (select_m_axi_bvalid_reg[1] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S6_1) begin
                    if (select_m_axi_bvalid_reg[1] == select_s_axi_bready_reg)
                        state_next = S6_2;
                end
                if (state_reg == S7_1) begin
                    if (select_m_axi_bvalid_reg[1] == select_s_axi_bready_reg)
                        state_next = S7_2;
                end
                
            end

            S4_2, S5_2, S6_2, S7_2: begin
                select_s_axi_awaddr_next = i_m_axi_awaddr[2];
                select_s_axi_awvalid_next = i_m_axi_awvalid[2];
                select_m_axi_awready_next = {i_s_axi_awready, 'b0, 'b0};

                select_s_axi_awprot_next = i_m_axi_awprot[2];
                select_s_axi_wvalid_next = i_m_axi_wvalid[2];
                select_m_axi_wready_next = {i_s_axi_wready, 'b0, 'b0};
                select_s_axi_wdata_next = i_m_axi_wdata[2];
                select_s_axi_wstrb_next = i_m_axi_wstrb[2];
                
                select_m_axi_bvalid_next = {i_s_axi_bvalid, 'b0, 'b0};
                select_s_axi_bready_next = i_m_axi_bready[2];

                //branch
                
                if (state_reg == S4_2) begin
                    if (select_m_axi_bvalid_reg[2] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S5_2) begin
                    if (select_m_axi_bvalid_reg[2] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S6_2) begin
                    if (select_m_axi_bvalid_reg[2] == select_s_axi_bready_reg)
                        state_next = START;
                end
                if (state_reg == S7_2) begin
                    if (select_m_axi_bvalid_reg[2] == select_s_axi_bready_reg)
                        state_next = START;
                end
            end

            default: begin
                state_next = START;
            end

        endcase
    end

    //write Adress
    // assign  o_s_axi_awaddr      =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_awaddr[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_awaddr[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_awaddr[2] : 0;
    assign  o_s_axi_awaddr      =   select_s_axi_awaddr_reg;

    // assign  o_s_axi_awvalid     =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_awvalid[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_awvalid[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_awvalid[2] : 0;
    assign  o_s_axi_awvalid     =   select_s_axi_awvalid_reg;

    // assign  o_m_axi_awready[0]  =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_s_axi_awready : 0;
    // assign  o_m_axi_awready[1]  =   (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_s_axi_awready : 0;
    // assign  o_m_axi_awready[2]  =   (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_s_axi_awready : 0;
    assign  o_m_axi_awready     =   select_m_axi_awready_reg;
    // assign  o_m_axi_awready[0]  =   select_m_axi_awready_reg[0];
    // assign  o_m_axi_awready[1]  =   select_m_axi_awready_reg[1];
    // assign  o_m_axi_awready[2]  =   select_m_axi_awready_reg[2];

    //write Protection, Data, Strobe
    // assign  o_s_axi_awprot      =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_awprot[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_awprot[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_awprot[2] : 0;
    assign  o_s_axi_awprot      =   select_s_axi_awprot_reg;

    // assign  o_s_axi_wvalid      =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_wvalid[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_wvalid[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_wvalid[2] : 0;
    assign  o_s_axi_wvalid      =   select_s_axi_wvalid_reg;

    // assign  o_m_axi_wready[0]   =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_s_axi_wready : 0;
    // assign  o_m_axi_wready[1]   =   (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_s_axi_wready : 0;
    // assign  o_m_axi_wready[2]   =   (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_s_axi_wready : 0;
    assign  o_m_axi_wready      =  select_m_axi_wready_reg; 

    // assign  o_s_axi_wdata       =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_wdata[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_wdata[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_wdata[2] : 0;
    assign  o_s_axi_wdata       = select_s_axi_wdata_reg;

    // assign  o_s_axi_wstrb       =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_wstrb[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_wstrb[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_wstrb[2] : 0;
    assign  o_s_axi_wstrb       = select_s_axi_wstrb_reg;

    // write Response
    // assign  o_m_axi_bvalid[0]   =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_s_axi_bvalid : 0;
    // assign  o_m_axi_bvalid[1]   =   (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_s_axi_bvalid : 0;
    // assign  o_m_axi_bvalid[2]   =   (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_s_axi_bvalid : 0;
    assign  o_m_axi_bvalid      = select_m_axi_bvalid_reg;
    
    // assign  o_s_axi_bready      =   (state_reg == S1_0 || state_reg == S3_0 || state_reg == S5_0 || state_reg == S7_0)  ? i_m_axi_bready[0] :
    //                                 (state_reg == S2_1 || state_reg == S3_1 || state_reg == S6_1 || state_reg == S7_1)  ? i_m_axi_bready[1] : 
    //                                 (state_reg == S4_2 || state_reg == S5_2 || state_reg == S6_2 || state_reg == S7_2)  ? i_m_axi_bready[2] : 0;
    assign  o_s_axi_bready      = select_s_axi_bready_reg;
endmodule
