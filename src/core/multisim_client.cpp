#include "socket_server/client.h"

#include "stdlib.h"
#include "svdpi.h"
#include <cassert>
#include <map>
#include <stdio.h>
#include <string>
#include <unistd.h>

using namespace std;

extern "C" void multisim_client_start(char const *server_runtime_directory,
                                      char const *server_name);
extern "C" int multisim_client_send_data(char const *server_name,
                                         const svOpenArrayHandle data_handle, int data_width);
extern "C" int multisim_client_get_data(char const *server_name, svOpenArrayHandle data_handle,
                                        int data_width);

#define MULTISIM_SERVER_MAX 256
int sockets[MULTISIM_SERVER_MAX];
int server_idx = 0;
map<string, int> server_name_to_idx;

int get_server_address_and_port(char const *server_runtime_directory, char const *server_name,
                                string &server_address, int &server_port) {
  string garbage;
  string server_file;
  server_file =
      string(server_runtime_directory) + "/multisim/server_" + string(server_name) + ".txt";
  FILE *fp = fopen(server_file.c_str(), "r");
  if (fp == NULL) {
    return 0;
  }
  char ip_str[64];
  fscanf(fp, "%s %s", &garbage[0], &ip_str[0]); // read "ip: xxx.xxx.xxx.xxx"
  server_address = string(ip_str);
  fscanf(fp, "%s %d", &garbage[0], &server_port); // read "port: xxxxx"
  fclose(fp);
  return 1;
}

int client_start(string server_runtime_directory, char const *server_name,
                 char const *server_address, int server_port) {
  Client *client = new Client(server_name);
  assert(server_idx < MULTISIM_SERVER_MAX);

  if (!client->start(server_address, server_port)) {
    return 0;
  }

  sockets[server_idx] = client->getSocket();
  server_name_to_idx[server_name] = server_idx;

  // dump info
  string first_server_name = server_name_to_idx.begin()->first;
  string client_info_file =
      string(server_runtime_directory) + "/multisim/client_" + first_server_name + ".txt";
  FILE *fp;
  if (server_idx == 0) {
    fp = fopen(client_info_file.c_str(), "w");
    fprintf(fp, "ip: %s\n", client->getIp());
    fprintf(fp, "pid: %0d\n", getpid());
  } else {
    fp = fopen(client_info_file.c_str(), "a");
  }
  fprintf(fp, "server_%0d: %s %s %0d\n", server_idx, server_name, server_address, server_port);
  fflush(fp);
  fclose(fp);
  printf("multisim_client_start: [%s] has started, info in %s\n", server_name,
         client_info_file.c_str());

  server_idx++;
  return 1;
}

void multisim_client_start(char const *server_runtime_directory, char const *server_name) {
  string server_address;
  int server_port;
  while (!get_server_address_and_port(server_runtime_directory, server_name, server_address,
                                      server_port)) {
    usleep(100000); // wait for 0.1s
  };
  printf("multisim_client_start: connect to server %s at %s:%0d\n", server_name,
         server_address.c_str(), server_port);
  while (
      !client_start(server_runtime_directory, server_name, server_address.c_str(), server_port)) {
    usleep(100000); // wait for 0.1s
  };
}

// #define SIMULATE_SEND_FAIL_CLIENT
int multisim_client_send_data(char const *server_name, const svOpenArrayHandle data_handle,
                              int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t send_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);

  for (int i = 0; i < buf_32b_size; i++) {
    send_buf[i] = data[i];
  }

#ifdef SIMULATE_SEND_FAIL_CLIENT
  static int cnt = 0;
  cnt++;
  if (cnt % 1000 == 0) {
    printf("multisim_client_send_data: simulate send fail\n");
    return 0;
  }
#endif

  r = send(sockets[idx], send_buf, sizeof(send_buf), 0);
  if (r <= 0) { // send failed
    return 0;
  }
  return 1;
}

int multisim_client_get_data(char const *server_name, svOpenArrayHandle data_handle,
                             int data_width) {
  int r;
  int buf_32b_size = (data_width + 31) / 32;
  uint32_t read_buf[buf_32b_size];
  int idx = server_name_to_idx[server_name];
  svBitVecVal *data = (svBitVecVal *)svGetArrayPtr(data_handle);

  r = read(sockets[idx], read_buf, sizeof(read_buf));
  if (r <= 0) {
    return 0;
  }

  for (int i = 0; i < buf_32b_size; i++) {
    data[i] = read_buf[i];
  }
  return 1;
}
