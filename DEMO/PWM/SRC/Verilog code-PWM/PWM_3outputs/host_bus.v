//*********************************************************************
//
//	File:		host_bus.v
//
//	Created for the PWM example
//
//*********************************************************************

`include "timescale.v"

module host_bus (
// host bus
				host_rst_l,
				host_clk,
				host_addr,
				host_rd_data,
				host_wr_data,
				host_rd_en,
				host_wr_en,
// host_ctrl bus
				host_ctrl_addr,
				host_ctrl_rd_data,
				host_ctrl_wr_data,
				host_ctrl_cs,
				host_ctrl_rd_en,
				host_ctrl_wr_en,
// vid_imager bus
				vid_imager_addr,
				vid_imager_rd_data,
				vid_imager_wr_data,
				vid_imager_cs,
				vid_imager_rd_en,
				vid_imager_wr_en
);

// host bus

input			host_rst_l;
input			host_clk;
input	[15:0]	host_addr;
output	[15:0]	host_rd_data;
input	[15:0]	host_wr_data;
input			host_rd_en;
input			host_wr_en;

// host_ctrl bus

output	[15:0]	host_ctrl_addr;
input	[15:0]	host_ctrl_rd_data;
output	[15:0]	host_ctrl_wr_data;
output			host_ctrl_cs;
output			host_ctrl_rd_en;
output			host_ctrl_wr_en;

// vid_imager bus

output	[15:0]	vid_imager_addr;
input	[15:0]	vid_imager_rd_data;
output	[15:0]	vid_imager_wr_data;
output			vid_imager_cs;
output			vid_imager_rd_en;
output			vid_imager_wr_en;

// read multiplexer registers

reg		[15:0]	host_rd_data;

// host_ctrl output ports

assign host_ctrl_cs = (host_addr[15:4] == 12'h001);
assign host_ctrl_addr = host_addr;
assign host_ctrl_wr_data = host_wr_data;
assign host_ctrl_wr_en = host_wr_en;
assign host_ctrl_rd_en = host_rd_en;

// vid_imager output ports

assign vid_imager_cs = (host_addr[15:4] == 12'h002);
assign vid_imager_addr = host_addr;
assign vid_imager_wr_data = host_wr_data;
assign vid_imager_wr_en = host_wr_en;
assign vid_imager_rd_en = host_rd_en;

// read bus multiplexer

always @ (
	 host_ctrl_cs or host_ctrl_rd_data or
	 vid_imager_cs or vid_imager_rd_data 
	 )
begin
	if (host_ctrl_cs)
		host_rd_data = host_ctrl_rd_data;
	else if (vid_imager_cs)
		host_rd_data = vid_imager_rd_data;
	else
		host_rd_data = 0;
end

endmodule
