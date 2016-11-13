# SAA7111A-FPGA
This project gives the solition using Verilog HDL communicating between SAA7111A and FPGA.

IIC file build the communications using IIC between SAA7111A(video decoding chip) and FPGA. This file contains only the intial wirte operations using IIC. The user can change the data to be sent to the subaddress in SAA7111A in the file in the ACK3 state.

RGB file gives an easy example of the process after getting the video format signal from SAA7111A. What RGB basiclly did is to convert the video format into 8 bit RGB for further processing.
