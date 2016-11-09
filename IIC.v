  module IIC(
			clk,rst_n,
		
			scl,sda,dir
		);

input clk;		// 50MHz
input rst_n;	//��λ�źţ�����Ч
output dir;     //sda����
output scl;		// 24C02��ʱ�Ӷ˿�
inout sda;		// 24C02�����ݶ˿�
/////////////////////////------------IICʱ��--------------//////////////////////////////////
reg[2:0] cnt;	// cnt=0:scl�����أ�cnt=1:scl�ߵ�ƽ�м䣬cnt=2:scl�½��أ�cnt=3:scl�͵�ƽ�м�
reg[8:0] cnt_delay;	//500ѭ������������iic����Ҫ��ʱ��
reg scl_r;		//ʱ������Ĵ���

always @ (posedge clk or negedge rst_n)
	if(!rst_n) cnt_delay <= 9'd0;
	else if(cnt_delay == 9'd499) cnt_delay <= 9'd0;	//������10usΪscl�����ڣ���100KHz
	else cnt_delay <= cnt_delay+1'b1;	//ʱ�Ӽ���

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) cnt <= 3'd5;
	else begin
		case (cnt_delay)
			9'd124:	cnt <= 3'd1;	//cnt=1:scl�ߵ�ƽ�м�,�������ݲ���
			9'd249:	cnt <= 3'd2;	//cnt=2:scl�½���
			9'd374:	cnt <= 3'd3;	//cnt=3:scl�͵�ƽ�м�,�������ݱ仯
			9'd499:	cnt <= 3'd0;	//cnt=0:scl������
			default: cnt <= 3'd5;
			endcase
		end
end


`define SCL_POS		(cnt==3'd0)		//cnt=0:scl������
`define SCL_HIG		(cnt==3'd1)		//cnt=1:scl�ߵ�ƽ�м�,�������ݲ���
`define SCL_NEG		(cnt==3'd2)		//cnt=2:scl�½���
`define SCL_LOW		(cnt==3'd3)		//cnt=3:scl�͵�ƽ�м�,�������ݱ仯

always @ (posedge clk or negedge rst_n)
	if(!rst_n) scl_r <= 1'b0;
	else if(cnt==3'd0) scl_r <= 1'b1;	//scl�ź�������
   	else if(cnt==3'd2) scl_r <= 1'b0;	//scl�ź��½���

assign scl = scl_r;	//����iic����Ҫ��ʱ��
/////////////////////////////////////////////////////////////////////////////
`define	DEVICE_READ	8'b0100_1001	//��Ѱַ������ַ����������
`define DEVICE_WRITE	8'b0100_1000	//��Ѱַ������ַ��д������

`define	WRITE_DATA	8'b0000_0000	//д��EEPROM������
`define BYTE_ADDR		8'b0000_0000	//д��/����EEPROM�ĵ�ַ�Ĵ���	
reg[7:0] db_r;		//��IIC�ϴ��͵����ݼĴ���
reg[7:0] read_data;	//����EEPROM�����ݼĴ���
reg[7:0] sub_address=8'b00000000;

//---------------------------------------------
		//����дʱ��
parameter 	IDLE 	= 4'd0;
parameter 	START1 	= 4'd1;
parameter 	ADD1 	= 4'd2;
parameter 	ACK1 	= 4'd3;
parameter 	ADD2 	= 4'd4;
parameter 	ACK2 	= 4'd5;
parameter 	START2 	= 4'd6;
parameter 	ADD3 	= 4'd7;
parameter 	ACK3	= 4'd8;
parameter 	DATA 	= 4'd9;
parameter 	ACK4	= 4'd10;
parameter 	STOP1 	= 4'd11;
parameter 	STOP2 	= 4'd12;

reg[3:0] cstate;	//״̬�Ĵ���
reg sda_r;		//������ݼĴ���
reg dir;	//�������sda�ź�inout�������λ		
reg[3:0] num;	//

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			cstate <= IDLE;
			sda_r <= 1'b1;
			dir <= 1'b0;
			num <= 4'd0;
			read_data <= 8'b0000_0000;
		end
	else 	  
		case (cstate)
			IDLE:	begin
					dir <= 1'b1;			//������sdaΪoutput
					sda_r <= 1'b1;
							
						db_r <= `DEVICE_WRITE;	//��������ַ��д������
						cstate <= START1;		
						
					
				end
			START1: begin
					if(`SCL_HIG) begin		//sclΪ�ߵ�ƽ�ڼ�
						dir <= 1'b1;	//������sdaΪoutput
						sda_r <= 1'b0;		//����������sda��������ʼλ�ź�
						cstate <= ADD1;
						num <= 4'd0;		//num��������
						end
					else cstate <= START1; //�ȴ�scl�ߵ�ƽ�м�λ�õ���
				end
			ADD1:	begin
					if(`SCL_LOW) begin
							if(num == 4'd8) begin	
									num <= 4'd0;			//num��������
									sda_r <= 1'b1;
									dir <= 1'b0;		//sda��Ϊ����̬(input)
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
							//		sda_r <= db_r[4'd7-num];	//��������ַ���Ӹ�λ��ʼ
								end
						end
			//		else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};	//������ַ����1bit
					else cstate <= ADD1;
				end
			ACK1:	begin
					if(/*!sda*/`SCL_NEG) begin	//ע��24C01/02/04/08/16�������Բ�����Ӧ��λ
							cstate <= ADD2;	//�ӻ���Ӧ�ź�
							db_r <= 8'h00;	// 1��ַ		
						end
					else cstate <= ACK1;		//�ȴ��ӻ���Ӧ
				end
			ADD2:	begin
					if(`SCL_LOW) begin
							if(num==4'd8) begin	
									num <= 4'd0;			//num��������
									sda_r <= 1'b1;
									dir <= 1'b0;		//sda��Ϊ����̬(input)
									cstate <= ACK2;
								end
							else begin
									dir <= 1'b1;		//sda��Ϊoutput
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
							//		sda_r <= db_r[4'd7-num];	//��EEPROM��ַ����bit��ʼ��		
									cstate <= ADD2;					
								end
						end
			//		else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};	//������ַ����1bit
					else cstate <= ADD2;				
				end
			ACK2:	begin
					if(/*!sda*/`SCL_NEG) begin		//�ӻ���Ӧ�ź�
						
								cstate <= DATA; 	//д����
								db_r<=8'h10;			//д�������			
								

					
						end
					else cstate <= ACK2;	//�ȴ��ӻ���Ӧ
				end
			
			
			DATA:	begin
					//д����
							dir <= 1'b1;	
							if(num<=4'd7) begin
								cstate <= DATA;
								if(`SCL_LOW) begin
									dir <= 1'b1;		//������sda��Ϊoutput
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
								//	sda_r <= db_r[4'd7-num];	//д�����ݣ���bit��ʼ��
									end
			//					else if(`SCL_POS) db_r <= {db_r[6:0],1'b0};	//д����������1bit
							 	end
							else if((`SCL_LOW) && (num==4'd8)) begin
									num <= 4'd0;
									sda_r <= 1'b1;
									dir <= 1'b0;		//sda��Ϊ����̬
									cstate <= ACK4;
								end
							else cstate <= DATA;
						
				end
			ACK4: begin
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
					else cstate <= ACK4;
				end
			STOP1:	begin
					if(`SCL_LOW) begin
					
							dir <= 1'b1;
							sda_r <= 1'b0;
							cstate <= STOP1;
						end
					else if(`SCL_HIG) begin
							sda_r <= 1'b1;	//sclΪ��ʱ��sda���������أ������źţ�
							cstate<=STOP2;
						end
					else cstate <= STOP1;
				end
			STOP2:	begin
					if(`SCL_LOW) 
					begin 
					sda_r <= 1'b1;
			      
					 cstate <= IDLE;
					 end
				end
			default: cstate <= IDLE;
			endcase
end

assign sda = dir ? sda_r:1'bz;




endmodule


