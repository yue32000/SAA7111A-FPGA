  /*
  This module defines the IIC bus between SAA7111A and FPGA. The FPGA writes all the commend to SAA7111A.
  */
module IIC(clk,rst_n,scl,sda);
input clk;		// 50MHz input clock
input rst_n;	//reset signal,module active when low
output scl;		
inout sda;		
/////////////////////////------------IIC CLOCK GENERATOR--------------//////////////////////////////////
reg[2:0] cnt;	// counting four state of SCL signal 0:posedge 1:high 2:negeage 3:low
reg[8:0] cnt_delay;	//counter
reg scl_r;	
//counter of 500
always @ (posedge clk or negedge rst_n)
	if(!rst_n) cnt_delay <= 9'd0;
	else if(cnt_delay == 9'd499) cnt_delay <= 9'd0;	
	else cnt_delay <= cnt_delay+1'b1;	
//counting four state of SCL
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) cnt <= 3'd5;
	else begin
		case (cnt_delay)
			9'd124:	cnt <= 3'd1;	//cnt=1:scl high middle point
			9'd249:	cnt <= 3'd2;	//cnt=2:scl negeage
			9'd374:	cnt <= 3'd3;	//cnt=3:scl low middle point
			9'd499:	cnt <= 3'd0;	//cnt=0:scl posedge
			default: cnt <= 3'd5;
			endcase
		end
end


`define SCL_POS		(cnt==3'd0)		//cnt=0:scl posedge
`define SCL_HIG		(cnt==3'd1)		//cnt=1:scl high middle point 
`define SCL_NEG		(cnt==3'd2)		//cnt=2:scl negeage
`define SCL_LOW		(cnt==3'd3)		//cnt=3:scl low middle point
// SCL generator
always @ (posedge clk or negedge rst_n)
	if(!rst_n) scl_r <= 1'b0;
	else if(cnt==3'd0) scl_r <= 1'b1;	//scl set to high when posedge comes
   	else if(cnt==3'd2) scl_r <= 1'b0;	//scl set to low when negeage comes
	
assign scl = scl_r;	
/////////////////////////////////////////////////////////////////////////////
//
`define	DEVICE_READ	8'b0100_1001	//read address of SAA7111A
`define DEVICE_WRITE	8'b0100_1000	//write address of SAA7111A
`define	WRITE_DATA	8'b0000_0000	//first address to be written in SAA7111A
reg[7:0] db_r;		//register for data to be sent through IIC
reg[7:0] sub_address=8'b00000000;//address of registers to be written in SAA7111A

//--------------------------------------------
parameter 	IDLE 	= 4'd0;//initial state
parameter 	START1= 4'd1;//start signal of transmitting
parameter 	ADD1 	= 4'd2;//device address
parameter 	ACK1 	= 4'd3;//acknowlegement
parameter 	ADD2 	= 4'd4;//subaddress1
parameter 	ACK2 	= 4'd5;//acknowlegement
parameter 	DATA 	= 4'd6;//data transmiting
parameter 	ACK3	= 4'd7;//acknowlegement
parameter 	STOP1 	= 4'd8;//stop signal of transmitting
parameter 	STOP2 	= 4'd9;//

reg[3:0] cstate;	//state register
reg sda_r;		   //sda register 
reg dir;	         //sda direction indicator		
reg[3:0] num;	   //number of bit to be sent
//IIC bus timing for writing DATA to SAA7111A subaddresses
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			cstate <= IDLE;
			sda_r <= 1'b1;
			dir <= 1'b0;
			num <= 4'd0;
		end
	else 	  
		case (cstate)
			IDLE:	begin
					dir <= 1'b1;			
					sda_r <= 1'b1;
							
						db_r <= `DEVICE_WRITE;	
						cstate <= START1;		
						
					
				end
			START1: begin
					if(`SCL_HIG) begin		
						dir <= 1'b1;	
						sda_r <= 1'b0;		
						cstate <= ADD1;
						num <= 4'd0;		
						end
					else cstate <= START1; 
				end
			ADD1:	begin
					if(`SCL_LOW) begin
							if(num == 4'd8) begin	
									num <= 4'd0;			
									sda_r <= 1'b1;
									dir <= 1'b0;		
									cstate <= ACK1;
								end
							else begin
									cstate <= ADD1;
									num <= num+1'b1;
									case (num)
										4'd0: sda_r <= db_r[7];
										4'd1: sda_r <= db_r[6];
										4'd2: sda_r <= db_r[5];
										4'd3: sda_r <= db_r[4];
										4'd4: sda_r <= db_r[3];
										4'd5: sda_r <= db_r[2];
										4'd6: sda_r <= db_r[1];
										4'd7: sda_r <= db_r[0];
										default: ;
										endcase
							
								end
						end
			
					else cstate <= ADD1;
				end
			ACK1:	begin
					if(/*!sda*/`SCL_NEG) begin	
							cstate <= ADD2;	
							db_r <= 8'h00;		
						end
					else cstate <= ACK1;		
				end
			ADD2:	begin
					if(`SCL_LOW) begin
							if(num==4'd8) begin	
									num <= 4'd0;			
									sda_r <= 1'b1;
									dir <= 1'b0;		
									cstate <= ACK2;
								end
							else begin
									dir <= 1'b1;		
									num <= num+1'b1;
									case (num)
										4'd0: sda_r <= db_r[7];
										4'd1: sda_r <= db_r[6];
										4'd2: sda_r <= db_r[5];
										4'd3: sda_r <= db_r[4];
										4'd4: sda_r <= db_r[3];
										4'd5: sda_r <= db_r[2];
										4'd6: sda_r <= db_r[1];
										4'd7: sda_r <= db_r[0];
										default: ;
										endcase
									cstate <= ADD2;					
								end
						end
					else cstate <= ADD2;				
				end
			ACK2:	begin
					if(/*!sda*/`SCL_NEG) begin		
						
								cstate <= DATA; 	
								db_r<=8'h10;	//written data	
						end
					else cstate <= ACK2;	
				end
			
			
			DATA:	begin
					//write
							dir <= 1'b1;	
							if(num<=4'd7) begin
								cstate <= DATA;
								if(`SCL_LOW) begin
									dir <= 1'b1;		
									num <= num+1'b1;
									case (num)
										4'd0: sda_r <= db_r[7];
										4'd1: sda_r <= db_r[6];
										4'd2: sda_r <= db_r[5];
										4'd3: sda_r <= db_r[4];
										4'd4: sda_r <= db_r[3];
										4'd5: sda_r <= db_r[2];
										4'd6: sda_r <= db_r[1];
										4'd7: sda_r <= db_r[0];
										default: ;
										endcase																	
									end	
							 	end
							else if((`SCL_LOW) && (num==4'd8)) begin
									num <= 4'd0;
									sda_r <= 1'b1;
									dir <= 1'b0;		
									cstate <= ACK3;
								end
							else cstate <= DATA;
						
				end
			ACK3: begin
					if(/*!sda*/`SCL_NEG) begin
//						sda_r <= 1'b1;
case(sub_address)
   8'h00:
	          begin 
	          sub_address<=8'h01;
				 db_r <=8'b00000000; 
				 cstate <= DATA;
	          end
	8'h01:
	          begin 
	          sub_address<=8'h02;
				 db_r <=8'b11000000; 
				 cstate <= DATA;
	          end
	8'h02:
	          begin 
				 sub_address<=8'h03;
				 db_r<=8'b00100011;
				 cstate<=DATA;
				 end
	8'h03:
	          begin
				sub_address<=8'h04; 
				 db_r<=8'b00000000;
				 cstate<=DATA;
				 end
	8'h04:
	          begin 
				 sub_address<=8'h05;
				 db_r<=8'b00000000;
				 cstate<=DATA;
				 end
	8'h05:
	          begin 
				 sub_address<=8'h06;
				 db_r<=8'b11101011;//horizontal sync begin
				 cstate<=DATA;
				 end
	8'h06:
	          begin 
				 sub_address<=8'h07;
				 db_r<=8'b11100000;//horizontal sync stop
				 cstate<=DATA;
				 end
	8'h07:
	          begin 
				 sub_address<=8'h08;
				 db_r<=8'b1x001000;
				 cstate<=DATA;
				 end
	8'h08:
	          begin 
				 sub_address<=8'h09;
				 db_r<=8'b00000001;
				 cstate<=DATA;
				 end
	8'h09:
	          begin 
				 sub_address<=8'h0A;
				 db_r<=10000000;
				 cstate<=DATA;
				 end
	8'h0A:
	          begin 
				 sub_address<=8'h0B;
				 db_r<=01000111;
				 cstate<=DATA;
				 end
	8'h0B:
	          begin
				sub_address<=8'h0C; 
				 db_r<=01000000;
				 cstate<=DATA;
				 end
	8'h0C:
	          begin 
				 sub_address<=8'h0D;
				 db_r<=00000000;
				 cstate<=DATA;
				 end
	8'h0D:
	          begin 
				 sub_address<=8'h0E;
				 db_r<=00000001;
				 cstate<=DATA;
				 end
	8'h0E:
	          begin 
				 sub_address<=8'h0F;
				 db_r<=8'b00000000;
				 cstate<=DATA;
				 end
	8'h0F:
	          begin 
				 sub_address<=8'h10;
				 db_r<=8'b00000x00;
				 cstate<=DATA;
				 end			 
	8'h10:
	          begin 
				 sub_address<=8'h11;
				 db_r<=00001100;
				 cstate<=DATA;
				 end
	8'h11:
	          begin 
				 sub_address<=8'h12;
				 db_r<=00001001;
				 cstate<=DATA;
				 end
	8'h12:
	          begin 
				 sub_address<=8'h13;
				 db_r<=00000000;
				 cstate<=DATA;
				 end
	8'h13:
	          begin
				sub_address<=8'h14; 
				 db_r<=00000000;
				 cstate<=DATA;
				 end
   8'h14:
	          begin
				sub_address<=8'h15; 
				 db_r<=00000000;
				 cstate<=DATA;
				 end
	8'h15:
	          begin 
				 sub_address<=8'h16; 
				 db_r<=00000000;
				 cstate<=DATA;
				 end
	8'h16:
	          begin 
				 sub_address<=8'h17; 
				 db_r<=00000000;
				 cstate<=DATA;
				 end

	8'h17:
	          begin 
				 sub_address<=8'h00; 
				
				 cstate<=STOP1;
				 end
	
	endcase
												
						end
					else cstate <= ACK3;
				end
			STOP1:	begin
					if(`SCL_LOW) begin
					
							dir <= 1'b1;
							sda_r <= 1'b0;
							cstate <= STOP1;
						end
					else if(`SCL_HIG) begin
							sda_r <= 1'b1;	//when scl is HIGH, pull to SDA to HIGH to give an end signal.
							cstate<=STOP2;
						end
					else cstate <= STOP1;
				end
			STOP2:	begin
					if(`SCL_LOW) 
					begin 
					sda_r <= 1'b1;
			      
					 cstate <= STOP2;
					 //cstate<= IDLE;
					 end
				end
			default: cstate <= IDLE;
			endcase
end

assign sda = dir ? sda_r:1'bz;
endmodule


