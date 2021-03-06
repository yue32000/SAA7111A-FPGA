/*
main module for SAA7111A and FPGA
*/
module SAA7111(llc,HREF,VREF,VPO15,VPO14,VPO13,VPO12,VPO11,VPO10,VPO9,VPO8,VPO7,VPO6,VPO5,VPO4,VPO3,VPO2,VPO1,VPO0,SCL,SDA,CLK,LED);
input llc,HREF,VREF,VPO15,VPO14,VPO13,VPO12,VPO11,VPO10,VPO9,VPO8,VPO7,VPO6,VPO5,VPO4,VPO3,VPO2,VPO1,VPO0,SCL,SDA,CLK;
output[1:0] LED;
IIC IIC(
			.clk(CLK),.rst_n(),
		
			.scl(SCL),.sda(SDA),.dir()
		  );
RGB RGB(.llc(llc),.HREF(HREF),.VREF(VREF),.VPO15(VPO15),.VPO14(VPO14),
         .VPO13(VPO13),.VPO12(VPO12),.VPO11(VPO11),.VPO10(VPO10),.VPO9(VPO9),
			.VPO8(VPO8),.VPO7(VPO7),.VPO6(VPO6),.VPO5(VPO5),.VPO4(VPO4),.VPO3(VPO3),
			 .VPO2(VPO2),.VPO1(VPO1),.VPO0(VPO0),.led(LED));
			endmodule
			