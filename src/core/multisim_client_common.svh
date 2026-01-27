//-----------------------------------------------------------
// DPIs
//-----------------------------------------------------------
localparam int PullData32bWidth = (PULL_DATA_WIDTH + 31) / 32;
localparam int PushData32bWidth = (PUSH_DATA_WIDTH + 31) / 32;

import "DPI-C" function void multisim_client_start(
  input string server_runtime_directory,
  input string server_name
);

import "DPI-C" function int multisim_client_pull(
  string server_name,
`ifdef MULTISIM_EMULATION
  output bit [31:0] data[PullData32bWidth],
`else
  output multisim_data_t [31:0] data[],
`endif
  input int data_width
);

import "DPI-C" function int multisim_client_push(
  string server_name,
`ifdef MULTISIM_EMULATION
  input bit [31:0] data[PushData32bWidth],
`else
  input multisim_data_t [31:0] data[],
`endif
  input int data_width
);

function automatic int multisim_client_pull_packed(
    string server_name, output multisim_data_t [PULL_DATA_WIDTH-1:0] data, input int data_width);
  multisim_data_t [31:0] data_unpacked[PullData32bWidth];
  multisim_data_t [PullData32bWidth*32-1:0] data_tmp;
  int ret;
  ret = multisim_client_pull(server_name, data_unpacked, data_width);
  for (int i = 0; i < PullData32bWidth; i++) begin
    data_tmp[i*32+:32] = data_unpacked[i];
  end
  data = data_tmp[PULL_DATA_WIDTH-1:0];
  return ret;
endfunction

function automatic int multisim_client_push_packed(
    string server_name, input multisim_data_t [PUSH_DATA_WIDTH-1:0] data, input int data_width);
  multisim_data_t [31:0] data_unpacked[PushData32bWidth];
  multisim_data_t [PushData32bWidth*32-1:0] data_tmp;
  int ret;
  data_tmp[PUSH_DATA_WIDTH-1:0] = data;
  for (int i = 0; i < PushData32bWidth; i++) begin
    data_unpacked[i] = data_tmp[i*32+:32];
  end
  ret = multisim_client_push(server_name, data_unpacked, data_width);
  return ret;
endfunction
