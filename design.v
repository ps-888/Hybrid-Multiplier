`timescale 1ns / 1ps

module hybrid_mult_optimized (
    input  [7:0] a,
    input  [7:0] b,
    output [15:0] product
);

    localparam integer K = 3;

    wire [15:0] lsb_approx_sum;
    wire [15:0] cross_product_1;
    wire [15:0] cross_product_2;
    wire [15:0] msb_exact_mult;
    wire [15:0] compensation_term;

    lsb_approx_adder #(
        .K(K)
    ) lsb_unit (
        .a_in(a[K-1:0]),
        .b_in(b[K-1:0]),
        .sum_out(lsb_approx_sum)
    );

    cross_product_mult #(
        .K(K)
    ) cross_unit (
        .a_in(a),
        .b_in(b),
        .cp1(cross_product_1),
        .cp2(cross_product_2)
    );

    msb_exact_mult #(
        .K(K)
    ) msb_unit (
        .a_in(a[7:K]),
        .b_in(b[7:K]),
        .mult_out(msb_exact_mult)
    );

    error_compensation #(
        .K(K)
    ) compensation_unit (
        .a_in(a),
        .b_in(b),
        .comp_out(compensation_term)
    );

    assign product = lsb_approx_sum + cross_product_1 + cross_product_2 + msb_exact_mult + compensation_term;
endmodule

module lsb_approx_adder #(
    parameter integer K = 3
) (
    input  [K-1:0] a_in,
    input  [K-1:0] b_in,
    output [15:0] sum_out
);
    wire [K-1:0] sum_bits;
    assign sum_bits = a_in | b_in;
    assign sum_out = { {16-K{1'b0}}, sum_bits };
endmodule

module cross_product_mult #(
    parameter integer K = 3
) (
    input  [7:0] a_in,
    input  [7:0] b_in,
    output [15:0] cp1,
    output [15:0] cp2
);
    wire [7-K:0] a_msb = a_in[7:K];
    wire [K-1:0] a_lsb = a_in[K-1:0];
    wire [7-K:0] b_msb = b_in[7:K];
    wire [K-1:0] b_lsb = b_in[K-1:0];

    wire [15:0] mult1_raw;
    wire [15:0] mult2_raw;
    
    assign mult1_raw = a_msb * b_lsb;
    assign mult2_raw = a_lsb * b_msb;

    assign cp1 = mult1_raw << K;
    assign cp2 = mult2_raw << K;

endmodule

module msb_exact_mult #(
    parameter integer K = 3
) (
    input  [7-K:0] a_in,
    input  [7-K:0] b_in,
    output [15:0] mult_out
);
    wire [15:0] raw_product;
    assign raw_product = a_in * b_in;
    assign mult_out = raw_product << (2 * K);
endmodule

module error_compensation #(
    parameter integer K = 3
) (
    input [7:0] a_in,
    input [7:0] b_in,
    output [15:0] comp_out
);
    wire [K:0] lsb_carries;
    wire lsb_carry_out_exact;
    
    assign lsb_carries[0] = a_in[0] & b_in[0];
    
    genvar i;
    generate
        for (i = 1; i < K; i = i + 1) begin : carry_chain
            assign lsb_carries[i] = (a_in[i] & b_in[i]) | (a_in[i] & lsb_carries[i-1]) | (b_in[i] & lsb_carries[i-1]);
        end
    endgenerate
    
    assign lsb_carry_out_exact = lsb_carries[K-1];
    assign comp_out = lsb_carry_out_exact << K;
endmodule
