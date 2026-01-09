`timescale 1ns/1ps

module tb_i2c_simple();

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Control signals
    reg start_write;
    reg start_read;
    reg [7:0] slave_addr;
    reg [15:0] mem_addr;
    reg [7:0] data_in;
    
    // Outputs
    wire [7:0] data_out;
    wire busy;
    wire done;
    wire error;
    
    // I2C lines
    wire scl;
    wire sda;
    
    // Debug signals
    wire debug_sda_out;
    wire debug_sda_in;
    wire debug_sda_en;
    wire [3:0] debug_state;
    wire [3:0] debug_bit_cnt;
    wire [7:0] debug_shift_reg;
    
    // Pull-ups for I2C lines (simulate external pull-ups)
    pullup(scl);
    pullup(sda);
    
    // Instantiate I2C Master
    i2c_eeprom_master dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_write(start_write),
        .start_read(start_read),
        .slave_addr(slave_addr),
        .mem_addr(mem_addr),
        .data_in(data_in),
        .data_out(data_out),
        .busy(busy),
        .done(done),
        .error(error),
        .scl(scl),
        .sda(sda),
        .debug_sda_out(debug_sda_out),
        .debug_sda_in(debug_sda_in),
        .debug_sda_en(debug_sda_en),
        .debug_state(debug_state),
        .debug_bit_cnt(debug_bit_cnt),
        .debug_shift_reg(debug_shift_reg)
    );
    
    // Clock generation: 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Monitor I2C signals
    always @(negedge scl) begin
        $display("Time=%0t | SCL=LOW | SDA=%b | State=%d | BitCnt=%d | ShiftReg=0x%02X", 
                 $time, sda, debug_state, debug_bit_cnt, debug_shift_reg);
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        start_write = 0;
        start_read = 0;
        slave_addr = 7'b1010_000;  // 0x50 - M24C32 address
        mem_addr = 16'h0000;
        data_in = 8'h00;
        
        // Create VCD file for waveform viewing
        $dumpfile("i2c_test.vcd");
        $dumpvars(0, tb_i2c_simple);
        
        $display("\n========================================");
        $display("I2C Master Simple Test");
        $display("========================================\n");
        
        // Release reset
        #100;
        rst_n = 1;
        #100;
        
        // =============================================
        // TEST 1: Write Operation
        // =============================================
        $display("\n--- TEST 1: WRITE 0x55 to address 0x0010 ---");
        mem_addr = 16'h0010;
        data_in = 8'h55;
        
        @(posedge clk);
        start_write = 1;
        @(posedge clk);
        start_write = 0;
        
        // Wait for transaction to complete
        wait(done || error);
        #100;
        
        if (error) begin
            $display("ERROR: Write failed - NACK received");
        end else begin
            $display("SUCCESS: Write completed");
        end
        
        #1000;
        
        // =============================================
        // TEST 2: Read Operation
        // =============================================
        $display("\n--- TEST 2: READ from address 0x0010 ---");
        mem_addr = 16'h0010;
        
        @(posedge clk);
        start_read = 1;
        @(posedge clk);
        start_read = 0;
        
        // Wait for transaction to complete
        wait(done || error);
        #100;
        
        if (error) begin
            $display("ERROR: Read failed - NACK received");
        end else begin
            $display("SUCCESS: Read completed, Data = 0x%02X", data_out);
        end
        
        #1000;
        
        // =============================================
        // TEST 3: Write to different address
        // =============================================
        $display("\n--- TEST 3: WRITE 0xAA to address 0x0100 ---");
        mem_addr = 16'h0100;
        data_in = 8'hAA;
        
        @(posedge clk);
        start_write = 1;
        @(posedge clk);
        start_write = 0;
        
        wait(done || error);
        #100;
        
        if (error) begin
            $display("ERROR: Write failed");
        end else begin
            $display("SUCCESS: Write completed");
        end
        
        #1000;
        
        // =============================================
        // Summary
        // =============================================
        $display("\n========================================");
        $display("Test Summary:");
        $display("- Check waveform for I2C protocol");
        $display("- START condition: SDA falls while SCL high");
        $display("- Data changes when SCL low");
        $display("- STOP condition: SDA rises while SCL high");
        $display("- Look for: START-ADDR-ACK-DATA-ACK-STOP");
        $display("========================================\n");
        
        #5000;
        $display("Simulation Complete");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500000;
        $display("\nERROR: Simulation timeout!");
        $finish;
    end
    
    // Display state changes
    always @(debug_state) begin
        case(debug_state)
            0:  $display("State: IDLE");
            1:  $display("State: START_BIT");
            2:  $display("State: SEND_ADDR_W");
            3:  $display("State: ACK1");
            4:  $display("State: SEND_MEM_H");
            5:  $display("State: ACK2");
            6:  $display("State: SEND_MEM_L");
            7:  $display("State: ACK3");
            8:  $display("State: SEND_DATA");
            9:  $display("State: ACK4");
            10: $display("State: RESTART");
            11: $display("State: SEND_ADDR_R");
            12: $display("State: ACK5");
            13: $display("State: READ_DATA");
            14: $display("State: SEND_NACK");
            15: $display("State: STOP_BIT");
        endcase
    end

endmodule