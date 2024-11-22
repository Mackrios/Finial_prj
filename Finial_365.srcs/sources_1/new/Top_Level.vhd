library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TopLevel is
    Port (
        CLK      : in  STD_LOGIC;                     -- 100 MHz clock
        SRST     : in  STD_LOGIC;                     -- Active-high reset
        SDA      : inout STD_LOGIC;                   -- SDA line for I2C/TWI
        SCL      : inout STD_LOGIC                    -- SCL line for I2C/TWI
    );
end TopLevel;

architecture Behavioral of TopLevel is

    -- Internal buffer signals for communication
    signal buf_srst     : STD_LOGIC;                     -- Reset signal
    signal buf_stb_i    : STD_LOGIC;                     -- Strobe signal
    signal buf_msg_i    : STD_LOGIC_VECTOR(7 downto 0);  -- Message signal (adjusted to 8-bit)
    signal buf_a_i      : STD_LOGIC_VECTOR(7 downto 0);  -- Address signal
    signal buf_d_i      : STD_LOGIC_VECTOR(7 downto 0);  -- Data signal
    signal buf_d_o      : STD_LOGIC_VECTOR(7 downto 0);  -- Data output signal
    signal buf_done_o   : STD_LOGIC;                     -- Done signal
    signal buf_err_o    : STD_LOGIC;                     -- Error signal

    -- Clock Divider component declaration
    component clock_divider is
        generic (DIVISOR : positive := 50000000);  -- Default for 2Hz output (100MHz/50M)
        port ( 
            mclk : in  STD_LOGIC;   -- Input clock
            sclk : out STD_LOGIC     -- Divided output clock
        );
    end component;

    -- State Machine component declaration
    component State_Machine is
        Port ( 
            clk         : in  STD_LOGIC;                     -- Input clock
            reset       : in  STD_LOGIC;                     -- Active-high reset
            byte_ready  : in  STD_LOGIC;                     -- Done signal from TWICtl
            twi_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Data from TWICtl
            srst        : out STD_LOGIC;                     -- Reset signal for TWICtl
            stb_i       : out STD_LOGIC;                     -- Strobe signal for TWICtl
            msg_i       : out STD_LOGIC_VECTOR(7 downto 0);  -- Message data for TWICtl
            a_i         : out STD_LOGIC_VECTOR(7 downto 0);  -- Address data for TWICtl
            d_i         : out STD_LOGIC_VECTOR(7 downto 0)   -- Data output for TWICtl
        );
    end component;

    -- TWICtl component declaration
    component TWICtl is
        generic (CLOCKFREQ : natural := 50);
        port ( 
            MSG_I  : in  STD_LOGIC_VECTOR(7 downto 0);  -- Correct type is 8-bit vector
            STB_I  : in  STD_LOGIC;
            A_I    : in  STD_LOGIC_VECTOR(7 downto 0);
            D_I    : in  STD_LOGIC_VECTOR(7 downto 0);
            D_O    : out STD_LOGIC_VECTOR(7 downto 0);
            DONE_O : out STD_LOGIC;
            ERR_O  : out STD_LOGIC;
            CLK    : in  STD_LOGIC;
            SRST   : in  STD_LOGIC;
            SDA    : inout STD_LOGIC;
            SCL    : inout STD_LOGIC
        );
    end component;

    -- Signals for internal clock division and state machine logic
    signal clk_div_out   : STD_LOGIC;  -- Divided clock output from clock divider
    signal sm_reset      : STD_LOGIC;  -- Reset signal to state machine
    signal sm_strobe     : STD_LOGIC;  -- Strobe signal to TWICtl
    signal sm_message    : STD_LOGIC_VECTOR(7 downto 0);  -- Message to TWICtl
    signal sm_address    : STD_LOGIC_VECTOR(7 downto 0);  -- Address to TWICtl
    signal sm_data       : STD_LOGIC_VECTOR(7 downto 0);  -- Data to TWICtl

begin

    -- Clock Divider Instance
    U_Clock_Divider : clock_divider
        generic map (DIVISOR => 50000000)  -- Set to divide by 50M for 2Hz output from 100MHz input
        port map (
            mclk => CLK,          -- Connect main clock to the clock divider
            sclk => clk_div_out   -- Output divided clock signal
        );

    -- State Machine Instance (used for controlling TWICtl)
    U_State_Machine : State_Machine
        port map (
            clk         => clk_div_out,        -- Use the divided clock for state machine
            reset       => SRST,               -- Reset signal
            byte_ready  => buf_done_o,         -- Done signal from TWICtl
            twi_data    => buf_d_o,            -- Data from TWICtl
            srst        => sm_reset,           -- Reset to TWICtl
            stb_i       => sm_strobe,          -- Strobe signal for TWICtl
            msg_i       => sm_message,         -- Message for TWICtl
            a_i         => sm_address,         -- Address for TWICtl
            d_i         => sm_data            -- Data for TWICtl
        );

    -- TWICtl Instance (I2C Controller)
    U_TWICtl : TWICtl
        generic map (CLOCKFREQ => 50)  -- 50 MHz clock frequency for the I2C protocol
        port map (
            MSG_I  => sm_message,          -- Message from State Machine
            STB_I  => sm_strobe,           -- Strobe from State Machine
            A_I    => sm_address,          -- Address from State Machine
            D_I    => sm_data,             -- Data from State Machine
            D_O    => buf_d_o,             -- Data output
            DONE_O => buf_done_o,          -- Done signal
            ERR_O  => buf_err_o,           -- Error signal
            CLK    => clk_div_out,         -- Use the divided clock for I2C timing
            SRST   => sm_reset,            -- Reset signal from State Machine
            SDA    => SDA,                 -- I2C SDA line
            SCL    => SCL                  -- I2C SCL line
        );

end Behavioral;
