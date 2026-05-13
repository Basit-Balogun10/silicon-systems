module counter #(
    parameter int unsigned WIDTH = 4
) (
    input logic clk,
    input logic reset_n,
    input logic enable,
    input logic up_down,
    output logic [WIDTH-1:0] count
);
  localparam bit [WIDTH-1:0] MaxCount = '1;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      if (up_down) count <= '0;
      else count <= MaxCount;
    end else begin
      if (enable) begin
        if (up_down === '1) begin
          if (count == MaxCount) count <= '0;
          else count <= count + 1;
        end else begin
          if (count == '0) count <= MaxCount;
          else count <= count - 1;
        end
      end else count <= count;
    end
  end

endmodule
