#include "multisim_server.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main() {
  int r;
  uint64_t mem[1 << 8];
  memset(mem, 0, sizeof(mem));

  // start multisim server channels
  multisim_server_start("exit");
  multisim_server_start("rw_cmd");
  multisim_server_start("rw_rsp");

  printf("SW Server: Started and waiting for connections...\n");

  while (true) {
    // check for exit command
    uint32_t exit_data[1];
    r = multisim_server_pull("exit", exit_data, 1);
    if (r > 0) {
      printf("SW Server: Exit command received\n");
      break;
    }

    // check for read/write command
    uint64_t rw_cmd[3];
    r = multisim_server_pull("rw_cmd", (uint32_t *)rw_cmd, 3 * 64);
    if (r > 0) {
      // Parse command
      uint64_t rwb = rw_cmd[0];
      uint64_t address = rw_cmd[1];
      uint64_t wdata = rw_cmd[2];

      // process command
      uint64_t rsp = 0;
      if (rwb) {
        // read
        rsp = mem[address & 0xFF];
      } else {
        // write
        mem[address & 0xFF] = wdata;
      }

      // send response
      r = multisim_server_push("rw_rsp", (uint32_t *)(&rsp), 64);
      assert(r > 0);
    }
  }

  printf("SW Server: Exiting\n");
  return 0;
}
