--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

--entity TopLevel is
--    Port (
--        CLK      : in  STD_LOGIC;                    
--        SRST     : in  STD_LOGIC;                     
--        SDA      : inout STD_LOGIC;                 
--        SCL      : inout STD_LOGIC                   
--    );
--end TopLevel;

--architecture Behavioral of TopLevel is

--    signal buf_srst     : STD_LOGIC;                   
--    signal buf_stb_i    : STD_LOGIC;                    
--    signal buf_msg_i    : STD_LOGIC;  
--    signal buf_a_i      : STD_LOGIC_VECTOR(7 downto 0);  
--    signal buf_d_i      : STD_LOGIC_VECTOR(7 downto 0); 
--    signal buf_d_o      : STD_LOGIC_VECTOR(7 downto 0); 
--    signal buf_done_o   : STD_LOGIC;                     
--    signal buf_err_o    : STD_LOGIC;                    

--    component clock_divider is
--        generic (DIVISOR : positive := 50000000);  
--        port ( 
--            mclk : in  STD_LOGIC; 
--            sclk : out STD_LOGIC     
--        );
--    end component;

  
--    component State_Machine is
--        Port ( 
--            clk         : in  STD_LOGIC;                     
--            reset       : in  STD_LOGIC;                   
--            byte_ready  : in  STD_LOGIC;                     
--            twi_data    : in  STD_LOGIC_VECTOR(7 downto 0);  
--            srst        : out STD_LOGIC;                    
--            stb_i       : out STD_LOGIC;                     
--            msg_i       : out STD_LOGIC; 
--            a_i         : out STD_LOGIC_VECTOR(7 downto 0); 
--            d_i         : out STD_LOGIC_VECTOR(7 downto 0)   
--        );
--    end component;

--    component TWICtl is
--        generic (CLOCKFREQ : natural := 50);
--        port ( 
--            MSG_I  : in  STD_LOGIC;
--            STB_I  : in  STD_LOGIC;
--            A_I    : in  STD_LOGIC_VECTOR(7 downto 0);
--            D_I    : in  STD_LOGIC_VECTOR(7 downto 0);
--            D_O    : out STD_LOGIC_VECTOR(7 downto 0);
--            DONE_O : out STD_LOGIC;
--            ERR_O  : out STD_LOGIC;
--            CLK    : in  STD_LOGIC;
--            SRST   : in  STD_LOGIC;
--            SDA    : inout STD_LOGIC;
--            SCL    : inout STD_LOGIC
--        );
--    end component;
--signal clk_div_out   : STD_LOGIC; 
--signal sm_reset      : STD_LOGIC;  
--signal sm_strobe     : STD_LOGIC;  
--signal sm_message    : STD_LOGIC;  
--signal sm_address    : STD_LOGIC_VECTOR(7 downto 0);  
--signal sm_data       : STD_LOGIC_VECTOR(7 downto 0);  

--begin

--    -- Clock Divider Instance
--    U_Clock_Divider : clock_divider
--        generic map (DIVISOR => 50000000)  
--        port map (
--            mclk => CLK,          
--            sclk => clk_div_out   
--        );

--    U_State_Machine : State_Machine
--        port map (
--            clk         => clk_div_out,        
--            reset       => SRST,              
--            byte_ready  => buf_done_o,        
--            twi_data    => buf_d_o,            
--            srst        => sm_reset,         
--            stb_i       => sm_strobe,        
--            msg_i       => sm_message,         
--            a_i         => sm_address,       
--            d_i         => sm_data          
--        );

--    -- TWICtl Instance (I2C Controller)
--    U_TWICtl : TWICtl
--        generic map (CLOCKFREQ => 50)
--        port map (
--            MSG_I  => sm_message,          
--            STB_I  => sm_strobe,          
--            A_I    => sm_address,          
--            D_I    => sm_data,             
--            D_O    => buf_d_o,            
--            DONE_O => buf_done_o,       
--            ERR_O  => buf_err_o,           
--            CLK    => clk_div_out,         
--            SRST   => sm_reset,           
--            SDA    => SDA,                
--            SCL    => SCL               
--        );

--end Behavioral;

