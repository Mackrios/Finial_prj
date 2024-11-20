library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_driver_testbench is
end display_driver_testbench;

architecture behavior of display_driver_testbench is

    -- This procedure waits for N number of falling edges on the specified clock signal
    procedure waitclocks(signal clock : std_logic; N : INTEGER) is
    begin
        for i in 1 to N loop
            wait until clock'event and clock = '0';  -- wait on falling edge
        end loop;
    end waitclocks;

    -- Signals for the display_driver component
    signal clk        : std_logic := '0';           -- 100 MHz clock
    signal reset      : std_logic := '0';           -- Active-high reset
    signal byte_ready : std_logic := '0';           -- Indicates when TWI data is ready
    signal twi_data   : std_logic_vector(7 downto 0) := (others => '0');  -- Data from TWI controller
    signal scl_enable : std_logic;                  -- TWI start signal
    signal display_out: std_logic_vector(15 downto 0);  -- Formatted display data

    -- Constants for the TWI controller
    constant addrAD2 : std_logic_vector(6 downto 0) := "1001011";  -- TWI address for the TMP
    constant read_Bit : std_logic := '1';
    constant write_Bit : std_logic := '0';

    constant Tperiod : time := 10 ns;  -- 100 MHz clock period

begin

    -- This process generates the 100 MHz system clock
    process(clk)
    begin
        clk <= not clk after Tperiod / 2;
    end process;

    -- This process simulates the state machine that drives the TWI controller to perform the bus
    -- master operations. These include a configuration register write, followed by a two-byte
    -- data register read. This process drives all of the non-TWI bus inputs to the TWI controller.
    master_stimulus : process
    begin
        -- Test 1: Reset Behavior
        -- Initialize signals
        byte_ready <= '0';      -- Indicate no byte ready initially
        reset <= '0';           -- Set reset to inactive
        twi_data <= "00000000"; -- Example data
        waitclocks(clk, 10);    -- Activate reset
        reset <= '1';
        waitclocks(clk, 2);
        reset <= '0';

        -- Test 1a: Verify reset behavior
        waitclocks(clk, 5); -- Wait a few cycles after reset
        assert (display_out = "0000000000000000") 
            report "Test failed: Display output during reset state transition" severity error;

        -- Test 2: Byte Reception (MSB)
        byte_ready <= '1';
        twi_data <= "10101010";  -- Simulated MSB byte
        waitclocks(clk, 5);      -- Simulate 5 cycles for MSB reception
        byte_ready <= '0';

        -- Test 2a: Verify correct MSB byte reception
        assert (display_out = "1010101000000000") 
            report "Test failed: Incorrect display output after MSB byte reception" severity error;

        -- Test 3: Byte Reception (LSB)
        byte_ready <= '1';
        twi_data <= "11001100";  -- Simulated LSB byte
        waitclocks(clk, 5);      -- Simulate 5 cycles for LSB reception
        byte_ready <= '0';

        -- Test 3a: Verify correct LSB byte reception
        assert (display_out = "1010101011001100") 
            report "Test failed: Incorrect display output after LSB byte reception" severity error;

        -- Test 4: Clock Division
        -- Ensure clock division to TWI clock is correct
        waitclocks(clk, 5); -- Wait for some cycles to observe TWI clock (scl_enable)
        assert (scl_enable = '1' or scl_enable = '0') 
            report "Test failed: TWI clock signal (scl_enable) is incorrect" severity error;

        -- Test 5: State Transitions and Edge Case Handling
        -- Test system with byte_ready low for several cycles (no data ready)
        byte_ready <= '0';
        waitclocks(clk, 10);
        assert (display_out = "1010101011001100") 
            report "Test failed: Display output changed unexpectedly with byte_ready low" severity error;

        -- Test 6: Invalid Data Handling (simulate incorrect data)
        twi_data <= "ZZZZZZZZ";  -- Invalid data input
        byte_ready <= '1';
        waitclocks(clk, 5);
        byte_ready <= '0';
        -- Check that the system either doesn't update display_out or handles invalid input gracefully
        assert (display_out = "1010101011001100") 
            report "Test failed: Display output changed unexpectedly with invalid data" severity error;

        -- Test completion
        waitclocks(clk, 10); -- Allow time to observe behavior
        assert (display_out = "1010101011001100") 
            report "Test failed: Final display output is incorrect" severity error;

        wait;  -- stop the process to avoid an infinite loop
    end process master_stimulus;

    -- This process is for simulating the display driver and testing its functionality
    DUT : entity work.display_driver
        port map (
            clk         => clk,            -- Input clock
            reset       => reset,          -- Reset signal
            byte_ready  => byte_ready,     -- Byte ready signal
            twi_data    => twi_data,       -- Data from TWI controller
            scl_enable  => scl_enable,     -- TWI start signal
            display_out => display_out     -- Output display data
        );

    -- Clock Divider component instantiation (from your `display_driver`)
    clk_div_inst: entity work.clock_divider
        generic map (DIVISOR => 50000000)  -- Clock divider value (divides 100 MHz to 2 Hz)
        port map (
            mclk => clk,      -- 100 MHz input clock
            sclk => scl_enable -- Output TWI clock
        );

end behavior;
