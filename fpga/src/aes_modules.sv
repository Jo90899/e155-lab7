
module controller( input logic clk, load, 
                   input logic[127:0] key,
                   output logic start, subReady, shiftReady, mixReady, countDone,
                   output logic[127:0] round_key,
				   output logic done);

    logic [127:0] old_key;
    logic [3:0] round; 
	logic [2:0] counter;

    keyExpansion keyController(.clk(clk), .round(round), .old_key(old_key), .round_key(round_key));

    typedef enum {IDLE, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, DONE} statetype;
    statetype state, next_state;

    // State Register
    always_ff @(posedge clk) begin
        if (load) begin 
            counter <= 0;
            old_key <= key;
            state <= IDLE;
            round <= -1;
        end
        else begin
            state <= next_state;                           
            if (state != next_state) begin 
                counter <= 0;
                round <= round + 1;
                old_key <= round_key;
            end
			else if (state == DONE) round = -1;
            else counter <= counter + 1;
            
        end

    end

    // Next State Logic
    always_comb begin
		case (state)
			IDLE: if (!load) next_state = R1; else next_state = state;
			R1: if (counter == 5) next_state = R2; else next_state = state;
			R2: if (counter == 5) next_state = R3; else next_state = state;
			R3: if (counter == 5) next_state = R4; else next_state = state;
			R4: if (counter == 5) next_state = R5; else next_state = state;
			R5: if (counter == 5) next_state = R6; else next_state = state;
			R6: if (counter == 5) next_state = R7; else next_state = state;
			R7: if (counter == 5) next_state = R8; else next_state = state;
			R8: if (counter == 5) next_state = R9; else next_state = state;
			R9: if (counter == 5) next_state = R10; else next_state = state;
			R10: if (counter == 5) next_state = R11; else next_state = state;
			R11: if (counter == 5) next_state = DONE; else next_state = state;
			DONE:  next_state = state;
			default: next_state = IDLE;
		endcase
    end

	// Output Logic
    assign start = ((round > 0) && (round <= 11));
    assign subReady = ((round > 0) && (round <= 10));
    assign shiftReady = ((round > 0) && (round <= 10));
    assign mixReady = ((round > 0) && (round < 10));
    assign countDone = (counter == 5);
    assign done = (state == DONE);

    

endmodule

module keyExpansion(	input logic clk,
						input logic [3:0] round,
						input logic [127:0] old_key,
						output logic [127:0] round_key
);

	logic[31:0] w0, w1, w2, w3, w4, w5, w6, w7, Rcon, rotWord, subWord;

    assign {w0,w1,w2,w3} = old_key;
	assign rotWord = {w3[23:16], w3[15:8], w3[7:0], w3[31:24]};

	sbox_sync sbox0(rotWord[7:0],      clk, subWord[7:0]);
	sbox_sync sbox1(rotWord[15:8],     clk, subWord[15:8]);
	sbox_sync sbox2(rotWord[23:16],    clk, subWord[23:16]);
	sbox_sync sbox3(rotWord[31:24],    clk, subWord[31:24]);        

	always_comb begin
		if ((round == 4'b1111) | (round == 4'b0000)) round_key = old_key;
		else begin
			if (round <= 8) Rcon = {16'b1 << (round-1), 24'h000000};
			else if (round == 9) Rcon = 32'h1b000000;
			else if (round == 10) Rcon = 32'h36000000;
			else Rcon = 32'h0;
			
			w4 = w0 ^ subWord ^ Rcon;
			w5 = w1 ^ w4;
			w6 = w2 ^ w5;
			w7 = w3 ^ w6;
			round_key = {w4, w5, w6, w7};
		end
	end

endmodule

module preEncode(	input  logic start,
					input  logic [127:0] plaintext, ciphertext,
					output logic [127:0] current_input
);	
	
    always_comb begin
        if (start)
			current_input = ciphertext;
		else
			current_input = plaintext;
	end
			
endmodule

module encode(
				input  logic [127:0] current_input, round_key,
				output logic [127:0] enc_out
);
	always_comb
		enc_out = current_input ^ round_key; 
	//always_comb begin
		//if (round == 0) enc_out = current_input;
		//else enc_out = current_input ^ round_key; 
	//end
    
endmodule

module subBytes(	input  logic clk, subReady,
					input  logic [127:0] sub_in,
					output logic [127:0] new_out
);
	
	logic [127:0] sub_out;
	
	sbox_sync sbox0(sub_in[7:0],      clk, sub_out[7:0]);
	sbox_sync sbox1(sub_in[15:8],     clk, sub_out[15:8]);
	sbox_sync sbox2(sub_in[23:16],    clk, sub_out[23:16]);
	sbox_sync sbox3(sub_in[31:24],    clk, sub_out[31:24]);
	sbox_sync sbox4(sub_in[39:32],    clk, sub_out[39:32]);
	sbox_sync sbox5(sub_in[47:40],    clk, sub_out[47:40]);
	sbox_sync sbox6(sub_in[55:48],    clk, sub_out[55:48]);
	sbox_sync sbox7(sub_in[63:56],    clk, sub_out[63:56]);
	sbox_sync sbox8(sub_in[71:64],    clk, sub_out[71:64]);
	sbox_sync sbox9(sub_in[79:72],    clk, sub_out[79:72]);
	sbox_sync sbox10(sub_in[87:80],   clk, sub_out[87:80]);
	sbox_sync sbox11(sub_in[95:88],   clk, sub_out[95:88]);
	sbox_sync sbox12(sub_in[103:96],  clk, sub_out[103:96]);
	sbox_sync sbox13(sub_in[111:104], clk, sub_out[111:104]);
	sbox_sync sbox14(sub_in[119:112], clk, sub_out[119:112]);
	sbox_sync sbox15(sub_in[127:120], clk, sub_out[127:120]);

    always_ff @(posedge clk) begin
        if (subReady) 
			new_out <= sub_out;
        else 
			new_out <= sub_in;
	end
endmodule

module shiftRows(	input  logic shiftReady,
					input  logic [127:0] shift_in,
					output logic [127:0] shift_out
);
    
    always_comb begin
        if (shiftReady) begin
            shift_out[127:96] = {shift_in[127:120], shift_in[87:80], shift_in[47:40], shift_in[7:0]};
            shift_out[95:64] = {shift_in[95:88], shift_in[55:48], shift_in[15:8], shift_in[103:96]};
            shift_out[63:32] = {shift_in[63:56], shift_in[23:16], shift_in[111:104], shift_in[71:64]};
            shift_out[31:0] = {shift_in[31:24], shift_in[119:112], shift_in[79:72], shift_in[39:32]};
        end
        else 
			shift_out = shift_in;
    end
endmodule

module mixColumns(	input  logic mixReady,
					input  logic [127:0] mix_in,	
					output logic [127:0] mix_out
);

	logic [127:0] current_out;

	mixcolumn mc0(mix_in[127:96], current_out[127:96]);
	mixcolumn mc1(mix_in[95:64], current_out[95:64]);
	mixcolumn mc2(mix_in[63:32], current_out[63:32]);
	mixcolumn mc3(mix_in[31:0], current_out[31:0]);

	always_comb begin
		if (mixReady)
			mix_out = current_out;
		else 		
			mix_out = mix_in;
	end
endmodule

