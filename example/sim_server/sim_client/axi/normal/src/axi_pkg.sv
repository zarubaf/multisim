package axi_pkg;

  parameter int AXI_ID_WIDTH = 16;
  parameter int AXI_ADDR_WIDTH = 32;
  parameter int AXI_DATA_WIDTH = 64;
  parameter int AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id;
    logic [AXI_ADDR_WIDTH-1:0] addr;
    logic [7:0]                len;     // AXI3: 4 bits; AXI4: 8 bits
    logic [2:0]                size;
    logic [1:0]                burst;
    logic [1:0]                lock;    // AXI3: 2 bits; AXI4: 1 bit
    logic [3:0]                cache;
    logic [2:0]                prot;
    logic [3:0]                qos;     // AXI4 only
    logic [3:0]                region;  // AXI4 only
  } axi_aw_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id;    // AXI3 only
    logic [AXI_DATA_WIDTH-1:0] data;
    logic [AXI_STRB_WIDTH-1:0] strb;
    logic                      last;
  } axi_w_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0] id;
    logic [1:0]              resp;
  } axi_b_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id;
    logic [AXI_ADDR_WIDTH-1:0] addr;
    logic [7:0]                len;     // AXI3: 4 bits; AXI4: 8 bits
    logic [2:0]                size;
    logic [1:0]                burst;
    logic [1:0]                lock;    // AXI3: 2 bits; AXI4: 1 bits
    logic [3:0]                cache;
    logic [2:0]                prot;
    logic [3:0]                qos;     // AXI4 only
    logic [3:0]                region;  // AXI4 only
  } axi_ar_t;

  typedef struct packed {
    logic [AXI_ID_WIDTH-1:0]   id;
    logic [AXI_DATA_WIDTH-1:0] data;
    logic [1:0]                resp;
    logic                      last;
  } axi_r_t;

endpackage
