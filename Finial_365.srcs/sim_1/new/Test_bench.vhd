library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity display_driver_testbench is
end display_driver_testbench;

architecture behavior of display_driver_testbench is

    procedure waitclocks(signal clock : std_logic; N : INTEGER) is
    begin
        for i in 1 to N loop
            wait until clock'event and clock = '0'; 
        end loop;
    end procedure;

    signal clk         : std_logic := '0';          
    signal reset       : std_logic := '0';          
    signal byte_ready  : std_logic := '0';           
    signal twi_data    : std_logic_vector(7 downto 0) := (others => '0');  
    signal scl_enable  : std_logic;                
    signal display_out : std_logic_vector(15 downto 0); 

    signal addrAD2 : std_logic_vector(7 downto 0):= (others => '0');   
    constant read_Bit : std_logic := '1';

    constant Tperiod : time := 10 ns;

begin
    process
    begin
        clk <= not clk after Tperiod / 2;
        wait for Tperiod / 2;
    end process;

    master_stimulus : process
    begin
        byte_ready <= '0';       
        reset <= '0';
        twi_data <= "00000000";  
        waitclocks(clk, 10);     
        reset <= '1';           
        waitclocks(clk, 2);
        reset <= '0'; 

        -- Read MSB
        addrAD2 <= "1001011" & '0';  
        byte_ready <= '1';           
        twi_data <= "10101010";     
        waitclocks(clk, 5);          
        byte_ready <= '0';           

        -- Read LSB
        addrAD2 <= "1001011" & '1';  
        byte_ready <= '1';           
        twi_data <= "11001100";      
        waitclocks(clk, 5);         
        byte_ready <= '0';           

       
        waitclocks(clk, 10);         

        wait;  
    end process master_stimulus;

   
    DUT : entity work.State_Machine
        port map (
            clk         => clk,            
            reset       => reset,         
            byte_ready  => byte_ready,    
            twi_data    => twi_data,      
            scl_enable  => scl_enable,     
            display_out => display_out     
        );

    -- Clock Divider Component
    clk_div_inst: entity work.clock_divider
        generic map (DIVISOR => 50000000)  
        port map (
            mclk => clk,      
            sclk => scl_enable 
        );

end behavior;
