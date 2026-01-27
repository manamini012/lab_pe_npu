module Top (
    input clk,
    input rst,
  
    input [16*49-1:0] A_inputs, 
    input [16*49-1:0] B_inputs,
    
    // Output cuối cùng của cả hệ thống
    output [15:0] Final_Result
);

    // 1. Dây nối từ MAC sang Adder Tree
    wire [15:0] mac_results [0:48];      
    wire [16*49-1:0] tree_input_flat;    

    // 2. Tạo 49 bộ MAC
    genvar i;
    generate
        for (i = 0; i < 49; i = i + 1) begin : GEN_MACS
            MAC_FP_16 u_mac (
                .clk(clk),
                .rst(rst),
                // Tách dây input phẳng thành từng cụm 16-bit
                .A(A_inputs[(i*16)+15 : (i*16)]), 
                .B(B_inputs[(i*16)+15 : (i*16)]),
                .Acc_Out(mac_results[i]) // Đầu ra của từng MAC [cite: 1, 9]
            );
            
            // Gom dây lại để đưa vào cây cộng
            assign tree_input_flat[(i*16)+15 : (i*16)] = mac_results[i];
        end
    endgenerate

    // 3. Nối vào Cây Cộng Pipelined
    Adder_Tree_49_Pipelined u_adder_tree (
        .clk(clk),
        .rst(rst),
        .in_flat_data(tree_input_flat),
        .final_sum(Final_Result)
    );

endmodule