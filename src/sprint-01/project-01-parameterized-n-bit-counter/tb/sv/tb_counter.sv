module tb_counter;
  import tb_pkg::*;

  // N-bit counter signals
  logic clk, reset_n, enable, up_down;
  count_t count;

  // 1-bit counter own signals (isolated)
  logic reset_n_1bit, enable_1bit, up_down_1bit;
  logic [0:0] single_bit_count;
  logic single_bit_expected_count;

  // N-bit DUT
  counter #(
      .WIDTH(Width)
  ) counter_dut (
      .clk(clk),
      .reset_n(reset_n),
      .enable(enable),
      .up_down(up_down),
      .count(count)
  );

  // 1-bit DUT, starts but held in reset
  counter #(
      .WIDTH(1)
  ) one_bit_counter (
      .clk(clk),
      .reset_n(reset_n_1bit),
      .enable(enable_1bit),
      .up_down(up_down_1bit),
      .count(single_bit_count)
  );

  // 1-bit counter in reset by default
  initial begin
    reset_n_1bit = 0;
    enable_1bit  = 0;
    up_down_1bit = 1; // counting up by default
  end

  task automatic setup(input string scenario_title, input bit count_direction = 1, input bit auto_enable = 1);
    if (scenario_title != "") begin
      $display("------------------------------------------------------");
      $display(scenario_title);
      $display("------------------------------------------------------");
    end

    clk = 0;
    reset_n = 0;
    enable = 0;
    up_down = count_direction;

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
  // enable is high from setup - asserting reset here also verifies reset > enable priority
    setup("TEST ASYNC RESET AND RESET PRIORITY OVER UP DIRECTION", 1);

    #(ClockPeriod/2) reset_n = 0;
    #1 $display("\nAsserting reset at time t=%0t", $time);

    check_count('0, count);

    setup("TEST ASYNC RESET AND RESET PRIORITY OVER DOWN DIRECTION", 0);
    #(ClockPeriod/2) reset_n = 0;
    #1 $display("\nAsserting reset at time t=%0t", $time);

    check_count('1, count);
  endtask

  task automatic test_increment();
    count_t target_count;

    setup("TEST INCREMENT", 1, 0);

    // count starts at 0, increments each cycle
    target_count = count_t'($urandom_range(int'(count_t'('1)) - 1, 1));
    enable = 1;
    wait_cycles(clk, int'(target_count));

    check_count(target_count, count);
  endtask

  task automatic test_decrement();
    count_t target_count;

    setup("TEST DECREMENT", 0, 0);

    // count starts at (2^N - 1), decrements each cycle
    target_count = count_t'($urandom_range(int'(count_t'('1)) - 2, 0));
    enable = 1;
    wait_cycles(clk, int'(int'(count_t'('1)) - int'(target_count)));

    check_count(target_count, count);
  endtask

  task automatic test_hold_up();
    count_t count_before_hold;

    setup("TEST HOLD (UP DIRECTION SELECTED)", 1, 0);
    $display("\nEnabling at time t=%0d", $time);
    enable = 1;

    count_before_hold = count_t'($urandom_range(
      int'(count_t'('1)) - 2, 1
      ));// Maxing the range right before Width-1 to allow testing increment without wrap/rollover below
    $display("\nCounting until count=%0d", count_before_hold);
    // count starts at 0, increments each cycle, so after N cycles count == N
    wait_cycles(clk, int'(count_before_hold));

    $display("\nTriggering hold at time t=%0t", $time);
    enable = 0;
    wait_cycles(clk, 1);

    check_count(count_before_hold, count);
  endtask

  task automatic test_hold_down();
    count_t count_before_hold;

    setup("TEST HOLD (DOWN DIRECTION SELECTED)", 0, 0);
    $display("\nEnabling at time t=%0d", $time);
    enable = 1;

    count_before_hold = count_t'($urandom_range(
      int'(count_t'('1)) - 1, 1
      ));  // Maxing the range right before '0 to allow testing decrement without wrap/rollover below
    $display("\nCounting until count=%0d", count_before_hold);
    // count starts at 0, increments each cycle, so after N cycles count == N
    wait_cycles(clk, int'(int'(count_t'('1)) - int'(count_before_hold)));

    $display("\nTriggering hold at time t=%0t", $time);
    enable = 0;
    wait_cycles(clk, 1);

    check_count(count_before_hold, count);
  endtask

  task automatic test_wrap_up();
    setup("TEST WRAP UP", 1, 0);

    enable = 1;
    wait_cycles(clk, int'(count_t'('1)));
    $display("\nCount should now be maximum value (2^N - 1)");
    check_count(count_t'('1), count);

    $display("\nExpecting wrap in next cycle: count=%0d when width=%0d", count, Width);
    wait_cycles(clk, 1);
    check_count('0, count);
  endtask

  task automatic test_wrap_down();
    setup("TEST WRAP DOWN", 0, 0);

    enable = 1;
    wait_cycles(clk, int'(count_t'('1)));
    $display("\nCount should now be minimum value ('0)");
    check_count(count_t'('0), count);

    $display("\nExpecting wrap in next cycle: count=%0d when width=%0d", count, Width);
    wait_cycles(clk, 1);
    check_count(count_t'('1), count);
  endtask

  task automatic test_direction_change_mid_run();
  count_t old_count, target_count;
  int unsigned min_wrap_cycles, max_wrap_cycles, target_cycles;
  bit direction = 1;

  setup("TEST DIRECTION CHANGE MID RUN", direction, 0); // Counting up initially

  // 4 count cycles from 0: up -> down-> up (wrap) -> down (wrap)
  target_count = count_t'($urandom_range(int'(count_t'('1)), 1));
  $display("\ntarget_count=%0d", target_count);
  enable = 1;
  wait_cycles(clk, int'(target_count));
  check_count(target_count, count);

  up_down = 0;
  target_count = count_t'($urandom_range(int'(target_count), 0));
  $display("\ntarget_count=%0d", target_count);
  wait_cycles(clk, int'(count) - int'(target_count));
  check_count(target_count, count);

  // Ranging count cycles to prevent multiple counter wraps (counting beyond 2^N - 1)
  up_down = 1;
  old_count = count;
  min_wrap_cycles = int'(count_t'('1)) - int'(count) + 1;
  max_wrap_cycles = int'(min_wrap_cycles + int'(count_t'('1)));
  target_cycles = $urandom_range(max_wrap_cycles, min_wrap_cycles);
  $display("\ncount=%0d target_cycles=%0d min_wrap_cycles=%0d max_wrap_cycles=%0d", count, target_cycles, min_wrap_cycles, max_wrap_cycles);
  wait_cycles(clk, target_cycles);
  check_count(count_t'((int'(old_count) + target_cycles) % (int'(count_t'('1)) + 1)), count);

  // Ranging count cycles to prevent multiple counter wraps (counting below 0)
  up_down = 0;
  old_count = count;
  min_wrap_cycles = int'(count) + 1;
  max_wrap_cycles = int'(min_wrap_cycles + int'(count_t'('1)));
  target_cycles = $urandom_range(max_wrap_cycles, min_wrap_cycles);
  $display("\ncount=%0d target_cycles=%0d min_wrap_cycles=%0d max_wrap_cycles=%0d", count, target_cycles, min_wrap_cycles, max_wrap_cycles);
    wait_cycles(clk, target_cycles);
  // expected = (old_count - cycles + 2^WIDTH) % 2^WIDTH
  // alt: count_t'(int'(old_count) - target_cycles) relies on unsigned underflow
  check_count(
      count_t'((int'(old_count) - target_cycles + int'(count_t'('1)) + 1) % (int'(count_t'('1)) + 1)),
      count);
  endtask

  task automatic test_reset_mid_count_then_resume();
  count_t target_count;

  setup("TEST RESET MID-COUNT, THEN RESUME", 1, 0); // counting up initially

  target_count = count_t'($urandom_range(int'(count_t'('1)), 0));
  enable = 1;
  wait_cycles(clk, int'(target_count));

  check_count(target_count, count);

  reset_n = 0;
  wait_cycles(clk, 1);
  check_count('0, count);

  up_down = 0;
  reset_n = 1;
  target_count = count_t'($urandom_range(int'(count_t'('1)), 0));
  $display("count=%0d target_count=%0d", count, target_count);
  wait_cycles(clk, int'(int'(count_t'('1)) - int'(target_count) + 1)); // +1 cycle because we start from count=0 following reset;

  check_count(target_count, count);
  endtask;

  task automatic test_single_width_up();
    int unsigned test_cycles;

    single_bit_expected_count = 0;
    test_cycles = 4;

    // get the display banner from setup, but don't auto-enable main counter
    setup("TEST SINGLE WIDTH (UP DIRECTION SELECTED)", 1, 0);

    reset_n_1bit = 0;
    enable_1bit  = 0;
    up_down_1bit = 1;
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

  task automatic test_single_width_down();
    int unsigned test_cycles;

    single_bit_expected_count = 1;
    test_cycles = 4;

    // get the display banner from setup, but don't auto-enable main counter
    setup("TEST SINGLE WIDTH (DOWN DIRECTION SELECTED)", 0, 0);

    reset_n_1bit = 0;
    enable_1bit  = 0;
    up_down_1bit = 0;
    wait_cycles(clk, 2);
    reset_n_1bit = 1;
    wait_cycles(clk, 1);
    enable_1bit = 1;

    for (int unsigned i = 0; i < test_cycles; i++) begin
      wait_cycles(clk, 1);
      single_bit_expected_count = ~single_bit_expected_count;
      $strobe("time=%0t ns single_bit_count=%d expected=%d", $time, single_bit_count,
              single_bit_expected_count);
      check_count(count_t'(single_bit_expected_count), count_t'(single_bit_count));
    end

    reset_n_1bit = 0;
    enable_1bit  = 0;
  endtask

  // Clock generation
  always #(ClockPeriod/2) clk = ~clk;

  // Test runner
  initial begin
    int unsigned seed;
    seed = $urandom();  // first call returns the seed value
    $display("Using seed: %0d", seed);

    test_async_reset_and_priority();
    test_increment();
    test_hold_up();
    test_hold_down();
    test_wrap_up();
    test_wrap_down();
    test_direction_change_mid_run();
    test_reset_mid_count_then_resume();
    test_single_width_up();
    test_single_width_down();

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
