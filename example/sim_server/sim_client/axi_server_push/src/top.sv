`include "axi_pkg.sv"

module top ();
  import axi_pkg::*;

  bit clk = 0;
  always #1ns clk <= ~clk;

  axi_aw_t axi_aw     [1];
  bit      axi_awready[1];
  bit      axi_awvalid[1];
  axi_w_t  axi_w      [1];
  bit      axi_wready [1];
  bit      axi_wvalid [1];
  axi_b_t  axi_b      [1];
  bit      axi_bready [1];
  bit      axi_bvalid [1];
  axi_ar_t axi_ar     [1];
  bit      axi_arready[1];
  bit      axi_arvalid[1];
  axi_r_t  axi_r      [1];
  bit      axi_rready [1];
  bit      axi_rvalid [1];

  memory #(
      .CPU_NB(1)
  ) i_memory (
      .clk            (clk),
      .i_axi_s_aw     (axi_aw),
      .o_axi_s_awready(axi_awready),
      .i_axi_s_awvalid(axi_awvalid),

      .i_axi_s_w     (axi_w),
      .o_axi_s_wready(axi_wready),
      .i_axi_s_wvalid(axi_wvalid),

      .o_axi_s_b     (axi_b),
      .i_axi_s_bready(axi_bready),
      .o_axi_s_bvalid(axi_bvalid),

      .i_axi_s_ar     (axi_ar),
      .o_axi_s_arready(axi_arready),
      .i_axi_s_arvalid(axi_arvalid),

      .o_axi_s_r     (axi_r),
      .i_axi_s_rready(axi_rready),
      .o_axi_s_rvalid(axi_rvalid)
  );

  cpu_multisim_client i_cpu_multisim_client (
      .clk      (clk),
      .cpu_index(0),

      // manager AXI interface

      .o_axi_m_aw     (axi_aw[0]),
      .i_axi_m_awready(axi_awready[0]),
      .o_axi_m_awvalid(axi_awvalid[0]),

      .o_axi_m_w     (axi_w[0]),
      .i_axi_m_wready(axi_wready[0]),
      .o_axi_m_wvalid(axi_wvalid[0]),

      .i_axi_m_b     (axi_b[0]),
      .o_axi_m_bready(axi_bready[0]),
      .i_axi_m_bvalid(axi_bvalid[0]),

      .o_axi_m_ar     (axi_ar[0]),
      .i_axi_m_arready(axi_arready[0]),
      .o_axi_m_arvalid(axi_arvalid[0]),

      .i_axi_m_r     (axi_r[0]),
      .o_axi_m_rready(axi_rready[0]),
      .i_axi_m_rvalid(axi_rvalid[0])
  );

endmodule
