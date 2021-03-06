//*******************************************************************************
//
//	File:		omap_bus.v
//	Author:		Kevin Moon & Pete Scott
//	Data:		
//
//	COLDFIRE BUS INTERFACE MODULE
//
//	Connection Diagram:
//
//	Processor bus:
//	omap_bus_clk			bus clock
//	omap_cs_l				chip select
//	omap_oe_l				output enable
//	omap_wr_l				write strobe
//	omap_a[3:1]				address bus
//	omap_d[15:0]			bidirectional data bus
//
//	host bus:
//	host_addr[15:0]			register address
//	host_rd_data[15:0]		read data
//	host_wr_data[15:0]		write data
//	host_rd_en				read enable
//	host_wr_en				write enable
//
//*******************************************************************************

`include	"timescale.v"
`include	"reg_defs.v"

module omap_bus (
// coldfire bus:
				omap_cs_l,				// chip select
				omap_oe_l,				// output enable
				omap_wr_l,				// write strobe
				omap_a,					// address bus.
				omap_d,					// bidirectional data bus.
				omap_gpmc_clk,			// bus clock from the omap processor			
//  host bus:
				host_clk,
				host_rst_l,
				host_addr,
				host_rd_data,
				host_wr_data,
				host_rd_en,
				host_wr_en,
// control:
				sys_rst_l
		
		);

// Omap bus:

input			omap_cs_l;
input			omap_oe_l;
input			omap_wr_l;
input	[3:0]	omap_a;
inout	[15:0]	omap_d;
input			omap_gpmc_clk;

//  host bus:

input			host_clk;
input			host_rst_l;
output	[15:0]	host_addr;
input	[15:0]	host_rd_data;
output	[15:0]	host_wr_data;
output			host_rd_en;
output			host_wr_en;

// control:
output			sys_rst_l;

// coldfire bus:

wire			omap_cs_l;
wire			omap_oe_l;
wire			omap_wr_l;
wire	[3:0]	omap_a;
tri		[15:0]	omap_d;

//  host bus:

wire			host_clk;
wire			host_rst_l;
reg		[15:0]	host_addr;
wire	[15:0]	host_rd_data;
reg		[15:0]	host_wr_data;
reg				host_rd_en;
reg				host_wr_en;

reg 			sys_rst_l;

// internal wiring

reg		[15:0]	rd_data;
reg				cs_0;
reg				cs_1;
reg				wr;
wire			addr_sel;
reg		[1:0]	omap_cs_shift;

// generate chip reset
// write to reset reg

//**
// generate chip reset
// assert reset when the omap writes to address 0x2 (3'b001)
// deassert reset when the write cycle is finished
// synchronise on gpmc_clk to avoid metastability issues on address lines
// at the beginning of the communication cycle

always @(posedge omap_gpmc_clk or posedge omap_cs_l)
begin
	if (omap_cs_l)
		sys_rst_l <= 1;
	else
		//sys_rst_l <= ~(~omap_cs_l & ~omap_wr_l & ({omap_a[3:1],1'b0} == `FPGA_RESET));
		sys_rst_l <= ~(~omap_cs_l & ~omap_wr_l & ({omap_a[3:0]} == `FPGA_RESET));
end

//

always @(posedge host_clk or negedge host_rst_l)
begin
	if (~host_rst_l)
		omap_cs_shift <= 2'b11;
	else
	begin
		omap_cs_shift [0] <= omap_cs_l;
		omap_cs_shift [1] <= omap_cs_shift [0];
	end
end

always @(negedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		cs_0 <= 0;
	else
		cs_0 <= ~omap_cs_shift[1];//~omap_cs_shift[3];//~omap_cs_l;
		
always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		cs_1 <= 0;
	else
		cs_1 <= cs_0;

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		wr <= 0;
	else
		wr <= ~omap_wr_l;

// host read strobe

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		host_rd_en <= 0;
	else
		host_rd_en <= cs_0 & ~cs_1 & ~wr;

// host write strobe

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		host_wr_en <= 0;
	else
		host_wr_en <= cs_0 & ~cs_1 & wr;

// host address bus
// lower 3 bits come from bus
// upper bits come from address register

assign addr_sel = (host_addr[3:0] == `FPGA_ADDR) & host_wr_en;

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		host_addr[3:0] <= 0;
	else
		//host_addr[3:0] <= { omap_a[3:1], 1'b0 };
		host_addr[3:0] <= { omap_a[3:0] };

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		host_addr[15:4] <= 0;
	else if (addr_sel)
		host_addr[15:4] <= host_wr_data[15:4];

// host write data bus

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		host_wr_data[15:0] <= 0;
	else
		host_wr_data[15:0] <= omap_d[15:0];

// host read data bus

always @(posedge host_clk or negedge host_rst_l)
	if (~host_rst_l)
		rd_data[15:0] <= 0;
	else if (host_rd_en)
		rd_data[15:0] <= host_rd_data[15:0];

// tri state driver read data onto data bus

lpm_bustri	iJBUS_TRI (	.tridata (omap_d[15:0]),
			.data (rd_data[15:0]),
			.enabledt (~omap_cs_l & ~omap_oe_l));
defparam
	iJBUS_TRI.lpm_width = 16,
	iJBUS_TRI.lpm_type = "LPM_BUSTRI";

endmodule
