`timescale 1ns / 1ps

module axi_top_tb;

  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;
  parameter ID_WIDTH   = 4;

  reg clk, rst;

  reg start_wr, start_rd;
  reg [ADDR_WIDTH-1:0] wr_addr, rd_addr;
  reg [16*DATA_WIDTH-1:0] wr_data;
  reg [7:0] wr_len, rd_len;

  wire [16*DATA_WIDTH-1:0] rd_data;
  wire wr_done, rd_done;

  //----------------------------------------
  // DUT: axi_top
  //----------------------------------------
  axi_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH)
  ) dut (
    .clk(clk),
    .rst(rst),

    .start_wr(start_wr),
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_len(wr_len),
    .wr_done(wr_done),

    .start_rd(start_rd),
    .rd_addr(rd_addr),
    .rd_len(rd_len),
    .rd_data(rd_data),
    .rd_done(rd_done)
  );

  //----------------------------------------
  // Clock
  //----------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //----------------------------------------
  // Test Stimulus
  //----------------------------------------
  initial begin
    $display("=== AXI TOP TB START ===");
    rst = 1;
    start_wr = 0;
    start_rd = 0;
    wr_addr = 32'h0000_0000;
    rd_addr = 32'h0000_0000;
    wr_len = 3; // 4 beats total
    rd_len = 3;

    // 16 words, only bottom 4 used
wr_data = {
  384'd0,           // padding for top unused words
  32'h87654321,     // word3
  32'h12345678,     // word2
  32'hDEAD_BEEF,    // word1
  32'hFACE_CAFE     // word0
};

    #20 rst = 0;

    // Write
    #20 start_wr = 1;
    #10 start_wr = 0;

    wait (wr_done);
    $display("TB: WRITE DONE @ %0t", $time);

    // Read
    #50 start_rd = 1;
    #10 start_rd = 0;

    wait (rd_done);
    $display("TB: READ DONE @ %0t", $time);
    $display("TB: RD_DATA = %h", rd_data);

    // Check match
    if (rd_data[0 +: 32] !== 32'hFACE_CAFE) $display("TB: MISMATCH word0!");
    if (rd_data[32 +: 32] !== 32'hDEAD_BEEF) $display("TB: MISMATCH word1!");
    if (rd_data[64 +: 32] !== 32'h1234_5678) $display("TB: MISMATCH word2!");
    if (rd_data[96 +: 32] !== 32'h8765_4321) $display("TB: MISMATCH word3!");

    $display("=== AXI TOP TB END ===");
    #100 $finish;
  end

endmodule
