#include "socket_server/server.h"

#include <cassert>
#include <map>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <svdpi.h>
#include <unistd.h>

using namespace std;

extern "C" int multisim_server_start(char const *server_name);
extern "C" int multisim_server_get_data(char const *server_name,
                                        svOpenArrayHandle data_handle,
                                        int data_width);
extern "C" int multisim_server_send_data(char const *server_name,
                                         const svOpenArrayHandle data_handle,
                                         int data_width);

#define MULTISIM_SERVER_MAX 1024
Server *server[MULTISIM_SERVER_MAX];
int new_socket[MULTISIM_SERVER_MAX];
int server_idx = 0;
map<string, int> server_name_to_idx;

int multisim_server_start(char const *server_name) {
  char *str = new char[80];
  assert(server_idx < MULTISIM_SERVER_MAX);
  strcpy(str, server_name);
  server[server_idx] = new Server(str);
  server[server_idx]->start();
  new_socket[server_idx] = -1;
  server_name_to_idx[server_name] = server_idx;
  server_idx++;
  return 0;
}

int multisim_server_get_data(char const *server_name,
                             svOpenArrayHandle data_handle, int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);

  if (new_socket[idx] < 0) {
    new_socket[idx] = server[idx]->acceptNewSocket();
    if (new_socket[idx] < 0) {
      return 0;
    }
  }

  r = read(new_socket[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    // -1: nothing to send
    // 0: client disconnected
    if (r == 0) {
      new_socket[idx] = -1;
    }
    return 0;
  }

  for (int i = 0; i < buf_32b_size; i++) {
    data[i] = read_buf[i];
  }
  return 1;
}

// #define SIMULATE_SEND_FAIL_SERVER
int multisim_server_send_data(char const *server_name,
                              const svOpenArrayHandle data_handle,
                              int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);

  if (new_socket[idx] < 0) {
    new_socket[idx] = server[idx]->acceptNewSocket();
    if (new_socket[idx] < 0) {
      return 0;
    }
  }

  for (int i = 0; i < buf_32b_size; i++) {
    send_buf[i] = data[i];
  }

#ifdef SIMULATE_SEND_FAIL_SERVER
  static int cnt = 0;
  cnt++;
  if (cnt % 1000 == 0) {
    printf("multisim_server_send_data: simulate send fail\n");
    return 0;
  }
#endif

  r = send(new_socket[idx], send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return 0;
  }
  return 1;
}
