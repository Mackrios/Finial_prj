library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity State_Machine is
    port ( 
        MSG_I  : out STD_LOGIC;                          
        STB_I  : out STD_LOGIC;                           
        A_I    : out  STD_LOGIC_VECTOR (7 downto 0);     
        D_I    : out  STD_LOGIC_VECTOR (7 downto 0);      
        D_O    : in  STD_LOGIC_VECTOR (7 downto 0);     
        DONE_O : in  STD_LOGIC;                         
        ERR_O  : in  STD_LOGIC;                         
        CLK    : in std_logic;                           
        SRST   : out std_logic;                           
        START  : in std_logic;
        RESET  : in std_logic;
        DATA_OUT: out STD_LOGIC_VECTOR(15 downto 0)                 
    );
end State_Machine;

architecture Behavioral of State_Machine is

    type state_type is (IDLE, STRT, READ_MSB, Read_LSB, DONE);
    signal present_state, next_state : state_type;
    signal count_reset : std_logic;
    signal count : integer RANGE 0 to 1200;
    signal data_register : std_logic_vector(15 downto 0);
    signal addr : std_logic_vector(6 downto 0) := b"1001011";
    signal read_write_bit_0 : std_logic := '0';
    signal read_write_bit_1 : std_logic := '1';

begin

    clocked : PROCESS(CLK,RESET)
       BEGIN
         IF(RESET='1') THEN 
           present_state <= IDLE;
        ELSIF(rising_edge(clk)) THEN
          present_state <= next_state;
        END IF;  
     END PROCESS clocked;
    
    counter : PROCESS(clk)
       BEGIN
        IF(rising_edge(CLK)) THEN
          IF(count_reset='1') THEN 
            count <= 0;
          ELSE
            count <= count + 1;
          END IF;
        END IF;  
     END PROCESS counter;

    nextstate : PROCESS(present_state, count, START, DONE_O, ERR_O)
        BEGIN
            CASE present_state is
                WHEN IDLE =>
                     count_reset <= '0';
                     if( count = 1200 ) then
                        count_reset <='1';
                        next_state <= STRT;
                     else
                       next_state <= present_state;
                     end if;

                WHEN STRT =>
                    count_reset <= '1';
                    if( START = '1') then
                        next_state <= READ_MSB;
                    else
                        next_state <= present_state;
                    end if;

                WHEN READ_MSB =>
                    count_reset <= '0';
                    if ( count = 2) then 
                        count_reset <= '1';
                    else
                        count_reset <= '0';
                    end if;
                    if (DONE_O = '1') then
                        next_state <= Read_LSB;
                    elsif (ERR_O = '1') then
                       next_state <= STRT;
                    else
                        next_state <= present_state;
                    end if;
                    
                WHEN Read_LSB =>
                    count_reset <= '0';
                    if (count = 510) then
                        count_reset <= '1';
                    else 
                        count_reset <= '0';
                    end if;
                    if (DONE_O = '1') then
                        next_state <= DONE;
                    elsif (ERR_O = '1') then
                        next_state <= STRT;
                    else 
                        next_state <= present_state;
                    end if;

                WHEN DONE =>
                    count_reset <= '1';
                    if (START = '0') then
                        next_state <= STRT;
                    else
                        next_state <= present_state;
                    end if;
           END CASE;
    END PROCESS nextstate;

    output : PROCESS(present_state, START, count) 
           BEGIN
           CASE present_state is
              WHEN IDLE =>
                    A_I <= addr & read_write_bit_0;
                    D_I <= (others=> '0');
                    if (count < 1) then
                        SRST <= '1';
                    else
                        SRST <= '0';
                    end if;

              WHEN STRT =>
                    if( START = '1') then
                        STB_I <= '1';
                        MSG_I <= '1';
                    elsif( START = '0') then
                        STB_I <= '0';
                        MSG_I <= '0';
                    end if;

              WHEN READ_MSB =>
                   A_I <= addr & read_write_bit_1;
                   STB_I <= '1';
                   if (count < 2) then
                    MSG_I <= '1';
                   else
                    MSG_I <= '0';
                   end if;

              WHEN Read_LSB =>
                if (count = 1) then
                    MSG_I <= '1';
                else 
                    MSG_I <= '0';
                end if;
                if (count > 509) then
                    STB_I <= '0';
                else
                    STB_I <= '1';
                end if;

              WHEN DONE =>  
                STB_I <= '0';
                MSG_I <= '1';
          END CASE;
    END PROCESS output;

    data_register_update : PROCESS(CLK, RESET)
        BEGIN
            IF RESET = '1' THEN
                data_register <= (others => '0');
            ELSIF rising_edge(CLK) THEN
                IF present_state = READ_MSB AND DONE_O = '1' THEN
                    data_register(15 downto 8) <= D_O;
                END IF;

        -- Update lower 8 bits in Read_LSB state
                IF present_state = Read_LSB AND DONE_O = '1' THEN
                    data_register(7 downto 0) <= D_O;
                END IF;
            END IF;
        END PROCESS data_register_update;

    DATA_OUT <= data_register;
    
end Behavioral;
