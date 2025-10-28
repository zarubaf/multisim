module multisim_server_quasi_static_pull #(
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    output bit [DATA_WIDTH-1:0] data
);

  bit data_rdy;
  bit data_vld;
  bit [DATA_WIDTH-1:0] data_pull;

  assign data_rdy = 1'b1;

  always @(posedge clk) begin
    if (data_vld && data_rdy) begin
      data <= data_pull;
    end
  end

  multisim_server_pull #(
      .DATA_WIDTH(DATA_WIDTH)
  ) i_multisim_server_pull (
      .clk        (clk),
      .server_name(server_name),
      .data_rdy   (data_rdy),
      .data_vld   (data_vld),
      .data       (data_pull)
  );

endmodule
