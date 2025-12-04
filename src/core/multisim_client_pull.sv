`include "multisim_client_common_header.svh"

module multisim_client_pull #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter int DATA_WIDTH = 64
) (
    input bit clk,
    input string server_name,
    input bit data_rdy,
    output bit data_vld,
    output bit [DATA_WIDTH-1:0] data
);

  localparam PULL_DATA_WIDTH = DATA_WIDTH;
  localparam PUSH_DATA_WIDTH = DATA_WIDTH;
  `include "multisim_client_common.svh"

  initial begin
    data_vld = 0;
    multisim_client_start(SERVER_RUNTIME_DIRECTORY, server_name);
  end

  always @(posedge clk) begin
    bit [DATA_WIDTH-1:0] data_dpi;
    if (!data_vld || data_rdy) begin
      int data_vld_dpi;
      data_vld_dpi = multisim_client_pull_packed(server_name, data_dpi, DATA_WIDTH);
      data_vld <= data_vld_dpi[0];
      data <= data_dpi;
    end
  end

endmodule
