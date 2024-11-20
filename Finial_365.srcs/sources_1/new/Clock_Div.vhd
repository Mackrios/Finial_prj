library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_divider is
    generic (DIVISOR : positive := 50000000); -- Default for 2 Hz clock
    port (
        mclk : in  std_logic;  -- 100 MHz system clock
        sclk : out std_logic   -- Divided clock output
    );
end clock_divider;

architecture behavior of clock_divider is
    signal sclki : std_logic := '0'; -- Internal signal for clock toggle
    signal count : integer range 0 to DIVISOR-1 := 0; -- Counter variable
begin
    div_clk: process(mclk)
    begin
        if rising_edge(mclk) then
            if count = (DIVISOR / 2) - 1 then
                sclki <= not sclki; -- Toggle output clock
                count <= 0;         -- Reset counter
            else
                count <= count + 1; -- Increment counter
            end if;
        end if;
    end process;

    -- Assign the toggled signal to output
    sclk <= sclki; 
end behavior;
