library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_driver is
    Port (
        clk         : in  STD_LOGIC;                     -- 100 MHz clock
        reset       : in  STD_LOGIC;                     -- Active-high reset
        byte_ready  : in  STD_LOGIC;                     -- Indicates when TWI data is ready
        twi_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Data from TWI controller
        scl_enable  : out STD_LOGIC;                     -- TWI start signal
        display_out : out STD_LOGIC_VECTOR(15 downto 0)  -- Formatted display data
    );
end display_driver;

architecture Behavioral of display_driver is

    -- State machine states
    type state_type is (IDLE, READ_MSB, READ_LSB, DONE);
    signal current_state, next_state : state_type;

    -- Internal Signals for MSB and LSB data
    signal msb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal lsb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal temp_data  : STD_LOGIC_VECTOR(15 downto 0);

begin

    -- Clock divider signal (2 Hz output)
    scl_enable <= clk; 

    -- State Machine Process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            msb_data <= (others => '0');
            lsb_data <= (others => '0');
            next_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;

            case current_state is
                when IDLE =>
                    if byte_ready = '1' then  -- Transition to READ_MSB when byte_ready is asserted
                        next_state <= READ_MSB;
                    end if;

                when READ_MSB =>
                    msb_data <= twi_data;  -- Store MSB data
                    next_state <= READ_LSB;  -- Transition to READ_LSB after reading MSB

                when READ_LSB =>
                    lsb_data <= twi_data;  -- Store LSB data
                    next_state <= DONE;    -- Transition to DONE after reading LSB

                when DONE =>
                    next_state <= IDLE;    -- Return to IDLE state after processing

                when others =>
                    next_state <= IDLE;    -- Default state is IDLE
            end case;
        end if;
    end process;

    -- Combine MSB and LSB to form the 16-bit display data
    temp_data <= msb_data & lsb_data;

    -- Drive the final display output signal
    display_out <= temp_data;

end Behavioral;
