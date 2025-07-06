`timescale 1ns / 1ps
module axi_master #(
  parameter addr_width = 32,
  parameter data_width = 32,
  parameter id_width   = 4
)(
  input clk, rst,

  // AXI Write Address
  input awready,
  output reg awvalid,
  output reg [id_width-1:0] awid,
  output reg [addr_width-1:0] awaddr,
  output reg [7:0] awlen,
  output reg [2:0] awsize,
  output reg [1:0] awburst,

  // AXI Write Data
  input wready,
  output reg wlast, wvalid,
  output reg [data_width-1:0] wdata,
  output reg [(data_width/8)-1:0] wstrb,

  // AXI Write Response
  input [id_width-1:0] bid,
  input [1:0] bresp,
  input bvalid,
  output reg bready,

  // AXI Read Address
  output reg [id_width-1:0] arid,
  output reg [addr_width-1:0] araddr,
  output reg [7:0] arlen,
  output reg [2:0] arsize,
  output reg [1:0] arburst,
  output reg arvalid,
  input arready,

  // AXI Read Data
  input [id_width-1:0] rid,
  input [data_width-1:0] rdata,
  input [1:0] rresp,
  input rlast, rvalid,
  output reg rready,

  // User I/F
  input start_wr, start_rd,
  input [addr_width-1:0] wr_addr, rd_addr,
  input [16*data_width-1:0] wr_data,
  output reg [16*data_width-1:0] rd_data,
  input [7:0] wr_len, rd_len,
  output reg wr_done, rd_done
);

  //---------------------------------------------
  // Write path
  //---------------------------------------------

  reg [2:0] wr_state;
  integer wr_cnt;
  reg [data_width-1:0] wr_data_arr [0:15];

  localparam wr_idle  = 3'd0,
             wr_aw    = 3'd1,
             wr_wdata = 3'd2,
             wr_bresp = 3'd3,
             wr_wdone = 3'd4;

  integer i;

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 16; i = i + 1)
        wr_data_arr[i] <= 0;
    end else if (start_wr) begin
      for (i = 0; i < 16; i = i + 1)
        wr_data_arr[i] <= wr_data[i*data_width +: data_width];
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wr_state <= wr_idle;
      awvalid  <= 0;
      awid     <= 0;
      wvalid   <= 0;
      wlast    <= 0;
      bready   <= 0;
      wr_done  <= 0;
      wr_cnt   <= 0;
    end else begin
      case (wr_state)
        wr_idle: begin
          wr_done <= 0;
          if (start_wr) begin
            awid   <= 4'd1; // ✅ ID fix
            awvalid <= 1;
            awaddr  <= wr_addr;
            awlen   <= wr_len;
            awsize  <= $clog2(data_width/8);
            awburst <= 2'b01; // incr
            wr_cnt  <= 0;
            wr_state <= wr_aw;
          end
        end

        wr_aw: begin
          if (awvalid && awready) begin
            awvalid <= 0;
            wvalid <= 1;
            wdata  <= wr_data_arr[0];
            wstrb  <= {(data_width/8){1'b1}};
            wlast  <= (wr_len == 0);
            wr_state <= wr_wdata;
          end
        end

        wr_wdata: begin
          if (wvalid && wready) begin
            wr_cnt <= wr_cnt + 1;
            if (wr_cnt == wr_len) begin
              wvalid <= 0;
              wlast  <= 0;
              bready <= 1;
              wr_state <= wr_bresp;
            end else begin
              wdata <= wr_data_arr[wr_cnt + 1];
              wlast <= (wr_cnt + 1 == wr_len);
            end
          end
        end

        wr_bresp: begin
          if (bvalid && bready) begin
            bready <= 0;
            wr_done <= 1;
            wr_state <= wr_wdone;
          end
        end

        wr_wdone: begin
          wr_done <= 0;
          wr_state <= wr_idle;
        end

      endcase
    end
  end

  //---------------------------------------------
  // Read path
  //---------------------------------------------

  reg [2:0] rd_state;
  integer rd_cnt, k;
  reg [data_width-1:0] rd_data_arr [0:15];

  localparam rd_idle  = 3'd0,
             rd_ar    = 3'd1,
             rd_rdata = 3'd2,
             rd_rdone = 3'd3;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      rd_state <= rd_idle;
      arvalid  <= 0;
      arid     <= 0;
      rready   <= 0;
      rd_done  <= 0;
      rd_cnt   <= 0;
    end else begin
      case (rd_state)
        rd_idle: begin
          rd_done <= 0;
          if (start_rd) begin
            arid <= 4'd1; // ✅ ID fix
            for (k = 0; k < 16; k = k + 1)
              rd_data_arr[k] <= 0;
            arvalid <= 1;
            araddr  <= rd_addr;
            arlen   <= rd_len;
            arsize  <= $clog2(data_width/8);
            arburst <= 2'b01;
            rd_cnt  <= 0;
            rd_state <= rd_ar;
          end
        end

        rd_ar: begin
          if (arvalid && arready) begin
            arvalid <= 0;
            rready  <= 1;
            rd_state <= rd_rdata;
          end
        end

        rd_rdata: begin
          if (rvalid && rready) begin
            rd_data_arr[rd_cnt] <= rdata;
            rd_cnt <= rd_cnt + 1;
            if (rlast) begin
              rready <= 0;
              rd_done <= 1;
              rd_state <= rd_rdone;
            end
          end
        end

        rd_rdone: begin
          rd_done <= 0;
          rd_state <= rd_idle;
        end

      endcase
    end
  end

  genvar j;
  generate
    for (j = 0; j < 16; j = j + 1) begin
      always @(*) begin
        rd_data[j*data_width +: data_width] = rd_data_arr[j];
      end
    end
  endgenerate

endmodule
