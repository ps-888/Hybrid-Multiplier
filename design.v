module hybrid_mult (
input [7:0] a,
input [7:0] b,
output [15:0] product
);
//LSB approx
wire [2:0] lsb_approx;
assign lsb_approx = a[2:0] | b[2:0];
//Cross products
wire [10:0] cp1;
wire [10:0] cp2;
assign cp1 = (a[7:3] * b[2:0]) << 3;
assign cp2 = (a[2:0] * b[7:3]) << 3;
//MSB exact
wire [15:0] msb_prod;
assign msb_prod = (a[7:3] * b[7:3]) << 6;
// Error compensation
wire c0, c1, c2;
assign c0 = a[0] & b[0];
assign c1 = (a[1] & b[1]) | (a[1] & c0) | (b[1] & c0);
assign c2 = (a[2] & b[2]) | (a[2] & c1) | (b[2] & c1);
wire [3:0] comp = {3'b000, c2}; 
//Final accumulation 
assign product =
msb_prod
+ {5'b0, cp1} 
+ {5'b0, cp2}
+ {13'b0, lsb_approx}
+ {12'b0, comp};
endmodule

    
