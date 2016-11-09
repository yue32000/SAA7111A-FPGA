module RGB(llc,HREF,VREF,VPO15,VPO14,VPO13,VPO12,VPO11,VPO10,VPO9,VPO8,VPO7,VPO6,VPO5,VPO4,VPO3,VPO2,VPO1,VPO0,led);
input llc,HREF,VREF,VPO15,VPO14,VPO13,VPO12,VPO11,VPO10,VPO9,VPO8,VPO7,VPO6,VPO5,VPO4,VPO3,VPO2,VPO1,VPO0;
output reg[1:0] led;
reg cnt=1'b0;
reg[7:0]R,G,B,TEMP;
reg flag;
reg[15:0] count_href,count_vref;
reg[23:0] cnt_R,cnt_G,cnt_B;
`define thr 8'b10000000
always@(posedge llc)
  begin 
  if(VREF&&count_vref<286)begin
  flag=1'b1;
    if(HREF&&count_href<720)
     begin
	  case (cnt)         
          1'b0:begin
			      
					TEMP[7:0]={VPO7,VPO6,VPO5,VPO4,VPO3,VPO2,VPO1,VPO0};
					cnt=cnt+1;
					if(R>`thr)
					cnt_R=cnt_R+1;
					if(G>`thr)
					cnt_G=cnt_G+1;
					if(B>`thr)
					cnt_B=cnt_B+1;
					end
			 1'b1:begin
			      R[7:0]={VPO15,VPO14,VPO13,VPO12,VPO11,TEMP[7],TEMP[6],TEMP[5]};
					G[7:0]={VPO10,VPO9,VPO8,VPO7,VPO6,VPO5,TEMP[4],TEMP[3]};
               B[7:0]={VPO4,VPO3,VPO2,VPO1,VPO0,TEMP[2],TEMP[1],TEMP[0]};
					cnt=cnt+1;
					count_href=count_href+1;
					end          
      endcase
		end
		else begin
		     count_href=0;
		     count_vref=count_vref+1;
			  end
		end
	else begin
	        count_vref=0;
		       if(flag==1'b1)begin
		  
		            if(cnt_R>cnt_G)begin
		     if(cnt_R>cnt_B)
			  led=2'b01;//ºìµÆ
			  else if(cnt_R<cnt_B)
			  led=2'b10;//À¶µÆ
			  else led=2'b00;//error
			  end
			         else if(cnt_R<cnt_G)begin
			       if(cnt_G>cnt_B)
					 led=2'b11;//ÂÌµÆ
					 else if(cnt_G<cnt_B)
					 led=2'b10;//À¶µÆ
					 else 
					 led=2'b00;//error
					 end 
					   else led=2'b00;//error
					          cnt_R=0;
					          cnt_G=0;
					          cnt_B=0;
								 flag=0;
				end	
			else flag=0;	
		  end	  
   end
	endmodule
