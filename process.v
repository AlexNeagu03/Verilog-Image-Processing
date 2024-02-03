`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output reg [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output reg out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output reg [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output reg mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output reg gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output reg filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)


	parameter IDLE=5'b00000;
	parameter Read_first_pixel= 5'b00001;
	parameter Read_last_pixel_write_first_pixel =5'b00010;
	parameter Write_last_pixel= 5'b00011;
	parameter Inc_index =5'b00100;
	parameter Done = 5'b00101;
	parameter Initial_gray = 5'b00110;
	parameter Read_pixel = 5'b00111;
	parameter Maxim_Minim_calculus = 5'b01000;
	parameter Write_average = 5'b01001;
	parameter gray_increment = 5'b01010;
	parameter donegr = 5'b01011;
	parameter initial_sharpness = 5'b01100;
	parameter read_first_pixel_sharp = 5'b01101;
	parameter read_neighbour1 = 5'b01110;
	parameter read_neighbour2 = 5'b01111;
	parameter read_neighbour3 = 5'b10000;
	parameter read_neighbour4 = 5'b10001;
	parameter read_neighbour5 = 5'b10010;
	parameter read_neighbour6 = 5'b10011;
	parameter read_neighbour7 = 5'b10100;
	parameter read_neighbour8 = 5'b10101;
	parameter output_pixel_calculus = 5'b10110;
	parameter sharpness_increment = 5'b10111;
	parameter sharp_done = 5'b11000;

	reg [4:0] state = IDLE, next_state;
	reg [5:0] row_index, col_index;
	reg [23:0] fpix, lpix;
	reg [23:0] pixel;
	reg [7:0] maxim, minim;
	reg [23:0] neighbour1, neighbour2, neighbour3, neighbour4, neighbour5, neighbour6, neighbour7, neighbour8, pixel_sharp;


always @(posedge clk) begin
	state <= next_state;
	row <= row_index;
	col <= col_index;
end

always @(*) begin
	case (state)
	
	
		IDLE: begin
			mirror_done = 0;
			out_we = 0;
			
			row_index = 0;
			col_index = 0;
			
			next_state = Read_first_pixel;
		end
		
		
		
		Read_first_pixel: begin
			fpix = in_pix;
			
			row_index = 63 - row; 
			col_index = col;
			
			next_state = Read_last_pixel_write_first_pixel;
		end
		
		
		Read_last_pixel_write_first_pixel: begin
			lpix = in_pix;
			
			row_index = 63 - row;
			col_index = col;
			
			out_we = 1;
			out_pix = fpix;
			
			next_state = Write_last_pixel;
		end
		
		
		Write_last_pixel: begin
			out_we = 1;
			out_pix = lpix;
			
			row_index = row;
			col_index = col;
		
			next_state = Inc_index;
		end
		
		
		Inc_index: begin
			next_state = (row == 31 && col == 63) ? Done : Read_first_pixel; 
						
			if (row<31) begin
				row_index = row + 1;
			end else begin
				if (col<63) begin
					col_index = col + 1;
					row_index = 0;
				end
			end
		end
		
		
		Done: begin
			out_we = 0;
			mirror_done = 1;
			next_state = Initial_gray;
		end
		
		
		Initial_gray:begin
			gray_done = 0;
			out_we = 0;
			row_index = 0;
			col_index = 0;
			next_state = Read_pixel;
		end
		
		
		Read_pixel:begin	
			pixel = in_pix;
			next_state = Maxim_Minim_calculus;
		end
		
		
		Maxim_Minim_calculus:begin
			maxim = (pixel[23:16] >= pixel[15:8]) ? 
							((pixel[23:16] >= pixel[7:0]) ? pixel[23:16] : pixel[7:0]) : 
							((pixel[15:8] >= pixel[7:0]) ? pixel[15:8] : pixel[7:0]);
							
			minim =  (pixel[23:16] <= pixel[15:8]) ? 
							((pixel[23:16] <= pixel[7:0]) ? pixel[23:16] : pixel[7:0]) : 
							((pixel[15:8] <= pixel[7:0]) ? pixel[15:8] : pixel[7:0]);
										
				
			next_state = Write_average;
		
		end
		
		Write_average:begin
			out_we = 1;
			
			out_pix = {8'b0, (maxim + minim) /2, 8'b0}; //Semnalele 'R' si 'B' sunt setate pe '0', iar 'G' este setat pe valoarea mediei dintre min si max
			
			next_state = gray_increment;
		end
		
		
		gray_increment:begin
			next_state = (row == 63 && col == 63) ? donegr : Read_pixel;
			if(col< 63) begin
							col_index = col +  1;
			end 	else 	begin
							row_index = row + 1;
							col_index = 0;
			end
		end
		
		
		donegr:begin
			out_we = 0;
			gray_done = 1;
			next_state = initial_sharpness;
		end
	
		
		initial_sharpness:begin
			filter_done = 0;
			out_we = 0;
			row_index = 0;
			col_index = 0;
			next_state = read_first_pixel_sharp;
		end
		
		
		read_first_pixel_sharp:begin
			pixel_sharp = out_pix;
			row_index = row - 1;
			col_index = col - 1;
			next_state = read_neighbour1;
		end
			
		
		read_neighbour1:begin
		if(row == 0 && col < 63   || row <63 && col == 0 ) 
						begin
						neighbour1 = 24'b0;
			end else begin
						neighbour1 = out_pix;
			end
			row_index = row - 1; 
			col_index = col;
			next_state = read_neighbour2;
		end
		
		
		read_neighbour2:begin
			if(row == 0 && col < 63)
						begin 
						neighbour2 = 24'b0;
			end else begin
						neighbour2 = out_pix;
			end
			row_index = row - 1 ;
			col_index = col + 1;
			next_state = read_neighbour3;
		end
		
		
		read_neighbour3:begin
			if(row == 0 && col < 63 || row <63 && col == 63 )
						begin 
						neighbour3 = 24'b0;
			end else begin
						neighbour3 = out_pix;
			end
			row_index = row ;
			col_index = col + 1;
			next_state = read_neighbour4;
		end
		
		
		read_neighbour4:begin
			if(col == 63 && row < 63)
						begin 
						neighbour4 = 24'b0;
			end else begin
						neighbour4 = out_pix;
			end
			row_index = row + 1;
			col_index = col + 1;
			next_state = read_neighbour5;
		end
		
		
		read_neighbour5:begin
			if(row == 63 && col < 63 || row < 63 && col == 63)
						begin 
						neighbour5 = 24'b0;
			end else begin
						neighbour5 = out_pix;
			end
			row_index = row + 1;
			col_index = col ;
			next_state = read_neighbour6;
		end
		
		
		read_neighbour6:begin
			if(row == 63 && col < 63 )
						begin 
						neighbour6 = 24'b0;
			end else begin
						neighbour6 = out_pix;
			end
			row_index = row + 1;
			col_index = col - 1;
			next_state = read_neighbour7;
		end
		
		
		read_neighbour7:begin
			if(row < 63 && col == 0 || row == 63 && col < 63 )
						begin 
						neighbour7 = 24'b0;
			end else begin
						neighbour7 = out_pix;
			end
			row_index = row;
			col_index = col - 1;
			next_state = read_neighbour8;
		end
		
		
		read_neighbour8:begin
			if(row < 63 && col == 0)
						begin 
						neighbour8 = 24'b0;
			end else begin
						neighbour8 = out_pix;
			end
			row_index = row;
			col_index = col;
			next_state = output_pixel_calculus;
		end
		
		
		output_pixel_calculus:begin
			out_we = 1;
			out_pix =  9*pixel_sharp - neighbour1 - neighbour2 - neighbour3 - neighbour4 - neighbour5 - neighbour6  - neighbour7  - neighbour8; 
			row_index = row;
			col_index = col;
			next_state = sharpness_increment;
		end
		
		
		sharpness_increment:begin
			next_state = (row == 63 && col == 63) ? sharp_done : read_first_pixel_sharp;
			if(row< 63)
						begin
						row_index = row +  1;
			end else begin
						col_index = col + 1;
						row_index = 0;
			end
		end
		
		//Starea de finalizare a actiunii 'sharpness'
		sharp_done:begin
			filter_done = 1;
			out_we = 0;
		end
		endcase
end

endmodule