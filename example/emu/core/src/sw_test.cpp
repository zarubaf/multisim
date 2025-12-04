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
  printf("BW = %0d B/sec\n", (uint32_t)(byte_nb/secs));
}

int main() {
  int r;
  uint32_t write_buf[2];
  uint32_t read_buf[2];
  struct timeval stop, start;

  multisim_client_start(".", "exit");
  multisim_client_start(".", "rx64");
  multisim_client_start(".", "tx64");

  write_buf[0] = 0xcafedeca;
  write_buf[1] = 0xdeadbeef;

  //-----------------------------------------------------------
  // rx64->tx64
  //-----------------------------------------------------------
  printf("\nloopback test\n");
  printf("rx64: 0xcafedeca 0xdeadbeef\n");
  r = multisim_client_send_data("rx64", write_buf, 64);
  assert(r > 0);

  r = multisim_client_get_data("tx64", read_buf, 64);
  printf("tx64: 0x%08x 0x%08x\n", read_buf[0], read_buf[1]);
  assert(r > 0);

  //-----------------------------------------------------------
  // bandwidth tests
  //-----------------------------------------------------------
  printf("\nbandwidth test: push only\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    r = multisim_client_send_data("rx64", write_buf, 64);
    assert(r > 0);
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB*8);

  printf("\nbandwidth test: pull only\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    r = multisim_client_get_data("tx64", read_buf, 64);
    assert(r > 0);
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB*8);

  printf("\nbandwidth test: push/pull\n");
  gettimeofday(&start, NULL);
  for (int i = 0; i < BW_ITERATION_NB; i++) {
    r = multisim_client_send_data("rx64", write_buf, 64);
    assert(r > 0);
    r = multisim_client_get_data("tx64", read_buf, 64);
    assert(r > 0);
  }
  gettimeofday(&stop, NULL);
  print_bw_value(start, stop, BW_ITERATION_NB*8);

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  printf("exit\n");
  // sending whatever to exit socket will quit the Veloce
  r = multisim_client_send_data("exit", write_buf, 32);
  assert(r > 0);

  return 0;
}
