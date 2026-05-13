package tb_pkg;
  localparam int unsigned Width = 4;
  localparam int unsigned ClockPeriod = 20;
  typedef logic [Width-1:0] count_t;
  int unsigned tests_passed = 0;
  int unsigned tests_failed = 0;

  task automatic wait_cycles(ref logic clk, input int unsigned cycles);
    repeat (cycles) @(posedge clk);
  endtask

  task automatic check_count(input count_t expected_count, input count_t count);
    $display("------------------------------------------------------");
    if (count == expected_count) begin
      tests_passed++;
      $display("✅ PASS: count=%0d expected=%0d", count, expected_count);
    end else begin
      tests_failed++;
      $error("❌ FAIL: expected=%0d got=%0d", expected_count, count);
    end
    $display("------------------------------------------------------\n");
  endtask

  task automatic print_summary();
    int unsigned total = tests_passed + tests_failed;
    $display("\n===================================================");
    $display("  Results: %0d/%0d passed", tests_passed, total);
    if (tests_failed == 0) $display("  Status:  ALL TESTS PASSED ✓");
    else $display("  Status:  %0d FAILED ✗", tests_failed);
    $display("===================================================\n");
  endtask
endpackage
