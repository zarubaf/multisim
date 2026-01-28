<div align="center">

<img alt="Multisim" height="280" src="./.assets/multisim_light.png" />

simulate your RTL with real multi-threaded speed  
interface different simulators, chiplets and platforms together
</div>

# 💡 rationale

`multisim` is a systemverilog/DPI library allowing multiple simulations/platforms to run in parallel and communicate to simulate your DUT.

Typically, you can have:
* 1 **server simulation** with your DUT skeleton (NOC, fabric, etc)
* N **client simulations** with 1 big instance each (computing core, chip, etc)

## example: normal vs multisim simulation
Assuming your original simulation has N CPUs that take a lot of simulation time.

You could transform this DUT:  
![normal simulation](./.assets/multisim_normal.drawio.png)

Into this one, running on N+1 simulation instances:  
![multi simulations](./.assets/multisim_multi.drawio.png)

If the CPU is the bottleneck in terms of performance, you could speed up your simulation N times.

# 🚄 performance
Reusing [this example](./example/sim_server/sim_client/core/multi/src) where we have:
* 1 **server simulation** with 1 NOC
* `CPU number` **client simulations** with 1 `cpu` (slow module) each

![sim speed](./example/sim_server/sim_client/core/sim_speed.png)

# ⚙ usage
## available modules
* core library (ready/valid protocol)
    * `client->server`: [multisim_client_push](./src/core/multisim_client_push.sv) and [multisim_server_pull](./src/core/multisim_server_pull.sv)
    * `server->client`: [multisim_server_push](./src/core/multisim_server_push.sv) and [multisim_client_pull](./src/core/multisim_client_pull.sv)
* other protocols:
  * [axi](./src/axi/)
  * [apb](./src/apb/)
  * [quasi static signals](./src/quasi_static/) (useful for signals without control signals like IRQ)

## examples
All examples can be found [here](./example):

Tested platform combinations:

| client \ server | sim                                             | emu                                             | sw                                            | sim (4-state)                                                   |
| -               | -                                               | -                                               | -                                             | -                                                               |
| sim             | ✅ [examples](./example/sim_server/sim_client/) | ✅ [examples](./example/emu_server/sim_client/) | untested                                      | unsupported                                                     |
| emu             | untested                                        | untested                                        | untested                                      | unsupported                                                     |
| sw              | ✅ [examples](./example/sim_server/sw_client/)  | ✅ [examples](./example/emu_server/sw_client/)  | ✅ [examples](./example/sw_server/sw_client/) | unsupported                                                     |
| sim (4-state)   | unsupported                                     | unsupported                                     | unsupported                                   | ✅ [examples](./example/sim_4_state_server/sim_4_state_client/) |

## channels
* **server simulation** and **client simulations** communicate through channels
* channels direction can be `client->server` or `server->client`
* each **simulation** can use multiple channels
* `multisim` modules need a unique `server_name` to link a client/server channel together
* client modules need to set `server_runtime_directory` to know the port/ip address of each channel

## end of simulation
You can either:
* use the helper function `$MULTISIM_SRC/bin/kill_all_clients` to kill clients running in the backgroud
* use an "exit" channel to send exit instructions to the clients/servers you want to kill
* write a custom kill script

Find more info about PIDs/IPs of your clients in the server runtime directory in `.multisim/client*.txt`

## compilation
1. source [env.sh](./env.sh)
2. pass the right files to your simulator:
* server simulation, see [example](./example/sim_server/sim_client/core/multi/run_cpu)
* client simulation, see [example](./example/sim_server/sim_client/core/multi/run_top)

### shared objects
If your platform requires a shared object (.so file), it can be compiled like so:
```bash
# SW client example
g++ -o multisim_sw_client.so -g -shared -fPIC \
  -DMULTISIM_SW                               \
  $MULTISIM_SRC/core/multisim_client.cpp      \
  $MULTISIM_SRC/core/socket_server/client.cpp
```

Look in the [example](./example) directory for more examples.

# ⚖ pros and cons
Pros:
* speed: split your big DUT in as many smaller parts as you want
* interoperability: can use different simulators/platforms combinations (Verilator, VCS, Questa, Xcelium, Veloce, Palladium, Zebu, Qemu etc)
* scalability: as long as you have enough CPUs on your server

Cons:
* ⚠ **no cycle accuracy** ⚠: functionally accurate, but not cycle accurate
* harder debug: waveforms split on N+1 simulation, no time coherency in between them

# 🚀 future
* simple transaction logging to help debug
