module multisim_server_apb_pull #(
    parameter type   apb_req_t,
    parameter type   apb_resp_t
) (
    input bit clk,
    input bit rst_n,
    input string server_name,

    // manager APB interface

    output apb_req_t o_apb_m_req,
    input apb_resp_t i_apb_m_resp,
    output bit o_apb_m_psel,
    output bit o_apb_m_penable,
    input bit i_apb_m_pready
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
    apb_s_pready_d1 <= i_apb_m_pready;
  end

  always_comb begin : next_state_logic
    case (state)
      IDLE: next_state = request_vld ? SETUP : IDLE;
      SETUP: next_state = ACCESS;
      ACCESS: next_state = apb_s_pready_d1 ? (request_vld ? SETUP : IDLE) : ACCESS;
      default: next_state = IDLE;
    endcase
  end

  bit request_rdy;
  wire request_vld;
  apb_req_t request_data;
  wire response_rdy;
  wire response_vld = i_apb_m_pready && (next_state == ACCESS);

  always_comb begin
    case (next_state)
      IDLE: request_rdy = 1'b1;
      SETUP: begin
        request_rdy = 1'b1;
        o_apb_m_req = request_data;
      end
      ACCESS: request_rdy = 1'b0;
      default: request_rdy = 1'b0;
    endcase
  end

  always_ff @(posedge clk_gated) begin
    state <= next_state;
  end

  assign o_apb_m_psel = next_state != IDLE;
  assign o_apb_m_penable = next_state == ACCESS;

  // request
  multisim_server_pull #(
      .DATA_WIDTH($bits(apb_req_t))
  ) i_multisim_server_pull_apb_req (
      .clk        (clk_gated),
      .server_name(server_name_apb_req),
      .data_rdy   (request_rdy),
      .data_vld   (request_vld),
      .data       (request_data)
  );

  // response
  multisim_server_push #(
      .DATA_WIDTH($bits(apb_resp_t))
  ) i_multisim_server_push_apb_resp (
      .clk        (clk_gated),
      .server_name(server_name_apb_resp),
      .data_rdy   (response_rdy),
      .data_vld   (response_vld),
      .data       (i_apb_m_resp)
  );

endmodule
