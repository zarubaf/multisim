module multisim_client_push #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter int DATA_WIDTH = 64,
    // do not touch
    parameter type multisim_data_t = `ifdef MULTISIM_SIMULATION_4_STATE logic `else bit `endif
) (
    input bit clk,
    input string server_name,
    output bit data_rdy,
    input bit data_vld,
    input multisim_data_t [DATA_WIDTH-1:0] data
);

  localparam PULL_DATA_WIDTH = DATA_WIDTH;
  localparam PUSH_DATA_WIDTH = DATA_WIDTH;
  `include "multisim_client_common.svh"

  initial begin
    data_rdy = 0;
`ifndef MULTISIM_EMULATION
    /* verilator lint_off WAITCONST */
    wait (server_name != "");
`endif
    multisim_client_start(SERVER_RUNTIME_DIRECTORY, server_name);
    data_rdy = 1;
  end

  multisim_data_t [DATA_WIDTH-1:0] data_q;

  always @(posedge clk) begin
    if (data_vld && data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_push_packed(server_name, data, DATA_WIDTH);
      data_rdy <= data_rdy_dpi[0];
      data_q   <= data;
    end
    if (!data_rdy) begin
      int data_rdy_dpi;
      data_rdy_dpi = multisim_client_push_packed(server_name, data_q, DATA_WIDTH);
      data_rdy <= data_rdy_dpi[0];
    end
  end

endmodule
