`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2025 05:37:58 PM
// Design Name: 
// Module Name: axi_lite_arbiter_tb
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



module axi_lite_arbiter_tb;

    // Parameters
    localparam NUM_MASTERS = 3;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam CLK_PERIOD = 10; // 100 MHz clock

    // Signals
    reg                         clk;
    reg                         resetn;

    // Master signals
    reg  [NUM_MASTERS-1:0]      m_axi_awvalid;
    wire [NUM_MASTERS-1:0]      m_axi_awready;
    reg  [ADDR_WIDTH-1:0]       m_axi_awaddr_0, m_axi_awaddr_1, m_axi_awaddr_2;
    reg  [2:0]                  m_axi_awprot_0, m_axi_awprot_1, m_axi_awprot_2;
    reg  [NUM_MASTERS-1:0]      m_axi_wvalid;
    wire [NUM_MASTERS-1:0]      m_axi_wready;
    reg  [DATA_WIDTH-1:0]       m_axi_wdata_0, m_axi_wdata_1, m_axi_wdata_2;
    reg  [DATA_WIDTH/8-1:0]     m_axi_wstrb_0, m_axi_wstrb_1, m_axi_wstrb_2;
    wire [NUM_MASTERS-1:0]      m_axi_bvalid;
    reg  [NUM_MASTERS-1:0]      m_axi_bready;

    // Slave signals
    wire                        s_axi_awvalid;
    reg                         s_axi_awready;
    wire [ADDR_WIDTH-1:0]       s_axi_awaddr;
    wire [2:0]                  s_axi_awprot;
    wire                        s_axi_wvalid;
    reg                         s_axi_wready;
    wire [DATA_WIDTH-1:0]       s_axi_wdata;
    wire [DATA_WIDTH/8-1:0]     s_axi_wstrb;
    reg                         s_axi_bvalid;
    wire                        s_axi_bready;

    // Unused read channel signals (tied off)
    reg  [NUM_MASTERS-1:0]      m_axi_arvalid;
    wire [NUM_MASTERS-1:0]      m_axi_arready;
    reg  [ADDR_WIDTH-1:0]       m_axi_araddr_0, m_axi_araddr_1, m_axi_araddr_2;
    reg  [2:0]                  m_axi_arprot_0, m_axi_arprot_1, m_axi_arprot_2;
    wire [NUM_MASTERS-1:0]      m_axi_rvalid;
    reg  [NUM_MASTERS-1:0]      m_axi_rready;
    wire [DATA_WIDTH-1:0]       m_axi_rdata_0, m_axi_rdata_1, m_axi_rdata_2;
    wire                        s_axi_arvalid;
    reg                         s_axi_arready;
    wire [ADDR_WIDTH-1:0]       s_axi_araddr;
    wire [2:0]                  s_axi_arprot;
    reg                         s_axi_rvalid;
    wire                        s_axi_rready;
    reg  [DATA_WIDTH-1:0]       s_axi_rdata;

    // Instantiate the DUT
    axi_lite_arbiter #(
        .NUM_MASTERS(NUM_MASTERS),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .i_m_axi_awvalid(m_axi_awvalid),
        .o_m_axi_awready(m_axi_awready),
        .i_m_axi_awaddr({m_axi_awaddr_2, m_axi_awaddr_1, m_axi_awaddr_0}),
        .i_m_axi_awprot({m_axi_awprot_2, m_axi_awprot_1, m_axi_awprot_0}),
        .i_m_axi_wvalid(m_axi_wvalid),
        .o_m_axi_wready(m_axi_wready),
        .i_m_axi_wdata({m_axi_wdata_2, m_axi_wdata_1, m_axi_wdata_0}),
        .i_m_axi_wstrb({m_axi_wstrb_2, m_axi_wstrb_1, m_axi_wstrb_0}),
        .o_m_axi_bvalid(m_axi_bvalid),
        .i_m_axi_bready(m_axi_bready),
        .i_m_axi_arvalid(m_axi_arvalid),
        .o_m_axi_arready(m_axi_arready),
        .i_m_axi_araddr({m_axi_araddr_2, m_axi_araddr_1, m_axi_araddr_0}),
        .i_m_axi_arprot({m_axi_arprot_2, m_axi_arprot_1, m_axi_arprot_0}),
        .o_m_axi_rvalid(m_axi_rvalid),
        .i_m_axi_rready(m_axi_rready),
        .o_m_axi_rdata({m_axi_rdata_2, m_axi_rdata_1, m_axi_rdata_0}),
        .o_s_axi_awvalid(s_axi_awvalid),
        .i_s_axi_awready(s_axi_awready),
        .o_s_axi_awaddr(s_axi_awaddr),
        .o_s_axi_awprot(s_axi_awprot),
        .o_s_axi_wvalid(s_axi_wvalid),
        .i_s_axi_wready(s_axi_wready),
        .o_s_axi_wdata(s_axi_wdata),
        .o_s_axi_wstrb(s_axi_wstrb),
        .i_s_axi_bvalid(s_axi_bvalid),
        .o_s_axi_bready(s_axi_bready),
        .o_s_axi_arvalid(s_axi_arvalid),
        .i_s_axi_arready(s_axi_arready),
        .o_s_axi_araddr(s_axi_araddr),
        .o_s_axi_arprot(s_axi_arprot),
        .i_s_axi_rvalid(s_axi_rvalid),
        .o_s_axi_rready(s_axi_rready), // Sửa lỗi ở đây
        .i_s_axi_rdata(s_axi_rdata)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Main test procedure
    initial begin
        // Initialize signals
        resetn = 0;
        m_axi_awvalid = 0;
        m_axi_awaddr_0 = 0;
        m_axi_awaddr_1 = 0;
        m_axi_awaddr_2 = 0;
        m_axi_awprot_0 = 0;
        m_axi_awprot_1 = 0;
        m_axi_awprot_2 = 0;
        m_axi_wvalid = 0;
        m_axi_wdata_0 = 0;
        m_axi_wdata_1 = 0;
        m_axi_wdata_2 = 0;
        m_axi_wstrb_0 = 0;
        m_axi_wstrb_1 = 0;
        m_axi_wstrb_2 = 0;
        m_axi_bready = 0;
        s_axi_awready = 0;
        s_axi_wready = 0;
        s_axi_bvalid = 0;
        m_axi_arvalid = 0;
        m_axi_araddr_0 = 0;
        m_axi_araddr_1 = 0;
        m_axi_araddr_2 = 0;
        m_axi_arprot_0 = 0;
        m_axi_arprot_1 = 0;
        m_axi_arprot_2 = 0;
        m_axi_rready = 0;
        s_axi_arready = 0;
        s_axi_rvalid = 0;
        s_axi_rdata = 0;

        // Reset
        #(CLK_PERIOD*5) resetn = 1;
        $display("Reset released at %0t", $time);

        // Test Case 1: Single master write (Master 0)
        $display("Test Case 1: Master 0 write");
        m_axi_awaddr_0 = 32'h1000_1000;
        m_axi_awaddr_1 = 32'h2000_2000;
        m_axi_awaddr_2 = 32'h3000_3000;
        m_axi_wdata_0 = 32'hDEAD_BEEF;
        m_axi_wdata_1 = 32'habcd_ffff;
        m_axi_wdata_2 = 32'hFFFF_ffff;
        m_axi_awvalid = 'b000;
        m_axi_wvalid  = 'b000;
        m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 1: 3'b111////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b111;
        m_axi_wvalid  = 'b111;
        m_axi_bready  = 'b111;
        m_axi_awprot_0 = 'b001; 
        m_axi_awprot_1 = 'b011; 
        m_axi_awprot_2 = 'b100;

        m_axi_wstrb_0 = 'b1111; 
        m_axi_wstrb_1 = 'b1101;
        m_axi_wstrb_2 = 'b1011;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b110;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b110;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b110;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b100;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b100;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;

        //////////////////////////TEST CASE 2 repeat: 3'b111////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b111;
        m_axi_wvalid  = 'b111;
        m_axi_bready  = 'b111;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b110;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b110;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b110;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b100;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b100;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;
        



        //////////////////////////TEST CASE 3: 3'b001////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b001;
        m_axi_wvalid  = 'b001;
        m_axi_bready  = 'b001;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;



        //////////////////////////TEST CASE 4: 3'b010////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b010;
        m_axi_wvalid  = 'b010;
        m_axi_bready  = 'b010;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 5: 3'b011////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b011;
        m_axi_wvalid  = 'b011;
        m_axi_bready  = 'b011;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b010;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b010;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b010;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 6: 3'b100////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b100;
        m_axi_wvalid  = 'b100;
        m_axi_bready  = 'b100;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        // //master 1
        // repeat(7) @(posedge clk);
        // s_axi_awready = 1;
        // repeat(1) @(posedge clk);
        // s_axi_awready = 0;
        // s_axi_wready = 1;
        
        // repeat(1) @(posedge clk);
        // s_axi_wready = 0;
        // m_axi_awvalid = 'b000;
        // s_axi_bvalid = 1;

        // repeat(1) @(posedge clk);
        // m_axi_wvalid  = 'b000;
        // s_axi_bvalid = 0;

        // repeat(1) @(posedge clk);
        // m_axi_bready  = 'b000;


        // //master 2
        // repeat(7) @(posedge clk);
        // s_axi_awready = 1;
        // repeat(1) @(posedge clk);
        // s_axi_awready = 0;
        // s_axi_wready = 1;
        
        // repeat(1) @(posedge clk);
        // s_axi_wready = 0;
        // m_axi_awvalid = 'b000;
        // s_axi_bvalid = 1;

        // repeat(1) @(posedge clk);
        // m_axi_wvalid  = 'b000;
        // s_axi_bvalid = 0;

        // repeat(1) @(posedge clk);
        // m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 7: 3'b101////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b101;
        m_axi_wvalid  = 'b101;
        m_axi_bready  = 'b101;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b100;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b100;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 8: 3'b110////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b110;
        m_axi_wvalid  = 'b110;
        m_axi_bready  = 'b110;

        //master 0
        // repeat(7) @(posedge clk);
        // s_axi_awready = 1;
        // repeat(1) @(posedge clk);
        // s_axi_awready = 0;
        // s_axi_wready = 1;
        
        // repeat(1) @(posedge clk);
        // s_axi_wready = 0;
        // m_axi_awvalid = 'b110;
        // s_axi_bvalid = 1;

        // repeat(1) @(posedge clk);
        // m_axi_wvalid  = 'b110;
        // s_axi_bvalid = 0;

        // repeat(1) @(posedge clk);
        // m_axi_bready  = 'b110;


        //master 1
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b100;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b100;


        //master 2
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;
        

        //////////////////////////TEST CASE 9: 3'b111////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b111;
        m_axi_wvalid  = 'b111;
        m_axi_bready  = 'b111;
        m_axi_awprot_0 = 'b001; 
        m_axi_awprot_1 = 'b011; 
        m_axi_awprot_2 = 'b100;

        m_axi_wstrb_0 = 'b1111; 
        m_axi_wstrb_1 = 'b1101;
        m_axi_wstrb_2 = 'b1011;

        //master 0
        repeat(7) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b110;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b110;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b110;


        //master 1
        repeat(20) @(posedge clk);
        s_axi_awready = 0;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 0;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b100;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b100;


        //master 2
        repeat(5) @(posedge clk);
        s_axi_awready = 1;
        repeat(1) @(posedge clk);
        s_axi_awready = 0;
        s_axi_wready = 1;
        
        repeat(1) @(posedge clk);
        s_axi_wready = 0;
        m_axi_awvalid = 'b000;
        s_axi_bvalid = 1;

        repeat(1) @(posedge clk);
        m_axi_wvalid  = 'b000;
        s_axi_bvalid = 0;

        repeat(1) @(posedge clk);
        m_axi_bready  = 'b000;


        //////////////////////////TEST CASE 10: 3'b111////////////////////////////
        repeat(20) @(posedge clk);
        m_axi_awvalid = 'b111;
        m_axi_wvalid  = 'b111;
        m_axi_bready  = 'b111;
        m_axi_awprot_0 = 'b001; 
        m_axi_awprot_1 = 'b011; 
        m_axi_awprot_2 = 'b100;

        m_axi_wstrb_0 = 'b1111; 
        m_axi_wstrb_1 = 'b1101;
        m_axi_wstrb_2 = 'b1011;

    
        
        
    end

    // Monitor slave outputs
    always @(posedge clk) begin
        if (s_axi_awvalid && s_axi_awready)
            $display("Slave received AW: addr=%h, prot=%b at %0t", s_axi_awaddr, s_axi_awprot, $time);
        if (s_axi_wvalid && s_axi_wready)
            $display("Slave received W: data=%h, strb=%b at %0t", s_axi_wdata, s_axi_wstrb, $time);
        if (s_axi_bvalid && s_axi_bready)
            $display("Slave sent B response at %0t", $time);
    end

endmodule