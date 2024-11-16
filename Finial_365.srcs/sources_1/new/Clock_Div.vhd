library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_divider is
    generic (DIVISOR : positive := 10000);
    port (
        mclk : in  std_logic;
        sclk : out std_logic
    );
end clock_divider;

architecture behavior of clock_divider is
    signal sclki : std_logic := '0';
begin
    div_clk: process(mclk)
        variable count : integer range 0 to DIVISOR/2 := 0;
    begin
        if rising_edge(mclk) then
            if count = (DIVISOR / 2) - 1 then
                sclki <= not sclki;
                count := 0;
            else
                count := count + 1;
            end if;
        end if;
    end process;
    sclk <= sclki;
end behavior;
