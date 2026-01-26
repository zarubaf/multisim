# SW Server / SW Client Example

This example demonstrates how to use multisim with both server and client running as pure software applications (no simulation or emulation involved).

## Architecture

- **SW Server** (`sw_server.cpp`): A C++ application that implements a simple memory server with read/write operations
- **SW Client** (`sw_client.cpp`): A C++ application that connects to the server and performs memory read/write operations

## Communication Channels

The server and client communicate through three multisim channels:

1. `exit` - Used by the client to signal the server to exit
2. `rw_cmd` - Client sends read/write commands to the server (3x64-bit: [rwb, address, wdata])
3. `rw_rsp` - Server sends read responses back to the client (1x64-bit: [rdata])

## Memory Interface

The server implements a simple 256-entry memory array (64-bit values).

### Write Operation
- Command: `[rwb=0, address, wdata]`
- Response: `[0]`

### Read Operation
- Command: `[rwb=1, address, unused]`
- Response: `[rdata]`

## Running the Example

```bash
# Make sure you've sourced the environment
source ../../../../env.sh

# Run the example
./run
```

The script will:
1. Compile the server application
2. Compile the client application
3. Start the server in the background
4. Run the client which performs functional and bandwidth tests
5. Clean up automatically

## Tests Performed

1. **Functional test: write then read** - Writes a value and immediately reads it back
2. **Functional test: all writes then all reads** - Writes multiple values, then reads them all back
3. **Bandwidth test: write** - Measures write bandwidth
4. **Bandwidth test: read** - Measures read bandwidth

## Expected Output

The client will print test progress and bandwidth measurements. Both server and client will log their operations. The test passes if all assertions succeed.
