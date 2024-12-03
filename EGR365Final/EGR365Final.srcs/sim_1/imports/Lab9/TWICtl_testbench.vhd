library ieee;
use ieee.std_logic_1164.all;

entity TWI_testbench is
end TWI_testbench;

architecture behavior of TWI_testbench is
	
	procedure waitclocks(signal clock : std_logic; N : INTEGER) is
		begin
			for i in 1 to N loop
				wait until clock'event and clock='0';
			end loop;
	end waitclocks;

  signal CLK_sig    : std_logic := '0';					
  signal RESET_sig  : std_logic := '0';
  signal SCL_sig    : std_logic;
  signal MSG_I_sig  : std_logic;
  signal STB_I_sig  : std_logic;
  signal DONE_O_sig : std_logic;
  signal ERR_O_sig  : std_logic;
  signal SDA_sig    : std_logic;
  signal A_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
  signal D_I_sig    : STD_LOGIC_VECTOR (7 downto 0);
  signal D_O_sig    : STD_LOGIC_VECTOR (7 downto 0);
  signal START_sig  : std_logic;
  signal DATA_OUT_sig : std_logic_vector(15 downto 0);
  signal SRST_sig    : std_logic;
  
  signal LED_sig    : STD_LOGIC_VECTOR(15 downto 0);

  constant addrAD2	 : STD_LOGIC_VECTOR(6 downto 0) := b"1001011";	
  constant read_Bit  : STD_LOGIC := '1';
  constant write_Bit : STD_LOGIC := '0';

  
  constant Tperiod : time := 10 ns;						
  
  
  begin
	
    process(CLK_sig)
      begin
        CLK_sig <= not CLK_sig after Tperiod/2;
    end process;
    
    RESET_sig <= '0', '1' after 10ns, '0' after 20ns;
    START_sig <= '0', '1' after 1ms, '0' after 2ms, '1' after 3ms, '0' after 4ms;
	


	-- This process the TMP slave device on the TWI bus. It drives the SDA signal to '0' at the appropriate
	-- times to furnish an "ACK" signal to the TWI master device and '0' and 'H' at appropriate times to 
	-- simulate the data being returned from the TMP over the TWI bus.
	
slave_stimulus : process
      begin
SDA_sig <= 'H'; -- not driven
SCL_sig <= 'H'; -- not driven

-- address write
waitclocks(SCL_sig, 9); -- wait for transmission time
SDA_sig <= '0';
waitclocks(SCL_sig, 1); -- wait for ack time
SDA_sig <= 'H';

SDA_sig <= 'H'; -- MSB (upper byte)
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0'; -- LSB
waitclocks(SCL_sig, 1);
SDA_sig <= 'H'; -- Release bus


waitclocks(SCL_sig, 1);
SDA_sig <= '0'; -- MSB (lower byte)
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0'; -- LSB (lower byte)
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';

-- address write
waitclocks(SCL_sig, 10); -- wait for transmission time
SDA_sig <= '0';
waitclocks(SCL_sig, 1); -- wait for ack time
SDA_sig <= 'H';

SDA_sig <= 'H'; -- MSB (upper byte)
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0'; -- LSB
waitclocks(SCL_sig, 1);
SDA_sig <= 'H'; -- Release bus


waitclocks(SCL_sig, 1);
SDA_sig <= '0'; -- MSB (lower byte)
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= '0';
waitclocks(SCL_sig, 1);
SDA_sig <= 'H'; -- LSB (lower byte)
waitclocks(SCL_sig, 1);
SDA_sig <= 'H';

wait; -- stop the process to avoid an infinite loop

end process slave_stimulus;

 
    -- this is the component instantiation for the
    -- DUT - the device we are testing

    DUT : entity work.State_Machine(Behavioral)
	    port map( MSG_I  => MSG_I_sig,                         
                  STB_I  => STB_I_sig,                          
                  A_I    => A_I_sig,     
                  D_I    => D_I_sig,     
                  D_O    => D_O_sig,     
                  DONE_O => DONE_O_sig,                        
                  ERR_O  => ERR_O_sig,                        
                  CLK    => CLK_sig,                         
                  SRST   => SRST_sig,                          
                  START => START_sig,
                  RESET => RESET_sig,
                  DATA_OUT => DATA_OUT_sig               
	     );
    DUT_1 : entity work.TWICtl(Behavioral)
		generic map (CLOCKFREQ => 100) -- System clock in MHz
		port map(MSG_I  => MSG_I_sig,  -- new message
                 STB_I  => STB_I_sig,  -- strobe
                 A_I    => A_I_sig,    -- address input bus
                 D_I    => D_I_sig,    -- data input bus
                 D_O    => D_O_sig,    -- data output bus
                 DONE_O => DONE_O_sig, -- done status signal
                 ERR_O  => ERR_O_sig,  -- error status
                 CLK    => clk_sig,    -- Input Clock
                 SRST   => SRST_sig,  -- Reset

                 SDA    => SDA_sig,    --TWI SDA
                 SCL    => SCL_sig);   --TWI SCL

											
 
end behavior;