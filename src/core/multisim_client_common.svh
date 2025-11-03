//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
localparam int Data32bWidth = (DATA_WIDTH + 31) / 32;

import "DPI-C" function void multisim_client_start(
  input string server_runtime_directory,
  input string server_name
);
import "DPI-C" function int multisim_client_get_data(
  string server_name,
  output bit [31:0] data[],
  input int data_width
);
import "DPI-C" function int multisim_client_send_data(
  string server_name,
  input bit [31:0] data[],
  input int data_width
);

function automatic int multisim_client_get_data_packed(
    string server_name, output bit [DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[Data32bWidth];
  bit [Data32bWidth*32-1:0] data_tmp;
  int ret;
  ret = multisim_client_get_data(server_name, data_unpacked, data_width);
  for (int i = 0; i < Data32bWidth; i++) begin
    data_tmp[i*32+:32] = data_unpacked[i];
  end
  data = data_tmp[DATA_WIDTH-1:0];
  return ret;
endfunction

function automatic int multisim_client_send_data_packed(
    string server_name, input bit [DATA_WIDTH-1:0] data, input int data_width);
  bit [31:0] data_unpacked[Data32bWidth];
  bit [Data32bWidth*32-1:0] data_tmp;
  int ret;
  data_tmp[DATA_WIDTH-1:0] = data;
  for (int i = 0; i < Data32bWidth; i++) begin
    data_unpacked[i] = data_tmp[i*32+:32];
  end
  ret = multisim_client_send_data(server_name, data_unpacked, data_width);
  return ret;
endfunction

//-----------------------------------------------------------
// functions/tasks
//-----------------------------------------------------------
function automatic int multisim_fopen(input string filename, input bit [4*8-1:0] mode);
  return $fopen({SERVER_RUNTIME_DIRECTORY, "/multisim/", filename}, mode);
endfunction

//-----------------------------------------------------------
// end of simulation
//-----------------------------------------------------------
initial begin
  multisim_client_end_of_simulation eos;
  eos = new();

  // make sure only 1 process handles eos to improve performance
  @(posedge clk);
  if (eos.handles_end_of_simulation()) begin
    int check_every_n_cycles;
    if (!$value$plusargs("MULTISIM_EOS_CHECK_EVERY_N_CYCLES=%d", check_every_n_cycles)) begin
      check_every_n_cycles = 1000;
    end

    forever begin
      int fp;
      repeat (check_every_n_cycles) begin
        @(posedge clk);
      end
      fp = multisim_fopen("server_exit", "r");  // can be checked ~2M times/sec on Verilator
      if (fp != 0) begin
        $fclose(fp);
        $display("multisim_client: end of simulation");
        $finish;
      end
    end
  end
end
