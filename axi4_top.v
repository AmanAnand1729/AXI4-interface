`timescale 1ns/ 1ps

module axi_top #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter ID_WIDTH   = 4
)(
  input  wire                   clk,
  input  wire                   rst,

  // User-side: write command
  input  wire                   start_wr,
  input  wire [ADDR_WIDTH-1:0]  wr_addr,
  input  wire [16*DATA_WIDTH-1:0] wr_data,
  input  wire [7:0]             wr_len,
  output wire                   wr_done,

  // User-side: read command
  input  wire                   start_rd,
  input  wire [ADDR_WIDTH-1:0]  rd_addr,
  input  wire [7:0]             rd_len,
  output wire [16*DATA_WIDTH-1:0] rd_data,
  output wire                   rd_done
);

  // Internal AXI signals
  wire awready, awvalid;
  wire [ID_WIDTH-1:0] awid;
  wire [ADDR_WIDTH-1:0] awaddr;
  wire [7:0] awlen;
  wire [2:0] awsize;
  wire [1:0] awburst;

  wire wready, wvalid, wlast;
  wire [DATA_WIDTH-1:0] wdata;
  wire [(DATA_WIDTH/8)-1:0] wstrb;

  wire [ID_WIDTH-1:0] bid;
  wire [1:0] bresp;
  wire bvalid, bready;

  wire [ID_WIDTH-1:0] arid;
  wire [ADDR_WIDTH-1:0] araddr;
  wire [7:0] arlen;
  wire [2:0] arsize;
  wire [1:0] arburst;
  wire arvalid, arready;

  wire [ID_WIDTH-1:0] rid;
  wire [DATA_WIDTH-1:0] rdata;
  wire [1:0] rresp;
  wire rvalid, rlast, rready;

  //----------------------------------------
  // Master
  //----------------------------------------
  axi_master #(
    .addr_width(ADDR_WIDTH),
    .data_width(DATA_WIDTH),
    .id_width(ID_WIDTH)
  ) master_inst (
    .clk(clk),
    .rst(rst),

    .awready(awready),
    .awvalid(awvalid),
    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),

    .wready(wready),
    .wvalid(wvalid),
    .wlast(wlast),
    .wdata(wdata),
    .wstrb(wstrb),

    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arvalid(arvalid),
    .arready(arready),

    .rid(rid),
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),

    .start_wr(start_wr),
    .start_rd(start_rd),
    .wr_addr(wr_addr),
    .rd_addr(rd_addr),
    .wr_data(wr_data),
    .rd_data(rd_data),
    .wr_len(wr_len),
    .rd_len(rd_len),
    .wr_done(wr_done),
    .rd_done(rd_done)
  );

  //----------------------------------------
  // Slave
  //----------------------------------------
  axi_slave #(
    .addr_width(ADDR_WIDTH),
    .data_width(DATA_WIDTH),
    .id_width(ID_WIDTH)
  ) slave_inst (
    .clk(clk),
    .rst(rst),

    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awvalid(awvalid),
    .awready(awready),

    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wlast(wlast),
    .wready(wready),

    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arvalid(arvalid),
    .arready(arready),

    .rready(rready),
    .rdata(rdata),
    .rid(rid),
    .rresp(rresp),
    .rvalid(rvalid),
    .rlast(rlast)
  );

endmodule
