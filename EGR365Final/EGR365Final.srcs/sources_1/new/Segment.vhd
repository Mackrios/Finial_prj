
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity Temp_Display is
--    Port (
--        CPU_RESETN : in  STD_LOGIC := '0';
--        CLK100MHZ  : in  STD_LOGIC := '0';
--        TEMP_DATA  : in  STD_LOGIC_VECTOR(15 downto 0);  -- 16-bit temperature data input
--        CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;
--        AN        : out STD_LOGIC_VECTOR (7 downto 0);
--        DP        : out STD_LOGIC
--    );
--end Temp_Display;

--architecture Behavioral of Temp_Display is
--    signal clk_divsig : STD_LOGIC;
--    signal counter_reg : unsigned(1 downto 0) := "00";
--    signal bcd_values : STD_LOGIC_VECTOR(3 downto 0);
--    signal temp_int   : integer range 0 to 99;
--    signal temp_frac  : integer range 0 to 9;
--    signal temp_bcd   : STD_LOGIC_VECTOR(15 downto 0);

--    -- Clock Divider Component Declaration
--    component clock_divider is
--        generic (DIVISOR : positive := 100000);  -- Adjust for display refresh
--        Port (mclk : in std_logic; sclk : out std_logic);
--    end component;

--begin

    
--    CLK_DIV: clock_divider
--        generic map (DIVISOR => 100000)  -- Adjust as needed
--        port map (mclk => CLK100MHZ, sclk => clk_divsig);

--    -- Convert TEMP_DATA to Integer and Fractional parts using fixed-point math
--    process(TEMP_DATA)
--        variable temp_value : integer;
--    begin
--        -- Convert raw data to Celsius (temp_data is signed 16-bit)
--        temp_value := to_integer(signed(TEMP_DATA));  -- Convert to integer

--        -- Divide by 128 to get the temperature (fixed-point equivalent of /128)
--        temp_int <= temp_value / 128;                 -- Integer part (°C)
--        temp_frac <= (temp_value * 10 / 128) mod 10;  -- Fractional part (tenths)
--    end process;

--    -- Convert integer and fractional parts to BCD
--    temp_bcd <= std_logic_vector(to_unsigned(temp_int / 10, 4)) &  -- Tens digit
--                std_logic_vector(to_unsigned(temp_int mod 10, 4)) & -- Units digit
--                std_logic_vector(to_unsigned(temp_frac, 4)) &       -- Tenths digit
--                "0000";  -- Blank digit

--    -- 4-digit Display Multiplexing Process
--    process (clk_divsig, CPU_RESETN)
--    begin
--        if CPU_RESETN = '0' then
--            counter_reg <= (others => '0');
--        elsif rising_edge(clk_divsig) then
--            counter_reg <= counter_reg + 1;
--        end if;
--    end process;

--    -- Select active digit and control decimal point
--    Decoder : process (counter_reg)
--    begin
--        case counter_reg is
--            when "00" =>
--                AN <= "11111110";  -- Display Tens digit
--                DP <= '1';
--                bcd_values <= temp_bcd(15 downto 12);
--            when "01" =>
--                AN <= "11111101";  -- Display Units digit
--                DP <= '0';         -- Decimal point active
--                bcd_values <= temp_bcd(11 downto 8);
--            when "10" =>
--                AN <= "11111011";  -- Display Tenths digit
--                DP <= '1';
--                bcd_values <= temp_bcd(7 downto 4);
--            when "11" =>
--                AN <= "11110111";  -- Blank digit
--                DP <= '1';
--                bcd_values <= "0000";
--            when others =>
--                AN <= "11111111";
--                DP <= '1';
--        end case;
--    end process;

--    -- 7-Segment Decoder Process (based on BCD input)
--    with bcd_values select
--        (CA, CB, CC, CD, CE, CF, CG) <=
--            std_logic_vector'("0000001") when "0000",  -- 0
--            std_logic_vector'("1001111") when "0001",  -- 1
--            std_logic_vector'("0010010") when "0010",  -- 2
--            std_logic_vector'("0000110") when "0011",  -- 3
--            std_logic_vector'("1001100") when "0100",  -- 4
--            std_logic_vector'("0100100") when "0101",  -- 5
--            std_logic_vector'("0100000") when "0110",  -- 6
--            std_logic_vector'("0001111") when "0111",  -- 7
--            std_logic_vector'("0000000") when "1000",  -- 8
--            std_logic_vector'("0000100") when "1001",  -- 9
--            std_logic_vector'("1111111") when others;  -- Blank

--end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Temp_Display is
    Port (
        CPU_RESETN : in  STD_LOGIC := '0';
        CLK100MHZ  : in  STD_LOGIC := '0';
        TEMP_DATA  : in  STD_LOGIC_VECTOR(15 downto 0);  -- 16-bit temperature data input
        CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;
        AN        : out STD_LOGIC_VECTOR (7 downto 0);
        DP        : out STD_LOGIC
    );
end Temp_Display;

architecture Behavioral of Temp_Display is
    signal clk_divsig : STD_LOGIC;
    signal counter_reg : unsigned(1 downto 0) := "00";
    signal bcd_values : STD_LOGIC_VECTOR(3 downto 0);
    signal temp_int   : integer range 0 to 99;
    signal temp_frac  : integer range 0 to 9;
    signal temp_bcd   : STD_LOGIC_VECTOR(15 downto 0);

    -- Clock Divider Component Declaration
    component clock_divider is
        generic (DIVISOR : positive := 100000);  -- Adjust for display refresh
        Port (mclk : in std_logic; sclk : out std_logic);
    end component;

begin

    CLK_DIV: clock_divider
        generic map (DIVISOR => 100000)  -- Adjust as needed
        port map (mclk => CLK100MHZ, sclk => clk_divsig);

    -- Convert TEMP_DATA to Integer and Fractional parts using fixed-point math
    process(TEMP_DATA)
        variable temp_value : integer;
        variable temp_raw : integer;
    begin
        -- Extract the lower 11 bits of TEMP_DATA (temperature data part)
        temp_value := to_integer(unsigned(TEMP_DATA(10 downto 0)));  -- Extract lower 11 bits
        
        -- Calculate integer and fractional parts
        temp_raw := temp_value / 16;            -- Integer part (°C)
        temp_int <= temp_raw;                   -- Integer value (degrees)
        
        -- Fractional calculation (tenths digit)
        temp_frac <= ((temp_value - (temp_raw * 16)) * 10) / 16;  -- Tenths digit calculation
    end process;

    -- Convert integer and fractional parts to BCD
    temp_bcd <= std_logic_vector(to_unsigned(temp_int / 10, 4)) &  -- Tens digit
                std_logic_vector(to_unsigned(temp_int mod 10, 4)) & -- Units digit
                std_logic_vector(to_unsigned(temp_frac, 4)) &       -- Tenths digit
                "0000";                                             -- Blank digit

    -- 4-digit Display Multiplexing Process
    process (clk_divsig, CPU_RESETN)
    begin
        if CPU_RESETN = '0' then
            counter_reg <= (others => '0');
        elsif rising_edge(clk_divsig) then
            counter_reg <= counter_reg + 1;
        end if;
    end process;

    -- Select active digit and control decimal point
    Decoder : process (counter_reg)
    begin
        case counter_reg is
            when "00" =>
                AN <= "11111110";  -- Display Tens digit
                DP <= '1';
                bcd_values <= temp_bcd(15 downto 12);
            when "01" =>
                AN <= "11111101";  -- Display Units digit
                DP <= '0';         -- Decimal point active
                bcd_values <= temp_bcd(11 downto 8);
            when "10" =>
                AN <= "11111011";  -- Display Tenths digit
                DP <= '1';
                bcd_values <= temp_bcd(7 downto 4);
            when "11" =>
                AN <= "11110111";  -- Blank digit
                DP <= '1';
                bcd_values <= "0000";
            when others =>
                AN <= "11111111";
                DP <= '1';
        end case;
    end process;

    -- 7-Segment Decoder Process (based on BCD input)
    with bcd_values select
        (CA, CB, CC, CD, CE, CF, CG) <=
            std_logic_vector'("0000001") when "0000",  -- 0
            std_logic_vector'("1001111") when "0001",  -- 1
            std_logic_vector'("0010010") when "0010",  -- 2
            std_logic_vector'("0000110") when "0011",  -- 3
            std_logic_vector'("1001100") when "0100",  -- 4
            std_logic_vector'("0100100") when "0101",  -- 5
            std_logic_vector'("0100000") when "0110",  -- 6
            std_logic_vector'("0001111") when "0111",  -- 7
            std_logic_vector'("0000000") when "1000",  -- 8
            std_logic_vector'("0000100") when "1001",  -- 9
            std_logic_vector'("1111111") when others;  -- Blank

end Behavioral;
