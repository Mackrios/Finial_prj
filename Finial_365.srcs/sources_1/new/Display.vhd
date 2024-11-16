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

    type state_type is (IDLE, READ_MSB, READ_LSB, DONE);
    signal current_state, next_state : state_type;

    -- Internal Signals
    signal msb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal lsb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal temp_data  : STD_LOGIC_VECTOR(15 downto 0);

   
    signal clk_div    : STD_LOGIC;

 
    component clock_divider
        generic (DIVISOR : positive := 50000000);  
        port (
            mclk : in  std_logic;
            sclk : out std_logic
        );
    end component;

begin

    clk_div_inst: clock_divider
        port map (
            mclk => clk,        -- 100 MHz input clock
            sclk => clk_div     -- 2 Hz output clock
        );

    scl_enable <= clk_div;  

    -- State Machine Process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            msb_data <= (others => '0');
            lsb_data <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;

            case current_state is
                when IDLE =>
                    if clk_div = '1' then
                        next_state <= READ_MSB;
                    end if;

                when READ_MSB =>
                    if byte_ready = '1' then
                        msb_data <= twi_data;
                        next_state <= READ_LSB;
                    end if;

                when READ_LSB =>
                    if byte_ready = '1' then
                        lsb_data <= twi_data;
                        next_state <= DONE;
                    end if;

                when DONE =>
                    next_state <= IDLE;

                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    -- Combine MSB and LSB 
    temp_data <= msb_data & lsb_data;

    -- Drive the final display output signal
    display_out <= temp_data;

end Behavioral;
