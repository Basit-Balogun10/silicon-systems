module tb_counter;
  import tb_pkg::*;

  // N-bit counter signals
  logic clk, reset_n, enable;
  count_t count;
  
  // 1-bit counter own signals (isolated)
  logic reset_n_1bit, enable_1bit;
  logic [0:0] single_bit_count;
  logic single_bit_expected_count;

  // N-bit DUT
  counter #(
      .WIDTH(Width)
  ) counter_dut (
      .clk(clk),
      .reset_n(reset_n),
      .enable(enable),
      .count(count)
  );

  // 1-bit DUT, starts but held in reset
  counter #(
      .WIDTH(1)
  ) one_bit_counter (
      .clk(clk),
      .reset_n(reset_n_1bit),
      .enable(enable_1bit),
      .count(single_bit_count)
  );

  // 1-bit counter in reset by default
  initial begin
    reset_n_1bit = 0;
    enable_1bit  = 0;
  end

  task automatic setup(input string scenario_title, input bit auto_enable = 1);
    if (scenario_title != "") begin
      $display("------------------------------------------------------");
      $display(scenario_title);
      $display("------------------------------------------------------");
    end

    clk = 0;
    reset_n = 0;
    enable = 0;

    wait_cycles(clk, 2);

    $display(
        "\n--------------------------------Starting counter---------------------------------\n");
    reset_n = 1;

    wait_cycles(clk, 1);

    if (auto_enable) begin
      enable = 1;
      wait_cycles(clk, 1);
    end
  endtask

  task automatic test_async_reset_and_priority();
    setup("TEST ASYNC RESET AND RESET PRIORITY");
    // enable is high from setup — asserting reset here also verifies reset > enable priority

    #10 reset_n = 0;
    #1 $display("\nAsserting reset at time t=%0t", $time);

    check_count('0, count);
  endtask

  task automatic test_increment();
    count_t target_count;

    setup("TEST INCREMENT", 0);

    // count starts at 0, increments each cycle
    target_count=count_t'($urandom_range(1, (1 << Width) - 1));
    enable = 1;
    wait_cycles(clk, int'(target_count));

    check_count(target_count, count);
  endtask

  task automatic test_hold();
    count_t count_before_hold;

    setup("TEST HOLD", 0);
    $display("\nEnabling at time t=%0d", $time);
    enable = 1;

    count_before_hold = count_t'($urandom_range(
      1, (1 << Width) - 2
      ));  // Maxing the range right before Width-1 to allow testing increment without wrap/rollover below
    $display("\nCounting until count=%0d", count_before_hold);
    // count starts at 0, increments each cycle, so after N cycles count == N
    wait_cycles(clk, int'(count_before_hold));

    $display("\nTriggering hold at time t=%0t", $time);
    enable = 0;
    wait_cycles(clk, 1);

    check_count(count_before_hold, count);
  endtask

  task automatic test_wrap();
    setup("TEST WRAP", 0);

    enable = 1;
    wait_cycles(clk, (1 << Width)-1);

    $display("\nExpecting wrap in next cycle: count=%0d when width=%0d", count, Width);

    wait_cycles(clk, 1);

    check_count('0, count);
  endtask

  task automatic test_single_width();
    int unsigned test_cycles;

    single_bit_expected_count = 0;
    test_cycles = 4;

    
    // get the display banner from setup, but don't auto-enable main counter
    setup("TEST SINGLE WIDTH", 0);

    reset_n_1bit = 0;
    enable_1bit  = 0;
    wait_cycles(clk, 2);
    reset_n_1bit = 1;
    wait_cycles(clk, 1);
    enable_1bit = 1;

    for (int unsigned i = 0; i < test_cycles; i++) begin
      wait_cycles(clk, 1);
      single_bit_expected_count = ~single_bit_expected_count;
      $strobe("time=%0t ns single_bit_count=%d expected=%d", $time, single_bit_count, single_bit_expected_count);
      check_count(count_t'(single_bit_expected_count), count_t'(single_bit_count));
    end

    reset_n_1bit = 0;
    enable_1bit  = 0;
  endtask

  // Clock generation
  always #10 clk = ~clk;

  // Test runner
  initial begin
    int unsigned seed;
    seed = $urandom();  // first call returns the seed value
    $display("Using seed: %0d", seed);

    test_async_reset_and_priority();
    test_increment();
    test_hold();
    test_wrap();
    test_single_width();

    print_summary();
    #20 $finish;
  end

  // Monitoring
  always @(posedge clk)
    $strobe(
        "time=%0t ns clk=%d reset_n=%d enable=%d count=%d", $time, clk, reset_n, enable, count
    );

  initial begin
`ifdef WAVE_VCD
    $dumpfile("sim/waveforms/counter.vcd");
`else
    $dumpfile("sim/waveforms/counter.fst");
`endif
    $dumpvars(0, tb_counter);
  end
endmodule
