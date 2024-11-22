library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity State_Machine is
    Port (
        clk         : in  STD_LOGIC;                     -- 100 MHz clock
        reset       : in  STD_LOGIC;                     -- Active-high reset
        byte_ready  : in  STD_LOGIC;                     -- Indicates when TWI data is ready
        twi_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Data from TWI controller
        scl_enable  : out STD_LOGIC;                     -- TWI clock enable
        display_out : out STD_LOGIC_VECTOR(15 downto 0); -- 16-bit combined MSB + LSB data
        srst        : out STD_LOGIC;                     -- Reset signal for TWICtl
        stb_i       : out STD_LOGIC;                     -- Strobe signal for TWICtl
        msg_i       : out STD_LOGIC;  -- Message data for TWICtl
        a_i         : out STD_LOGIC_VECTOR(7 downto 0);  -- Address data for TWICtl
        d_i         : out STD_LOGIC_VECTOR(7 downto 0)   -- Data output for TWICtl
    );
end State_Machine;

architecture Behavioral of State_Machine is

    -- State machine states
    type state_type is (IDLE, READ_MSB, READ_LSB, DONE, START);
    signal current_state, next_state : state_type;

    -- Internal signals for MSB and LSB data
    signal msb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal lsb_data   : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal temp_data  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

begin

    -- Clock passthrough for `scl_enable`
    scl_enable <= clk;

    -- Reset signal for TWICtl (directly tied to reset input of State_Machine)
    srst <= reset;

    -- State Machine Process
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;  -- Start at START state after reset
            msb_data <= (others => '0');
            lsb_data <= (others => '0');
            temp_data <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;

            case current_state is
               when IDLE =>
                    if byte_ready = '1' then
                        next_state <= START;  -- Start reading MSB
                    else
                        next_state <= IDLE;     -- Remain in START until byte_ready is asserted
                    end if;
            
                when START =>
                    if byte_ready = '1' then
                        next_state <= READ_MSB;  -- Transition to READ_MSB when byte_ready is asserted
                    else
                        next_state <= START;  -- Stay in START until byte_ready is asserted
                    end if;

                when READ_MSB =>
                    msb_data <= twi_data;       -- Capture MSB data from TWI controller
                    next_state <= READ_LSB;     -- Transition to READ_LSB

                when READ_LSB =>
                    lsb_data <= twi_data;       -- Capture LSB data from TWI controller
                    next_state <= DONE;         -- Transition to DONE after capturing both parts

                when DONE =>
                    temp_data <= msb_data & lsb_data;  -- Combine MSB and LSB into 16-bit display data
                    next_state <= START;         -- Go back to START state after done
                when others =>
                    next_state <= START;         -- Default to START state
            end case;
        end if;
    end process;

   -- Drive the final display output signal
    display_out <= temp_data;

    -- TWI Control Signals
    stb_i <= '1' when (current_state = READ_MSB or current_state = READ_LSB) else '0';

    -- Assign `msg_i` based on current state (MSB and LSB register addresses)
   msg_i <= '0' when current_state = READ_MSB else  -- Register address 0x00 for MSB
      '1';                                   -- Register address 0x01 for LSB

    a_i <= "1001011" & '1'; -- Sensor address 0x4B + read bit

    -- Data input is not required for read operations
    d_i <= (others => '0');

end Behavioral;
