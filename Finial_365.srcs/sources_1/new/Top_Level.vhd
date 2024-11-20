library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TopLevel is
    Port ( CLK      : in STD_LOGIC;         -- Fast input clock (100 MHz)
           SRST     : in STD_LOGIC;         -- Synchronous reset
           MSG_I    : in STD_LOGIC;         -- Message input for TWI
           STB_I    : in STD_LOGIC;         -- Strobe input for TWI
           A_I      : in STD_LOGIC_VECTOR(7 downto 0); -- Address input for TWI
           D_I      : in STD_LOGIC_VECTOR(7 downto 0); -- Data input for TWI
           D_O      : out STD_LOGIC_VECTOR(7 downto 0); -- Data output from TWI
           DONE_O   : out STD_LOGIC;        -- Done signal from TWI
           ERR_O    : out STD_LOGIC;        -- Error signal from TWI
           SDA      : inout STD_LOGIC;      -- SDA line for I2C/TWI
           SCL      : inout STD_LOGIC;      -- SCL line for I2C/TWI
           DISP_SEL : out STD_LOGIC_VECTOR(7 downto 0); -- Display select
           DISP_OUT : out STD_LOGIC_VECTOR(15 downto 0)  -- Display output
           );
end TopLevel;

architecture Behavioral of TopLevel is

    -- Internal signals for connecting components
    signal clk_div : STD_LOGIC;               -- Divided clck for the slower logic
    signal internal_D_O : STD_LOGIC_VECTOR(7 downto 0); 
    signal internal_DONE_O : STD_LOGIC;
    signal internal_ERR_O : STD_LOGIC;
    signal display_data : STD_LOGIC_VECTOR(15 downto 0); -- For display output

    -- Clock Divider component declaration
    component clock_divider is
        generic (DIVISOR : positive := 50000000); 
        port ( mclk : in STD_LOGIC;
               sclk : out STD_LOGIC );
    end component;

    -- Display Driver component declaration
    component display_driver is
        Port ( clk         : in  STD_LOGIC;                     -- 100 MHz clock
               reset       : in  STD_LOGIC;                     -- Active-high reset
               byte_ready  : in  STD_LOGIC;                     -- Indicates when TWI data is ready
               twi_data    : in  STD_LOGIC_VECTOR(7 downto 0);  -- Data from TWI controller
               scl_enable  : out STD_LOGIC;                     -- TWI start signal
               display_out : out STD_LOGIC_VECTOR(15 downto 0)  -- Formatted display data
             );
    end component;

    -- TWICtl component declaration
    component TWICtl is
        generic (CLOCKFREQ : natural := 50);
        port ( MSG_I  : in STD_LOGIC;
               STB_I  : in STD_LOGIC;
               A_I    : in  STD_LOGIC_VECTOR(7 downto 0);
               D_I    : in  STD_LOGIC_VECTOR(7 downto 0);
               D_O    : out STD_LOGIC_VECTOR(7 downto 0);
               DONE_O : out STD_LOGIC;
               ERR_O  : out STD_LOGIC;
               CLK    : in STD_LOGIC;
               SRST   : in STD_LOGIC;
               SDA    : inout STD_LOGIC;
               SCL    : inout STD_LOGIC);
    end component;

begin
    --  the Clock Divider
    U_ClockDivider: clock_divider
        Port map (
            mclk  => CLK,        -- Fast input clock (100 MHz)
            sclk  => clk_div     -- Output divided clock
        );

    --  the TWICtl component
    U_TWICtl: TWICtl
        generic map (CLOCKFREQ => 50)
        port map (
            MSG_I  => MSG_I,
            STB_I  => STB_I,
            A_I    => A_I,
            D_I    => D_I,
            D_O    => internal_D_O,
            DONE_O => internal_DONE_O,
            ERR_O  => internal_ERR_O,
            CLK    => clk_div,      -- Use divided clock for the TWI component
            SRST   => SRST,
            SDA    => SDA,
            SCL    => SCL
        );

    -- Instantiate the Display Driver component
    U_DisplayLogic: display_driver
        Port map (
            clk         => CLK,
            reset       => SRST,
            byte_ready  => internal_DONE_O, -- Byte ready signal from TWI
            twi_data    => internal_D_O,
            scl_enable  => SCL,  -- Output SCL signal for TWI
            display_out => display_data -- Final 16-bit display data
        );

    -- Drive the display output to the top-level output
    DISP_OUT <= display_data;
    DISP_SEL <= (others => '1'); --set display selection

    -- Connect the outputs from the TWICtl to the top-level outputs
    D_O    <= internal_D_O;
    DONE_O <= internal_DONE_O;
    ERR_O  <= internal_ERR_O;

end Behavioral;
