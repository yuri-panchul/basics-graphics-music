// Test double for the board wrapper's startup reset contract.
// This is not a model or implementation of Intel's Reset Release IP.
// Only test_de25_nano.py adds this file, with the INTEL_VERSION branch enabled.
module agilex_reset_release (output ninit_done);
    assign ninit_done = tb.ninit_done_request;
endmodule
