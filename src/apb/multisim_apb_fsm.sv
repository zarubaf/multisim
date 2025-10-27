typedef enum logic [3:0] {
  IDLE   = 4'b0001,
  SETUP  = 4'b0010,
  ACCESS = 4'b0100
  } multisim_apb_state_t;

module multisim_apb_fsm(
    input bit clk,
    input bit rst_n,
    input bit i_apb_pready,
    input bit i_apb_psel,
    output multisim_apb_state_t state
);

  wire clk_gated;
  assign clk_gated = clk & rst_n;

  multisim_apb_state_t prev_state;

  bit apb_pready_d1;
  always_ff @(posedge clk_gated) begin
    apb_pready_d1 <= i_apb_pready;
  end

  always_comb begin : next_state_logic
    case (prev_state)
      IDLE: state = i_apb_psel ? SETUP : IDLE;
      SETUP: state = ACCESS;
      ACCESS: state = apb_pready_d1 ? (i_apb_psel ? SETUP : IDLE) : ACCESS;
      default: state = IDLE;
    endcase
  end

  always_ff @(posedge clk_gated) begin
    prev_state <= state;
  end

endmodule
