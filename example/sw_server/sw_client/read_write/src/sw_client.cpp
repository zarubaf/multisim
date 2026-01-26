#include "multisim_client.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>

#define BW_ITERATION_NB 100000

void print_bw_value(struct timeval start, struct timeval stop, uint32_t byte_nb) {
  double secs;
  secs = (double)(stop.tv_usec - start.tv_usec) / 1000000 + (double)(stop.tv_sec - start.tv_sec);
  printf("time: %.3f s\n", secs);
  printf("byte_nb: %d\n", byte_nb);
  printf("BW = %0d B/sec\n", (uint32_t)(byte_nb / secs));
}

static inline void write_server(uint64_t address, uint64_t wdata) {
  int r;
  uint64_t cmd[3];
  uint64_t rsp[1];
  cmd[0] = 0; // write
  cmd[1] = address;
  cmd[2] = wdata;
  r = multisim_client_push("rw_cmd", (uint32_t *)cmd, 3 * 64);
  assert(r > 0);
  r = multisim_client_pull("rw_rsp", (uint32_t *)rsp, 64);
  assert(r > 0);
}

static inline uint64_t read_server(uint64_t address) { int r;
  uint64_t cmd[3];
  uint64_t rsp[1];
  cmd[0] = 1; // read
  cmd[1] = address;
  r = multisim_client_push("rw_cmd", (uint32_t *)cmd, 3 * 64);
  assert(r > 0);
  r = multisim_client_pull("rw_rsp", (uint32_t *)rsp, 64);
  assert(r > 0);
  return rsp[0];
}

void exit_server() {
  uint32_t data[1];
  printf("SW Client: Sending exit command\n");
  // Sending whatever to exit socket will quit the server
  (void)multisim_client_push("exit", data, 32);
}

int main() {
  struct timeval stop, start;

  multisim_client_start(".", "exit");
  multisim_client_start(".", "rw_cmd");
  multisim_client_start(".", "rw_rsp");

  //-----------------------------------------------------------
  // write and read
  //-----------------------------------------------------------
  printf("\nFunctional test: write then read\n");
  for (int address = 0; address < 10; address++) {
    uint64_t wdata = 0xbebecacadeadb00b + address;
    uint64_t rdata;
    write_server(address, wdata);
    printf("SW Client: 0x%016lx -> [%d]\n", wdata, address);
    rdata = read_server(address);
    printf("SW Client: 0x%016lx <- [%d]\n", rdata, address);
    assert(rdata == wdata);
  }

  printf("\nFunctional test: all writes then all reads\n");
  for (int address = 0; address < 10; address++) {
    uint64_t wdata = 0xdeadbeefcafedeca + address;
    write_server(address, wdata);
    printf("SW Client: 0x%016lx -> [%d]\n", wdata, address);
  }
  for (int address = 0; address < 10; address++) {
    uint64_t rdata;
    uint64_t expected = 0xdeadbeefcafedeca + address;
    rdata = read_server(address);
    printf("SW Client: 0x%016lx <- [%d]\n", rdata, address);
    assert(rdata == expected);
  }

  //-----------------------------------------------------------
  // bandwidth tests
  //-----------------------------------------------------------
  printf("\nBandwidth test: write\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    write_server(0, 0xdeadbeefcafedeca);
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB * 8);

  printf("\nBandwidth test: read\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    uint64_t rdata = read_server(0);
    (void)rdata;
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB * 8);

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  exit_server();

  printf("SW Client: Test passed!\n");
  return 0;
}
