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
    output                                           o_s_axi_awvalid,    // Slave Write Address Valid
    input                                            i_s_axi_awready,    // Slave Write Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_awaddr,     // Slave Write Address

    output                       [2:0]               o_s_axi_awprot,     // Slave Write Protection
    output                                           o_s_axi_wvalid,     // Slave Write Data Valid
    input                                            i_s_axi_wready,     // Slave Write Data Ready
    output                       [DATA_WIDTH-1:0]    o_s_axi_wdata,      // Slave Write Data
    output                       [DATA_WIDTH/8-1:0]  o_s_axi_wstrb,      // Slave Write Strobe

    input                                            i_s_axi_bvalid,     // Slave Write Response Valid
    output                                           o_s_axi_bready,     // Slave Write Response Ready

    output                                           o_s_axi_arvalid,    // Slave Read Address Valid
    input                                            i_s_axi_arready,    // Slave Read Address Ready
    output                       [ADDR_WIDTH-1:0]    o_s_axi_araddr,     // Slave Read Address
    output                       [2:0]               o_s_axi_arprot,     // Slave Read Protection
    input                                            i_s_axi_rvalid,     // Slave Read Data Valid
    output                                           o_s_axi_rready,     // Slave Read Data Ready
    input                        [DATA_WIDTH-1:0]    i_s_axi_rdata       // Slave Read Data
);
 

    // Write Channel States
    localparam  W_START   =   'd0,
                W_S1_0    =   'd1,
                W_S2_1    =   'd2,
                W_S3_0    =   'd3,
                W_S3_1    =   'd4,
                W_S4_2    =   'd5,
                W_S5_0    =   'd6,
                W_S5_2    =   'd7,
                W_S6_1    =   'd8,
                W_S6_2    =   'd9,
                W_S7_0    =   'd10,
                W_S7_1    =   'd11,
                W_S7_2    =   'd12;

    // Read Channel States
    localparam  R_START   =   'd0,
                R_S1_0    =   'd1,
                R_S2_1    =   'd2,
                R_S3_0    =   'd3,
                R_S3_1    =   'd4,
                R_S4_2    =   'd5,
                R_S5_0    =   'd6,
                R_S5_2    =   'd7,
                R_S6_1    =   'd8,
                R_S6_2    =   'd9,
                R_S7_0    =   'd10,
                R_S7_1    =   'd11,
                R_S7_2    =   'd12;
        
    // Write Channel Variables
    reg     [3:0]               w_state_reg, w_state_next;
    reg                         w_active_capture_reg, w_active_capture_next;

    reg     [ADDR_WIDTH-1:0]    w_select_s_axi_awaddr_reg, w_select_s_axi_awaddr_next;
    reg                         w_select_s_axi_awvalid_reg, w_select_s_axi_awvalid_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_awready_reg, w_select_m_axi_awready_next;

    reg     [2:0]               w_select_s_axi_awprot_reg, w_select_s_axi_awprot_next;
    reg                         w_select_s_axi_wvalid_reg, w_select_s_axi_wvalid_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_wready_reg, w_select_m_axi_wready_next;
    reg     [DATA_WIDTH-1:0]    w_select_s_axi_wdata_reg, w_select_s_axi_wdata_next;
    reg     [DATA_WIDTH/8-1:0]  w_select_s_axi_wstrb_reg, w_select_s_axi_wstrb_next;

    reg                         w_select_s_axi_bready_reg, w_select_s_axi_bready_next;
    reg     [NUM_MASTERS-1:0]   w_select_m_axi_bvalid_reg, w_select_m_axi_bvalid_next;

    // Read Channel Variables
    reg     [3:0]               r_state_reg, r_state_next;
    reg                         r_active_capture_reg, r_active_capture_next;

    reg     [ADDR_WIDTH-1:0]    r_select_s_axi_araddr_reg, r_select_s_axi_araddr_next;
    reg                         r_select_s_axi_arvalid_reg, r_select_s_axi_arvalid_next;
    reg     [NUM_MASTERS-1:0]   r_select_m_axi_arready_reg, r_select_m_axi_arready_next;

    reg     [2:0]               r_select_s_axi_arprot_reg, r_select_s_axi_arprot_next;
    reg                         r_select_s_axi_rready_reg, r_select_s_axi_rready_next;
    reg     [NUM_MASTERS-1:0]   r_select_m_axi_rvalid_reg, r_select_m_axi_rvalid_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata0_reg, r_select_m_axi_rdata0_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata1_reg, r_select_m_axi_rdata1_next;
    reg     [DATA_WIDTH-1:0]    r_select_m_axi_rdata2_reg, r_select_m_axi_rdata2_next;


    wire                        w_enb_awvalid, w_enb_wvalid, w_enb_bready, w_enb_quantum_time;
    wire                        r_enb_arvalid, r_enb_rready, r_enb_quantum_time;

    //wirte channel sequential circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            w_state_reg                   <= W_START;
            w_active_capture_reg          <= 0;

            w_select_s_axi_awaddr_reg     <= 0;
            w_select_s_axi_awvalid_reg    <= 0;
            w_select_m_axi_awready_reg    <= 0;
            w_select_s_axi_awprot_reg     <= 0;
            w_select_s_axi_wvalid_reg     <= 0;
            w_select_m_axi_wready_reg     <= 0;
            w_select_s_axi_wdata_reg      <= 0;
            w_select_s_axi_wstrb_reg      <= 0;
            w_select_s_axi_bready_reg     <= 0;
            w_select_m_axi_bvalid_reg     <= 0;

        end
        else begin
            w_state_reg                   <= w_state_next;
            w_active_capture_reg          <= w_active_capture_next;

            w_select_s_axi_awaddr_reg     <= w_select_s_axi_awaddr_next;
            w_select_s_axi_awvalid_reg    <= w_select_s_axi_awvalid_next;
            w_select_m_axi_awready_reg    <= w_select_m_axi_awready_next;
            w_select_s_axi_awprot_reg     <= w_select_s_axi_awprot_next;
            w_select_s_axi_wvalid_reg     <= w_select_s_axi_wvalid_next;
            w_select_m_axi_wready_reg     <= w_select_m_axi_wready_next;
            w_select_s_axi_wdata_reg      <= w_select_s_axi_wdata_next;
            w_select_s_axi_wstrb_reg      <= w_select_s_axi_wstrb_next;
            w_select_s_axi_bready_reg     <= w_select_s_axi_bready_next;
            w_select_m_axi_bvalid_reg     <= w_select_m_axi_bvalid_next;

        end
        
    end


    //wirte channel combi circuit
    always @(*) begin
        w_active_capture_next         = w_active_capture_reg;
        w_state_next                  = w_state_reg;
        w_select_s_axi_awaddr_next    = w_select_s_axi_awaddr_reg;
        w_select_s_axi_awvalid_next   = w_select_s_axi_awvalid_reg;
        w_select_m_axi_awready_next   = w_select_m_axi_awready_reg;
        w_select_s_axi_awprot_next    = w_select_s_axi_awprot_reg;
        w_select_s_axi_wvalid_next    = w_select_s_axi_wvalid_reg;
        w_select_m_axi_wready_next    = w_select_m_axi_wready_reg;
        w_select_s_axi_wdata_next     = w_select_s_axi_wdata_reg;
        w_select_s_axi_wstrb_next     = w_select_s_axi_wstrb_reg;
        w_select_s_axi_bready_next    = w_select_s_axi_bready_reg;
        w_select_m_axi_bvalid_next    = w_select_m_axi_bvalid_reg;

        case (w_state_reg)
            W_START: begin
                w_select_s_axi_awaddr_next    = 0;
                w_select_s_axi_awvalid_next   = 0;
                w_select_m_axi_awready_next   = 0;
                w_select_s_axi_awprot_next    = 0;
                w_select_s_axi_wvalid_next    = 0;
                w_select_m_axi_wready_next    = 0;
                w_select_s_axi_wdata_next     = 0;
                w_select_s_axi_wstrb_next     = 0;
                w_select_s_axi_bready_next    = 0;
                w_select_m_axi_bvalid_next    = 0;



                if (|i_m_axi_awvalid == 1) begin
                    w_active_capture_next = 1;
                    case (i_m_axi_awvalid)
                        'b001: begin
                            w_state_next = W_S1_0;
                        end 
                        'b010: begin
                            w_state_next = W_S2_1;
                        end 
                        'b011: begin
                            w_state_next = W_S3_0;
                        end 
                        'b100: begin
                            w_state_next = W_S4_2;
                        end 
                        'b101: begin
                            w_state_next = W_S5_0;
                        end 
                        'b110: begin
                            w_state_next = W_S6_1;
                        end 
                        'b111: begin
                            w_state_next = W_S7_0;
                        end
                        default: begin
                            w_state_next = W_START;
                        end 
                    endcase
                end  
            end 
            W_S1_0, W_S3_0, W_S5_0, W_S7_0: begin
                w_active_capture_next         = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[0];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[0];
                w_select_m_axi_awready_next   = {1'b0, 1'b0, i_s_axi_awready};

                w_select_s_axi_awprot_next    = i_m_axi_awprot[0];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[0];
                w_select_m_axi_wready_next    = {1'b0, 1'b0, i_s_axi_wready};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[0];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[0];

                w_select_m_axi_bvalid_next    = {1'b0, 1'b0, i_s_axi_bvalid};
                w_select_s_axi_bready_next    = i_m_axi_bready[0];

                case (w_state_reg)
                    W_S1_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S3_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S3_1;
                    end
                    W_S5_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S5_2;
                    end
                    W_S7_0: begin
                        if (((w_select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S7_1;
                    end 
                    default: begin
                    end
                endcase
            end
            W_S2_1, W_S3_1, W_S6_1, W_S7_1: begin
                w_active_capture_next        = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[1];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[1];
                w_select_m_axi_awready_next   = {1'b0, i_s_axi_awready, 1'b0}
                ;
                w_select_s_axi_awprot_next    = i_m_axi_awprot[1];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[1];
                w_select_m_axi_wready_next    = {1'b0, i_s_axi_wready, 1'b0};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[1];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[1];

                w_select_m_axi_bvalid_next    = {1'b0, i_s_axi_bvalid, 1'b0};
                w_select_s_axi_bready_next    = i_m_axi_bready[1];

                case (w_state_reg)
                    W_S2_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S3_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S6_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S6_2;
                    end
                    W_S7_1: begin
                        if (((w_select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_S7_2;
                    end 
                    default: begin
                    end
                endcase
            end
            W_S4_2, W_S5_2, W_S6_2, W_S7_2: begin
                w_active_capture_next        = 0;
                w_select_s_axi_awaddr_next    = i_m_axi_awaddr[2];
                w_select_s_axi_awvalid_next   = i_m_axi_awvalid[2];
                w_select_m_axi_awready_next   = {i_s_axi_awready, 1'b0, 1'b0};

                w_select_s_axi_awprot_next    = i_m_axi_awprot[2];
                w_select_s_axi_wvalid_next    = i_m_axi_wvalid[2];
                w_select_m_axi_wready_next    = {i_s_axi_wready, 1'b0, 1'b0};
                w_select_s_axi_wdata_next     = i_m_axi_wdata[2];
                w_select_s_axi_wstrb_next     = i_m_axi_wstrb[2];
                
                w_select_m_axi_bvalid_next    = {i_s_axi_bvalid, 1'b0, 1'b0};
                w_select_s_axi_bready_next    = i_m_axi_bready[2];

                case (w_state_reg)
                    W_S4_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S5_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S6_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end
                    W_S7_2: begin
                        if (((w_select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (w_enb_quantum_time == 1))
                            w_state_next = W_START;
                    end 
                    default: begin
                    end
                endcase
            end
            default: begin
                w_state_next = W_START;
            end
        endcase
    end

    // Read Channel Sequential Circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            r_state_reg                   <= R_START;
            r_active_capture_reg          <= 0;
            r_select_s_axi_araddr_reg     <= 0;
            r_select_s_axi_arvalid_reg    <= 0;
            r_select_m_axi_arready_reg    <= 0;
            r_select_s_axi_arprot_reg     <= 0;
            r_select_s_axi_rready_reg     <= 0;
            r_select_m_axi_rvalid_reg     <= 0;

            r_select_m_axi_rdata0_reg     <= 0;
            r_select_m_axi_rdata1_reg     <= 0;
            r_select_m_axi_rdata2_reg     <= 0;
        end
        else begin
            r_state_reg                   <= r_state_next;
            r_active_capture_reg          <= r_active_capture_next;
            r_select_s_axi_araddr_reg     <= r_select_s_axi_araddr_next;
            r_select_s_axi_arvalid_reg    <= r_select_s_axi_arvalid_next;
            r_select_m_axi_arready_reg    <= r_select_m_axi_arready_next;
            r_select_s_axi_arprot_reg     <= r_select_s_axi_arprot_next;
            r_select_s_axi_rready_reg     <= r_select_s_axi_rready_next;
            r_select_m_axi_rvalid_reg     <= r_select_m_axi_rvalid_next;

            r_select_m_axi_rdata0_reg     <= r_select_m_axi_rdata0_next;
            r_select_m_axi_rdata1_reg     <= r_select_m_axi_rdata1_next;
            r_select_m_axi_rdata2_reg     <= r_select_m_axi_rdata2_next;
        end
    end

    
    // Read Channel Combinational Circuit
    always @(*) begin
        r_active_capture_next         = r_active_capture_reg;
        r_state_next                  = r_state_reg;
        r_select_s_axi_araddr_next    = r_select_s_axi_araddr_reg;
        r_select_s_axi_arvalid_next   = r_select_s_axi_arvalid_reg;
        r_select_m_axi_arready_next   = r_select_m_axi_arready_reg;
        r_select_s_axi_arprot_next    = r_select_s_axi_arprot_reg;
        r_select_s_axi_rready_next    = r_select_s_axi_rready_reg;
        r_select_m_axi_rvalid_next    = r_select_m_axi_rvalid_reg;
        
        r_select_m_axi_rdata0_next     = r_select_m_axi_rdata0_reg;
        r_select_m_axi_rdata1_next     = r_select_m_axi_rdata1_reg;
        r_select_m_axi_rdata2_next     = r_select_m_axi_rdata2_reg;

        case (r_state_reg)
            R_START: begin
                r_select_s_axi_araddr_next    = 0;
                r_select_s_axi_arvalid_next   = 0;
                r_select_m_axi_arready_next   = 0;
                r_select_s_axi_arprot_next    = 0;
                r_select_s_axi_rready_next    = 0;
                r_select_m_axi_rvalid_next    = 0;
                
                r_select_m_axi_rdata0_next     = 0;
                r_select_m_axi_rdata1_next     = 0;
                r_select_m_axi_rdata2_next     = 0;

                if (|i_m_axi_arvalid == 1) begin
                    r_active_capture_next = 1;
                    case (i_m_axi_arvalid)
                        'b001: begin
                            r_state_next = R_S1_0;
                        end 
                        'b010: begin
                            r_state_next = R_S2_1;
                        end 
                        'b011: begin
                            r_state_next = R_S3_0;
                        end 
                        'b100: begin
                            r_state_next = R_S4_2;
                        end 
                        'b101: begin
                            r_state_next = R_S5_0;
        
                        end 
                        'b110: begin
                            r_state_next = R_S6_1;
                        end 
                        'b111: begin
                            r_state_next = R_S7_0;
                        end
                        default: begin
                            r_state_next = R_START;
                        end 
                    endcase
                end  
            end 
            R_S1_0, R_S3_0, R_S5_0, R_S7_0: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[0];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[0];
                r_select_m_axi_arready_next   = {1'b0, 1'b0, i_s_axi_arready};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[0];
                r_select_s_axi_rready_next    = i_m_axi_rready[0];
                r_select_m_axi_rvalid_next    = {1'b0, 1'b0, i_s_axi_rvalid};
                r_select_m_axi_rdata0_next    = i_s_axi_rdata;
                r_select_m_axi_rdata1_next    = 0;
                r_select_m_axi_rdata2_next    = 0;

                case (r_state_reg)
                    R_S1_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S3_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S3_1;
                    end
                    R_S5_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S5_2;
                    end
                    R_S7_0: begin
                        if (((r_select_m_axi_rvalid_reg[0] == 1) && (i_m_axi_rready[0] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S7_1;
                    end 
                    default: begin
                    end
                endcase
            end
            R_S2_1, R_S3_1, R_S6_1, R_S7_1: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[1];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[1];
                r_select_m_axi_arready_next   = {1'b0, i_s_axi_arready, 1'b0};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[1];
                r_select_s_axi_rready_next    = i_m_axi_rready[1];
                r_select_m_axi_rvalid_next    = {1'b0, i_s_axi_rvalid, 1'b0};
                r_select_m_axi_rdata0_next  = 0;
                r_select_m_axi_rdata1_next  = i_s_axi_rdata;
                r_select_m_axi_rdata2_next  = 0;

                case (r_state_reg)
                    R_S2_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S3_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S6_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S6_2;
                    end
                    R_S7_1: begin
                        if (((r_select_m_axi_rvalid_reg[1] == 1) && (i_m_axi_rready[1] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_S7_2;
                    end 
                    default: begin
                    end
                endcase
            end
            R_S4_2, R_S5_2, R_S6_2, R_S7_2: begin
                r_active_capture_next         = 0;
                r_select_s_axi_araddr_next    = i_m_axi_araddr[2];
                r_select_s_axi_arvalid_next   = i_m_axi_arvalid[2];
                r_select_m_axi_arready_next   = {i_s_axi_arready, 1'b0, 1'b0};

                r_select_s_axi_arprot_next    = i_m_axi_arprot[2];
                r_select_s_axi_rready_next    = i_m_axi_rready[2];
                r_select_m_axi_rvalid_next    = {i_s_axi_rvalid, 1'b0, 1'b0};
                r_select_m_axi_rdata0_next  = 0;
                r_select_m_axi_rdata1_next  = 0;
                r_select_m_axi_rdata2_next  = i_s_axi_rdata;

                case (r_state_reg)
                    R_S4_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S5_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S6_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end
                    R_S7_2: begin
                        if (((r_select_m_axi_rvalid_reg[2] == 1) && (i_m_axi_rready[2] == 1)) || (r_enb_quantum_time == 1))
                            r_state_next = R_START;
                    end 
                    default: begin
                    end
                endcase
            end
            default: begin
                r_state_next = R_START;
            end
        endcase
    end



   // Write Channel Assignments
    assign o_s_axi_awaddr       = w_select_s_axi_awaddr_reg;
    assign o_s_axi_awvalid      = (w_enb_awvalid) ? 0 : w_select_s_axi_awvalid_reg;
    assign o_m_axi_awready      = w_select_m_axi_awready_reg;

    assign o_s_axi_awprot       = w_select_s_axi_awprot_reg;
    assign o_s_axi_wvalid       = (w_enb_wvalid) ? 0 : w_select_s_axi_wvalid_reg;
    assign o_m_axi_wready       = w_select_m_axi_wready_reg;
    assign o_s_axi_wdata        = w_select_s_axi_wdata_reg;
    assign o_s_axi_wstrb        = w_select_s_axi_wstrb_reg;

    assign o_m_axi_bvalid       = w_select_m_axi_bvalid_reg;
    assign o_s_axi_bready       = (w_enb_bready) ? 0 : w_select_s_axi_bready_reg;

    // Read Channel Assignments
    assign o_s_axi_araddr       = r_select_s_axi_araddr_reg;
    assign o_s_axi_arvalid      = (r_enb_arvalid) ? 0 : r_select_s_axi_arvalid_reg;
    assign o_m_axi_arready      = r_select_m_axi_arready_reg;

    assign o_s_axi_arprot       = r_select_s_axi_arprot_reg;
    assign o_s_axi_rready       = (r_enb_rready) ? 0 : r_select_s_axi_rready_reg;
    assign o_m_axi_rvalid       = r_select_m_axi_rvalid_reg;
    assign o_m_axi_rdata[0]        = r_select_m_axi_rdata0_reg;
    assign o_m_axi_rdata[1]        = r_select_m_axi_rdata1_reg;
    assign o_m_axi_rdata[2]        = r_select_m_axi_rdata2_reg;


    // Write Channel Timer
    timer_write_channel timer_write (
        .clk(clk),
        .resetn(resetn & (!w_active_capture_reg)),

        .s_awready(i_s_axi_awready),
        .s_wready(i_s_axi_wready),
        .s_bvalid(i_s_axi_bvalid),
        .s_start_quantum(o_s_axi_awvalid),

        .enb_awvalid(w_enb_awvalid),
        .enb_wvalid(w_enb_wvalid),
        .enb_bready(w_enb_bready),
        .enb_quantum_time(w_enb_quantum_time)
    );

    // Read Channel Timer
    timer_read_channel timer_read (
        .clk(clk),
        .resetn(resetn & (!r_active_capture_reg)),

        .s_arready(i_s_axi_arready),
        .s_rvalid(i_s_axi_rvalid),
        .s_start_quantum(o_s_axi_arvalid),

        .enb_arvalid(r_enb_arvalid),
        .enb_rready(r_enb_rready),
        .enb_quantum_time(r_enb_quantum_time)
    );

endmodule

// module child
module timer_write_channel(
    input clk,
    input resetn,

    input s_awready,
    input s_wready,
    input s_bvalid,
    input s_start_quantum,

    output enb_awvalid,
    output enb_wvalid,
    output enb_bready,
    output enb_quantum_time
);


    localparam IDLE = 'b00,
               START = 'b01;

    localparam QUANTUM_SIZE = 14; // clock

    reg [1:0] state_quantum_reg, state_quantum_next;

    reg [2:0]count0_reg, count0_next;
    reg [2:0]count1_reg, count1_next;
    reg [2:0]count2_reg, count2_next;
    reg [3:0]count_quantum_reg, count_quantum_next;

    reg flag_awvalid_reg, flag_awvalid_next;
    reg flag_wvalid_reg, flag_wvalid_next;
    reg flag_bready_reg, flag_bready_next;

    reg enb_awvalid_reg, enb_awvalid_next;
    reg enb_wvalid_reg, enb_wvalid_next;
    reg enb_bready_reg, enb_bready_next;
    reg enb_quantum_time_reg, enb_quantum_time_next;

    always @(posedge clk, negedge resetn) begin
        if(~resetn) begin
            state_quantum_reg <= IDLE;
            count0_reg <= 0;
            count1_reg <= 0;
            count2_reg <= 0;
            count_quantum_reg <= 0;
            
            flag_awvalid_reg <= 0;
            flag_wvalid_reg <= 0;
            flag_bready_reg <= 0;

            enb_awvalid_reg <= 0;
            enb_wvalid_reg  <= 0;
            enb_bready_reg  <= 0;
            enb_quantum_time_reg <= 0;
        end
        else begin
            state_quantum_reg <= state_quantum_next;

            count0_reg <= count0_next;
            count1_reg <= count1_next;
            count2_reg <= count2_next;
            count_quantum_reg <= count_quantum_next;

            flag_awvalid_reg <= flag_awvalid_next;
            flag_wvalid_reg <= flag_wvalid_next;
            flag_bready_reg <= flag_bready_next;

            enb_awvalid_reg <= enb_awvalid_next;
            enb_wvalid_reg  <= enb_wvalid_next;
            enb_bready_reg  <= enb_bready_next;
            enb_quantum_time_reg <= enb_quantum_time_next;
        end
        
    end

    always @(*) begin
        state_quantum_next = state_quantum_reg;
        count0_next = count0_reg;
        count1_next = count1_reg;
        count2_next = count2_reg;
        count_quantum_next = count_quantum_reg;

        flag_awvalid_next = flag_awvalid_reg;
        flag_wvalid_next = flag_wvalid_reg;
        flag_bready_next = flag_bready_reg;

        enb_awvalid_next = enb_awvalid_reg;
        enb_wvalid_next  = enb_wvalid_reg;
        enb_bready_next  = enb_bready_reg;
        enb_quantum_time_next = enb_quantum_time_reg;

        // branch signal transaction
        case ({s_bvalid, s_wready, s_awready})
            'b001: begin: signal_awready
                flag_awvalid_next = 1;
            end
            'b010: begin: signal_wready
                flag_wvalid_next = 1;
            end
            'b100: begin: signal_bvalid
                flag_bready_next = 1;
            end
            default: begin
            end
        endcase

        if (flag_awvalid_next == 1) begin
            count0_next = count0_next + 1;
            enb_awvalid_next = 1;
            if (count0_reg > 1) begin
                flag_awvalid_next = 0;
                count0_next = 0;
                enb_awvalid_next = 0;
            end
        end
        if (flag_wvalid_next == 1) begin
            count1_next = count1_next + 1;
            enb_wvalid_next = 1;
            if (count1_reg > 1) begin
                flag_wvalid_next = 0;
                count1_next = 0;
                enb_wvalid_next = 0;
            end
        end
        if (flag_bready_next == 1) begin
            count2_next = count2_next + 1;
            enb_bready_next = 1;
            if (count2_reg > 1) begin
                flag_bready_next = 0;
                count2_next = 0;
                enb_bready_next = 0;
            end
        end

        //time quantum process
        case (state_quantum_reg)
            IDLE: begin
                enb_quantum_time_next = 0;
                if (s_start_quantum == 1  && enb_quantum_time_reg == 0) begin
                    state_quantum_next = START;
                    count_quantum_next = 0; //count_quantum_next + 1;
                end
            end
            START: begin
                count_quantum_next = count_quantum_next + 1;
                if ((count_quantum_reg > QUANTUM_SIZE)) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 1;
                    state_quantum_next = IDLE;
                end
                if (enb_bready_reg) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 0;
                    state_quantum_next = IDLE;
                end      
            end 
            default: state_quantum_next = IDLE;
        endcase
        

    end

    assign enb_awvalid = enb_awvalid_reg;
    assign enb_wvalid = enb_wvalid_reg;
    assign enb_bready = enb_bready_reg;
    assign enb_quantum_time = enb_quantum_time_reg;

endmodule



// Read Channel Timer Module
module timer_read_channel (
    input clk,
    input resetn,

    input s_arready,
    input s_rvalid,
    input s_start_quantum,

    output enb_arvalid,
    output enb_rready,
    output enb_quantum_time
);
    localparam IDLE = 'b00,
               START = 'b01;
    localparam QUANTUM_SIZE = 14; // clock

    reg [1:0] state_quantum_reg, state_quantum_next;
    reg [2:0] count0_reg, count0_next;
    reg [2:0] count1_reg, count1_next;
    reg [3:0] count_quantum_reg, count_quantum_next;

    reg flag_arvalid_reg, flag_arvalid_next;
    reg flag_rready_reg, flag_rready_next;

    reg enb_arvalid_reg, enb_arvalid_next;
    reg enb_rready_reg, enb_rready_next;
    reg enb_quantum_time_reg, enb_quantum_time_next;


    always @(posedge clk, negedge resetn) begin
        if(~resetn) begin
            state_quantum_reg <= IDLE;
            count0_reg <= 0;
            count1_reg <= 0;
            count_quantum_reg <= 0;
            
            flag_arvalid_reg <= 0;
            flag_rready_reg <= 0;

            enb_arvalid_reg <= 0;
            enb_rready_reg  <= 0;
            enb_quantum_time_reg <= 0;
        end
        else begin
            state_quantum_reg <= state_quantum_next;

            count0_reg <= count0_next;
            count1_reg <= count1_next;
            count_quantum_reg <= count_quantum_next;

            flag_arvalid_reg <= flag_arvalid_next;
            flag_rready_reg <= flag_rready_next;

            enb_arvalid_reg <= enb_arvalid_next;
            enb_rready_reg  <= enb_rready_next;
            enb_quantum_time_reg <= enb_quantum_time_next;
        end
        
    end

    always @(*) begin
        state_quantum_next  = state_quantum_reg;
        count0_next         = count0_reg;
        count1_next         = count1_reg;
        count_quantum_next  = count_quantum_reg;

        flag_arvalid_next   = flag_arvalid_reg;
        flag_rready_next    = flag_rready_reg;

        enb_arvalid_next = enb_arvalid_reg;
        enb_rready_next  = enb_rready_reg;
        enb_quantum_time_next = enb_quantum_time_reg;

        // branch signal transaction
        case ({s_rvalid, s_arready})
            'b01: begin
                flag_arvalid_next = 1;
            end
            'b10: begin
                flag_rready_next = 1;
            end
            default: begin
            end
        endcase

        if (flag_arvalid_next == 1) begin
            count0_next = count0_next + 1;
            enb_arvalid_next = 1;
            if (count0_reg > 1) begin
                flag_arvalid_next = 0;
                count0_next = 0;
                enb_arvalid_next = 0;
            end
        end
        if (flag_rready_next == 1) begin
            count1_next = count1_next + 1;
            enb_rready_next = 1;
            if (count1_reg > 1) begin
                flag_rready_next = 0;
                count1_next = 0;
                enb_rready_next = 0;
            end
        end

        //time quantum process
        case (state_quantum_reg)
            IDLE: begin
                enb_quantum_time_next = 0;
                if (s_start_quantum == 1  && enb_quantum_time_reg == 0) begin
                    state_quantum_next = START;
                    count_quantum_next = 0; //count_quantum_next + 1;
                end
            end
            START: begin
                count_quantum_next = count_quantum_next + 1;
                if ((count_quantum_reg > QUANTUM_SIZE)) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 1;
                    state_quantum_next = IDLE;
                end
                if (enb_rready_reg) begin
                    count_quantum_next = 0;
                    enb_quantum_time_next = 0;
                    state_quantum_next = IDLE;
                end      
            end 
            default: state_quantum_next = IDLE;
        endcase
        

    end

    assign enb_arvalid = enb_arvalid_reg;
    assign enb_rready = enb_rready_reg;
    assign enb_quantum_time = enb_quantum_time_reg;

endmodule