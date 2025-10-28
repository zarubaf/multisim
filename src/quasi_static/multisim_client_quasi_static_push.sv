module multisim_client_quasi_static_push #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    input bit [DATA_WIDTH-1:0] data
);

  bit data_rdy;
  bit data_vld;
  bit [DATA_WIDTH-1:0] data_push;

  bit [DATA_WIDTH-1:0] data_prev;
  bit [DATA_WIDTH-1:0] data_queue[$];

  assign data_push = data_queue.size() > 0 ? data_queue[0] : '0;
  assign data_vld  = data_queue.size() > 0 ? 1'b1 : 1'b0;

  initial begin
    data_queue.push_back(data);
    data_prev = data;
  end

  always @(posedge clk) begin
    if (data !== data_prev) begin
      data_queue.push_back(data);
      data_prev = data;
    end
    if (data_vld && data_rdy) begin
      data_queue.pop_front();
    end
  end

  multisim_client_push #(
      .SERVER_RUNTIME_DIRECTORY(SERVER_RUNTIME_DIRECTORY),
      .DATA_WIDTH(DATA_WIDTH)
  ) i_multisim_client_push_data (
      .clk        (clk),
      .server_name(server_name),
      .data_rdy   (data_rdy),
      .data_vld   (data_vld),
      .data       (data_push)
  );

endmodule
