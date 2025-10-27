module multisim_client_apb_push #(
    parameter string SERVER_RUNTIME_DIRECTORY = "../output_top",
    parameter type   apb_req_t,
    parameter type   apb_resp_t
) (
    input bit clk,
    input bit rst_n,
    input string server_name,

    // subordinate APB interface

    input apb_req_t i_apb_s_req,
    output apb_resp_t o_apb_s_resp,
    input bit i_apb_s_psel,
    input bit i_apb_s_penable,
    output bit o_apb_s_pready
);


  string server_name_apb_req;
  string server_name_apb_resp;
  initial begin
    $sformat(server_name_apb_req, "%0s_apb_req", server_name);
    $sformat(server_name_apb_resp, "%0s_apb_resp", server_name);
  end

  wire clk_gated;
  assign clk_gated = clk & rst_n;

  // APB state machine:
  typedef enum logic [3:0] {
    IDLE   = 4'b0001,
    SETUP  = 4'b0010,
    ACCESS = 4'b0100
  } apb_state_t;

  apb_state_t state, next_state;

  bit apb_s_pready_d1;
  always_ff @(posedge clk_gated) begin
    apb_s_pready_d1 <= o_apb_s_pready;
  end

  always_comb begin : next_state_logic
    case (state)
      IDLE: next_state = i_apb_s_psel ? SETUP : IDLE;
      SETUP: next_state = ACCESS;
      ACCESS: next_state = apb_s_pready_d1 ? (i_apb_s_psel ? SETUP : IDLE) : ACCESS;
      default: next_state = IDLE;
    endcase
  end

  wire request_rdy;
  bit request_vld;
  wire response_rdy = 1;
  wire response_vld;
  assign o_apb_s_pready = response_vld;

  always_comb begin
    case (next_state)
      IDLE: request_vld = 1'b0;
      SETUP: request_vld = 1'b1;
      ACCESS: begin
        if (request_rdy) request_vld = 1'b0;
      end
      default: request_vld = 1'b0;
    endcase
  end

  always_ff @(posedge clk_gated) begin
    state <= next_state;
  end

  // request
  multisim_client_push #(
      .SERVER_RUNTIME_DIRECTORY(SERVER_RUNTIME_DIRECTORY),
      .DATA_WIDTH($bits(apb_req_t))
  ) i_multisim_client_push_apb_req (
      .clk        (clk_gated),
      .server_name(server_name_apb_req),
      .data_rdy   (request_rdy),
      .data_vld   (request_vld),
      .data       (i_apb_s_req)
  );

  // response
  multisim_client_pull #(
      .SERVER_RUNTIME_DIRECTORY(SERVER_RUNTIME_DIRECTORY),
      .DATA_WIDTH($bits(apb_resp_t))
  ) i_multisim_client_pull_apb_resp (
      .clk        (clk_gated),
      .server_name(server_name_apb_resp),
      .data_rdy   (response_rdy),
      .data_vld   (response_vld),
      .data       (o_apb_s_resp)
  );

endmodule
