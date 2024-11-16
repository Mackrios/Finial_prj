library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TopLevel is
    Port ( CLK      : in STD_LOGIC;         -- Fast input clock
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
           DISP_OUT : out STD_LOGIC_VECTOR(7 downto 0)  -- Display output
           );
end TopLevel;

architecture Behavioral of TopLevel is

    -- Internal signals for connecting components
    signal clk_div : STD_LOGIC;               -- Divided clock for the slower logic
    signal internal_D_O : STD_LOGIC_VECTOR(7 downto 0); 
    signal internal_DONE_O : STD_LOGIC;
    signal internal_ERR_O : STD_LOGIC;

    -- Clock Divider component declaration
    component ClockDivider is
        Port ( CLK_IN  : in STD_LOGIC;
               CLK_OUT : out STD_LOGIC );
    end component;

    -- Display Logic component declaration
    component DisplayLogic is
        Port ( DATA_IN : in STD_LOGIC_VECTOR(7 downto 0);
               DISP_SEL : out STD_LOGIC_VECTOR(7 downto 0);
               DISP_OUT : out STD_LOGIC_VECTOR(7 downto 0) );
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
    -- Instantiate the Clock Divider
    U_ClockDivider: ClockDivider
        Port map (
            CLK_IN  => CLK,
            CLK_OUT => clk_div
        );

    -- Instantiate the TWICtl component
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

    -- Instantiate the Display Logic component
    U_DisplayLogic: DisplayLogic
        Port map (
            DATA_IN => internal_D_O,
            DISP_SEL => DISP_SEL,
            DISP_OUT => DISP_OUT
        );

    -- Connect the outputs from the TWICtl to the top-level outputs
    D_O    <= internal_D_O;
    DONE_O <= internal_DONE_O;
    ERR_O  <= internal_ERR_O;

end Behavioral;
