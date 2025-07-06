`timescale 1ns / 1ps

module axi_slave #(
  parameter addr_width = 32,
  parameter data_width = 32,
  parameter id_width   = 4
)(
  input  wire                   clk,
  input  wire                   rst,
  // Write Address Channel
  input  wire [id_width-1:0]    awid,
  input  wire [addr_width-1:0]  awaddr,
  input  wire [7:0]             awlen,
  input  wire [2:0]             awsize,
  input  wire [1:0]             awburst,
  input  wire                   awvalid,
  output reg                    awready,
  // Write Data Channel
  input  wire [data_width-1:0]  wdata,
  input  wire [(data_width/8)-1:0] wstrb,
  input  wire                   wvalid,
  input  wire                   wlast,
  output reg                    wready,
  // Write Response Channel
  output reg [id_width-1:0]     bid,
  output reg [1:0]              bresp,
  output reg                    bvalid,
  input  wire                   bready,
  // Read Address Channel
  input  wire [id_width-1:0]    arid,
  input  wire [addr_width-1:0]  araddr,
  input  wire [7:0]             arlen,
  input  wire [2:0]             arsize,
  input  wire [1:0]             arburst,
  input  wire                   arvalid,
  output reg                    arready,
  // Read Data Channel
  input  wire                   rready,
  output reg [data_width-1:0]   rdata,
  output reg [id_width-1:0]     rid,
  output reg [1:0]              rresp,
  output reg                    rvalid,
  output reg                    rlast
);

  //-----------------------------------------------
  // Internal RAM
  //-----------------------------------------------
  reg [data_width-1:0] mem [0:1023];
  integer i;
  initial begin
    for(i = 0; i < 1024; i = i + 1)
      mem[i] = 32'hA5A5A5A5;
  end

  //-----------------------------------------------
  // Internal write signals
  //-----------------------------------------------
  reg [addr_width-1:0] awaddr_l;
  reg [7:0]            awlen_l;
  reg [7:0]            wcount;
  reg [id_width-1:0]   awid_l;
  reg                  last_beat_accepted;

  //-----------------------------------------------
  // Internal read signals
  //-----------------------------------------------
  reg [addr_width-1:0] araddr_l;
  reg [7:0]            arlen_l;
  reg [7:0]            rcount;
  reg [1:0]            rd_state;
  localparam RD_IDLE = 2'd0, RD_SEND = 2'd1;

  //-----------------------------------------------
  // Write Address Channel
  //-----------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      awready <= 1'b0;
    end else begin
      if (awvalid && !awready) begin
        awready  <= 1'b1;
        awaddr_l <= awaddr;
        awlen_l  <= awlen;
        awid_l   <= awid;
        wcount   <= 0;
        $display("TIME %0t: AW Handshake: ID=%0d ADDR=%h LEN=%0d", $time, awid, awaddr, awlen);
      end else begin
        awready <= 1'b0;
      end
    end
  end

  //-----------------------------------------------
  // Write Data Channel
  //-----------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wready   <= 1'b0;
      wcount   <= 0;
      last_beat_accepted <= 1'b0;
    end else begin
      if (wvalid && !wready) begin
        wready <= 1'b1;

        if ((awaddr_l[11:2] + wcount) < 1024) begin
          mem[awaddr_l[11:2] + wcount] <= wdata;
          $display("TIME %0t: W Handshake: Write MEM[%0d]=%h", $time, awaddr_l[11:2] + wcount, wdata);
        end else begin
          $display("TIME %0t: W ERROR! OOB write", $time);
        end

        wcount <= wcount + 1;

        if (wlast)
          last_beat_accepted <= 1'b1;
      end else begin
        wready <= 1'b0;
      end

      // clear marker if response accepted
      if (bvalid && bready)
        last_beat_accepted <= 1'b0;
    end
  end

  //-----------------------------------------------
  // Write Response Channel
  //-----------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      bvalid <= 1'b0;
      bid    <= {id_width{1'b0}};
      bresp  <= 2'b00;
    end else begin
      if (last_beat_accepted && !bvalid) begin
        bvalid <= 1'b1;
        bid    <= awid_l;
        bresp  <= 2'b00; // OKAY
        $display("TIME %0t: B Response: BID=%0d", $time, awid_l);
      end else if (bvalid && bready) begin
        bvalid <= 1'b0;
      end
    end
  end

  //-----------------------------------------------
  // Read Address Channel
  //-----------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      arready <= 1'b0;
    end else begin
      if (arvalid && !arready) begin
        arready <= 1'b1;
        araddr_l <= araddr;
        arlen_l  <= arlen;
        rcount   <= 0;
        rd_state <= RD_SEND;
        $display("TIME %0t: AR Handshake: ID=%0d ADDR=%h LEN=%0d", $time, arid, araddr, arlen);
      end else begin
        arready <= 1'b0;
      end
    end
  end

  //-----------------------------------------------
  // Read Data Channel
  //-----------------------------------------------
  always @(posedge clk or posedge rst) begin
  if (rst) begin
    arready  <= 0;
    rvalid   <= 0;
    rlast    <= 0;
    rcount   <= 0;
    rd_state <= RD_IDLE;
    rdata    <= 0;
    rid      <= 0;
    rresp    <= 0;
    araddr_l <= 0;
    arlen_l  <= 0;
  end else begin
    case (rd_state)
      RD_IDLE: begin
        rvalid <= 0;
        rlast  <= 0;
        if (arvalid && arready) begin
          araddr_l <= araddr;
          arlen_l  <= arlen;
          rcount   <= 0;
          rd_state <= RD_SEND;
          $display("TIME %0t: SLAVE_READ: AR Handshake. ARID=%0d, ARADDR=%h, ARLEN=%0d",
                   $time, arid, araddr, arlen);
        end
      end

      RD_SEND: begin
        if (!rvalid || (rvalid && rready)) begin
          // Correct: sample using rcount BEFORE increment
          if ((araddr_l[11:2] + rcount) < 1024)
            rdata <= mem[araddr_l[11:2] + rcount];
          else
            rdata <= 32'hDEAD_BEEF;

          rid   <= arid;
          rresp <= 2'b00;
          rvalid <= 1;
          rlast  <= (rcount == arlen_l);

          $display("TIME %0t: SLAVE_READ: Sending MEM[%0d]=%h RLAST=%0b",
                   $time, araddr_l[11:2] + rcount, rdata, (rcount == arlen_l));

          if (rcount == arlen_l) begin
            rd_state <= RD_IDLE;
          end else begin
            rcount <= rcount + 1;
          end
        end
      end
    endcase
  end
end

endmodule
