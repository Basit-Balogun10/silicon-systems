module counter #(
    parameter int unsigned WIDTH = 4
) (
    input logic clk,
    input logic reset_n,
    input logic enable,
    output logic [WIDTH-1:0 ] count
);
  localparam bit [WIDTH-1:0] MaxCount = (1 << WIDTH) - 1;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) count <= '0;
    else begin
      if (enable) begin
        if (count == MaxCount) count <= '0;
        else count <= count + 1;
      end else count <= count;
    end
  end

endmodule
