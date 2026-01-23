module sim;

  reg clk;
  // tbx clkgen
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  //-----------------------------------------------------------
  // tasks
  //-----------------------------------------------------------
  task static write_rtl(bit [63:0] address, bit [63:0] wdata);
    bit [63:0] cmd[3];
    cmd[0] = 0;  // write
    cmd[1] = address;
    cmd[2] = wdata;

    rw_cmd_vld <= 1;
    rw_cmd <= {cmd[2], cmd[1], cmd[0]};
    @(posedge clk);
    while (rw_cmd_rdy != 1) begin
      @(posedge clk);
    end
    rw_cmd_vld <= 0;

    rw_rsp_rdy <= 1;
    @(posedge clk);
    while (rw_rsp_vld != 1) begin
      @(posedge clk);
    end
    rw_rsp_rdy <= 0;
  endtask

  task static read_rtl(input bit [63:0] address, output bit [63:0] rdata);
    bit [63:0] cmd[3];
    cmd[0] = 1;  // read
    cmd[1] = address;

    rw_cmd_vld <= 1;
    rw_cmd <= {cmd[2], cmd[1], cmd[0]};
    @(posedge clk);
    while (rw_cmd_rdy != 1) begin
      @(posedge clk);
    end
    rw_cmd_vld <= 0;

    rw_rsp_rdy <= 1;
    @(posedge clk);
    while (rw_rsp_vld != 1) begin
      @(posedge clk);
    end
    rw_rsp_rdy <= 0;
    rdata = rw_rsp;
  endtask

  task static exit_rtl();
    $display("exit");
    exit <= 1;
    @(posedge clk);
    while (exit_ack != 1) begin
      @(posedge clk);
    end
  endtask

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  bit exit;
  bit exit_ack;

  multisim_client_push #(
      .SERVER_RUNTIME_DIRECTORY("."),
      .DATA_WIDTH(1)
  ) i_multisim_server_pull_exit (
      .clk        (clk),
      .server_name("exit"),
      .data_rdy   (exit_ack),
      .data_vld   (exit),
      .data       (  /*unused*/)
  );

  always @(posedge clk) begin
    if (exit) begin
      $display("exit");
      while (!exit_ack) begin
        @(posedge clk);
      end
      $finish;
    end
  end

  //-----------------------------------------------------------
  // read/write
  //-----------------------------------------------------------
  bit rw_cmd_rdy;
  bit rw_cmd_vld;
  bit [3*64-1:0] rw_cmd;

  bit rw_rsp_rdy;
  bit rw_rsp_vld;
  bit [63:0] rw_rsp;

  multisim_client_push #(
      .SERVER_RUNTIME_DIRECTORY("."),
      .DATA_WIDTH(3 * 64)
  ) i_multisim_client_push_rw_cmd (
      .clk        (clk),
      .server_name("rw_cmd"),
      .data_rdy   (rw_cmd_rdy),
      .data_vld   (rw_cmd_vld),
      .data       (rw_cmd)
  );

  multisim_client_pull #(
      .SERVER_RUNTIME_DIRECTORY("."),
      .DATA_WIDTH(64)
  ) i_multisim_client_pull_rw_rsp (
      .clk        (clk),
      .server_name("rw_rsp"),
      .data_rdy   (rw_rsp_rdy),
      .data_vld   (rw_rsp_vld),
      .data       (rw_rsp)
  );


  // use "always" instead of "initial" here because of this Verilator quirk:
  // https://github.com/verilator/verilator/issues/5210
  always begin
    // avoid initial race condition
    @(posedge clk);

    //-----------------------------------------------------------
    // write and read
    //-----------------------------------------------------------
    $display("\nfunctional test: write then read");
    for (bit [63:0] address = 0; address < 10; address++) begin
      bit [63:0] wdata = 64'hbebecacadeadb00b + address;
      bit [63:0] rdata;
      write_rtl(address, wdata);
      $display("0x%x -> [%0d]", wdata, address);
      read_rtl(address, rdata);
      $display("0x%x <- [%0d]", rdata, address);
    end

    $display("\nfunctional test: all writes then all reads");
    for (bit [63:0] address = 0; address < 10; address++) begin
      bit [63:0] wdata = 64'hdeadbeefcafedeca + address;
      write_rtl(address, wdata);
      $display("0x%x -> [%0d]", wdata, address);
    end
    for (bit [63:0] address = 0; address < 10; address++) begin
      bit [63:0] rdata;
      read_rtl(address, rdata);
      $display("0x%x <- [%0d]", rdata, address);
    end

    //-----------------------------------------------------------
    // exit
    //-----------------------------------------------------------
    exit_rtl();
  end


endmodule

