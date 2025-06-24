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
                //state child
                S1_0    =   'd1,

                S2_1    =   'd2,
                
                S3_0    =   'd3,
                S3_1    =   'd4,

                S4_2    =   'd5,

                S5_0    =   'd6,
                S5_2    =   'd7,

                S6_1    =   'd8,
                S6_2    =   'd9,

                S7_0    =   'd10,
                S7_1    =   'd11,
                S7_2    =   'd12;
        


    //variable
    reg     [3:0]               state_reg, state_next;
    reg     [NUM_MASTERS-1:0]   capture_awvalid_reg, capture_awvalid_next;


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


    wire enb_awvalid, enb_wvalid, enb_bready, enb_quantum_time;

    //wirte channel sequential circuit
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            state_reg                   <= START;
            active_capture_reg          <= 0;
            capture_awvalid_reg         <= 0;


            select_s_axi_awaddr_reg     <= 0;
            select_s_axi_awvalid_reg    <= 0;
            select_m_axi_awready_reg    <= 0;
            select_s_axi_awprot_reg     <= 0;
            select_s_axi_wvalid_reg     <= 0;
            select_m_axi_wready_reg     <= 0;
            select_s_axi_wdata_reg      <= 0;
            select_s_axi_wstrb_reg      <= 0;
            select_s_axi_bready_reg     <= 0;
            select_m_axi_bvalid_reg     <= 0;
        end
        else begin
            state_reg <= state_next;
            active_capture_reg <= active_capture_next;
            capture_awvalid_reg <= capture_awvalid_next;

            select_s_axi_awaddr_reg     <=      select_s_axi_awaddr_next;
            select_s_axi_awvalid_reg    <=      select_s_axi_awvalid_next;
            select_m_axi_awready_reg    <=      select_m_axi_awready_next;
            select_s_axi_awprot_reg     <=      select_s_axi_awprot_next;
            select_s_axi_wvalid_reg     <=      select_s_axi_wvalid_next;
            select_m_axi_wready_reg     <=      select_m_axi_wready_next;
            select_s_axi_wdata_reg      <=      select_s_axi_wdata_next;
            select_s_axi_wstrb_reg      <=      select_s_axi_wstrb_next;
            select_s_axi_bready_reg     <=      select_s_axi_bready_next;
            select_m_axi_bvalid_reg     <=      select_m_axi_bvalid_next;
        end
        
    end


    //wirte channel combi circuit
    always @(*) begin
        active_capture_next         =   active_capture_reg;
        capture_awvalid_next        =   select_s_axi_awvalid_reg;
        state_next                  =   state_reg;

        select_s_axi_awaddr_next    =   select_s_axi_awaddr_reg;
        select_s_axi_awvalid_next   =   select_s_axi_awvalid_reg;
        select_m_axi_awready_next   =   select_m_axi_awready_reg;
        select_s_axi_awprot_next    =   select_s_axi_awprot_reg;
        select_s_axi_wvalid_next    =   select_s_axi_wvalid_reg;
        select_m_axi_wready_next    =   select_m_axi_wready_reg;
        select_s_axi_wdata_next     =   select_s_axi_wdata_reg;
        select_s_axi_wstrb_next     =   select_s_axi_wstrb_reg;
        select_s_axi_bready_next    =   select_s_axi_bready_reg;
        select_m_axi_bvalid_next    =   select_m_axi_bvalid_reg;
        case (state_reg)
            START: begin
                select_s_axi_awaddr_next    =   0;
                select_s_axi_awvalid_next   =   0;
                select_m_axi_awready_next   =   0;
                select_s_axi_awprot_next    =   0;
                select_s_axi_wvalid_next    =   0;
                select_m_axi_wready_next    =   0;
                select_s_axi_wdata_next     =   0;
                select_s_axi_wstrb_next     =   0;
                select_s_axi_bready_next    =   0;
                select_m_axi_bvalid_next    =   0;

                if (active_capture_reg) begin
                    capture_awvalid_next = i_m_axi_awvalid; //;
                end
                else capture_awvalid_next = 0;

                if (|i_m_axi_awvalid == 1) begin
                    active_capture_next = 1;
                    case (capture_awvalid_reg)
                        'b001: begin
                            state_next = S1_0;
                            active_capture_next = 0;   
                        end 
                        'b010: begin
                            state_next = S2_1;
                            active_capture_next = 0;   
                        end 
                        'b011: begin
                            state_next = S3_0;
                            active_capture_next = 0;   
                        end 
                        'b100: begin
                            state_next = S4_2;
                            active_capture_next = 0;   
                        end 
                        'b101: begin
                            state_next = S5_0;
                            active_capture_next = 0;   
                        end 
                        'b110: begin
                            state_next = S6_1;
                            active_capture_next = 0;   
                        end 
                        'b111: begin
                            state_next = S7_0;
                            active_capture_next = 0;   
                        end

                        default: begin
                            state_next = START;
                        end 
                        
                    endcase
                       
                end  
            end 
            S1_0, S3_0, S5_0, S7_0: begin
                capture_awvalid_next         =   0;
                select_s_axi_awaddr_next    =   i_m_axi_awaddr[0];
                select_s_axi_awvalid_next   =   i_m_axi_awvalid[0];
                select_m_axi_awready_next   =   {1'b0, 1'b0, i_s_axi_awready};
                
                select_s_axi_awprot_next    =   i_m_axi_awprot[0];
                select_s_axi_wvalid_next    =   i_m_axi_wvalid[0];
                select_m_axi_wready_next    =   {1'b0, 1'b0, i_s_axi_wready};
                select_s_axi_wdata_next     =   i_m_axi_wdata[0];
                select_s_axi_wstrb_next     =   i_m_axi_wstrb[0];

                select_m_axi_bvalid_next    =   {1'b0, 1'b0, i_s_axi_bvalid};
                select_s_axi_bready_next    =   i_m_axi_bready[0];

                //branch
                case (state_reg)
                    S1_0: begin
                        if (((select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S3_0: begin
                        if (((select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (enb_quantum_time == 1))
                        state_next = S3_1;
                    end
                    S5_0: begin
                        if (((select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (enb_quantum_time == 1))
                        state_next = S5_2;
                    end
                    S7_0: begin
                        if (((select_m_axi_bvalid_reg[0] == 1) && (i_m_axi_bready[0] == 1)) || (enb_quantum_time == 1))
                        state_next = S7_1;
                    end 

                    default: begin
                      
                    end
                endcase
            end

            S2_1, S3_1, S6_1, S7_1: begin
                capture_awvalid_next         =   0;
                select_s_axi_awaddr_next    =   i_m_axi_awaddr[1];
                select_s_axi_awvalid_next   =   i_m_axi_awvalid[1];
                select_m_axi_awready_next   =   {1'b0, i_s_axi_awready, 1'b0};

                select_s_axi_awprot_next    =   i_m_axi_awprot[1];
                select_s_axi_wvalid_next    =   i_m_axi_wvalid[1];
                select_m_axi_wready_next    =   {1'b0, i_s_axi_wready, 1'b0};
                select_s_axi_wdata_next     =   i_m_axi_wdata[1];
                select_s_axi_wstrb_next     =   i_m_axi_wstrb[1];

                select_m_axi_bvalid_next    =   {1'b0, i_s_axi_bvalid, 1'b0};
                select_s_axi_bready_next    =   i_m_axi_bready[1];

                //branch
                case (state_reg)
                    S2_1: begin
                        if (((select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S3_1: begin
                        if (((select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S6_1: begin
                        if (((select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (enb_quantum_time == 1))
                        state_next = S6_2;
                    end
                    S7_1: begin
                        if (((select_m_axi_bvalid_reg[1] == 1) && (i_m_axi_bready[1] == 1)) || (enb_quantum_time == 1))
                        state_next = S7_2;
                    end 

                    default: begin
                      
                    end
                endcase
                
            end

            S4_2, S5_2, S6_2, S7_2: begin
                capture_awvalid_next         =   0;
                select_s_axi_awaddr_next    =   i_m_axi_awaddr[2];
                select_s_axi_awvalid_next   =   i_m_axi_awvalid[2];
                select_m_axi_awready_next   =   {i_s_axi_awready, 1'b0, 1'b0};

                select_s_axi_awprot_next    =   i_m_axi_awprot[2];
                select_s_axi_wvalid_next    =   i_m_axi_wvalid[2];
                select_m_axi_wready_next    =   {i_s_axi_wready, 1'b0, 1'b0};
                select_s_axi_wdata_next     =   i_m_axi_wdata[2];
                select_s_axi_wstrb_next     =   i_m_axi_wstrb[2];
                
                select_m_axi_bvalid_next    =   {i_s_axi_bvalid, 1'b0, 1'b0};
                select_s_axi_bready_next    =   i_m_axi_bready[2];

                //branch
                case (state_reg)
                    S4_2: begin
                        if (((select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S5_2: begin
                        if (((select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S6_2: begin
                        if (((select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end
                    S7_2: begin
                        if (((select_m_axi_bvalid_reg[2] == 1) && (i_m_axi_bready[2] == 1)) || (enb_quantum_time == 1))
                        state_next = START;
                    end 

                    default: begin
                      
                    end
                endcase
                
            end

            default: begin
                state_next = START;
            end

        endcase
    end

    //write Adress
    assign  o_s_axi_awaddr      =   select_s_axi_awaddr_reg;
    assign  o_s_axi_awvalid     =   (enb_awvalid) ? 0 : select_s_axi_awvalid_reg;
    assign  o_m_axi_awready     =   select_m_axi_awready_reg;

    //write Protection, Data, Strobe
    assign  o_s_axi_awprot      =   select_s_axi_awprot_reg;
    assign  o_s_axi_wvalid      =   (enb_wvalid) ? 0 : select_s_axi_wvalid_reg;
    assign  o_m_axi_wready      =   select_m_axi_wready_reg; 
    assign  o_s_axi_wdata       =   select_s_axi_wdata_reg;
    assign  o_s_axi_wstrb       =   select_s_axi_wstrb_reg;

    // write Response
    assign  o_m_axi_bvalid      =   select_m_axi_bvalid_reg;
    assign  o_s_axi_bready      =   (enb_bready) ? 0 : select_s_axi_bready_reg;



    
    timer_write_channel timer_write(
        .clk(clk),
        .resetn(resetn),

        .s_awready(i_s_axi_awready),
        .s_wready(i_s_axi_wready),
        .s_bvalid(i_s_axi_bvalid),
        .s_start_quantum(o_s_axi_awvalid),

        .enb_awvalid(enb_awvalid),
        .enb_wvalid(enb_wvalid),
        .enb_bready(enb_bready),
        .enb_quantum_time(enb_quantum_time)
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
                if (s_start_quantum == 1) begin
                    state_quantum_next = START;
                    count_quantum_next = count_quantum_next + 1;
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