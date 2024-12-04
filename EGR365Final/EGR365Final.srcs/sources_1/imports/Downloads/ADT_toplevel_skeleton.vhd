library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity ADT_toplevel is
    Port (
        CPU_RESETN  : in    STD_LOGIC;
        SYS_CLK     : in    STD_LOGIC;
        AD2_SCL     : inout STD_LOGIC;
        AD2_SDA     : inout STD_LOGIC;
        LED         : out   STD_LOGIC_VECTOR(15 downto 0);
        SCL_ALT_IN  : inout STD_LOGIC;
        SDA_ALT_IN  : inout STD_LOGIC;
        CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;  -- 7-segment segments
        AN          : out STD_LOGIC_VECTOR(7 downto 0);  -- 7-segment anodes
        DP          : out STD_LOGIC   -- Decimal point
    );
end ADT_toplevel;

architecture Structural of ADT_toplevel is
   
    signal RESET_sig     : std_logic := '0';
    signal START_sig     : std_logic := '0';
    signal DONE_sig      : std_logic;
    signal ERR_sig       : std_logic;
    signal DATA_OUT_sig  : std_logic_vector(15 downto 0);

    -- Signals between the State Machine and TWI Controller
    signal MSG_I_sig, STB_I_sig, SRST_sig : std_logic;
    signal A_I_sig, D_I_sig, D_O_sig      : std_logic_vector(7 downto 0);

    -- Component Declarations
    component clock_divider is
        generic (DIVISOR : positive := 50000000);
        Port (
            mclk  : in  std_logic;
            sclk  : out std_logic
        );
    end component;

    component State_Machine is
        Port (
            MSG_I    : out STD_LOGIC;                          
            STB_I    : out STD_LOGIC;                           
            A_I      : out STD_LOGIC_VECTOR(7 downto 0);     
            D_I      : out STD_LOGIC_VECTOR(7 downto 0);      
            D_O      : in  STD_LOGIC_VECTOR(7 downto 0);     
            DONE_O   : in  STD_LOGIC;                         
            ERR_O    : in  STD_LOGIC;                         
            CLK      : in  std_logic;                           
            SRST     : out std_logic;                           
            START    : in  std_logic;
            RESET    : in  std_logic;
            DATA_OUT : out STD_LOGIC_VECTOR(15 downto 0)                 
        );
    end component;

    component TWICtl is
        generic (CLOCKFREQ : natural := 50);
        Port (
            MSG_I  : in  STD_LOGIC;
            STB_I  : in  STD_LOGIC;
            A_I    : in  STD_LOGIC_VECTOR (7 downto 0);
            D_I    : in  STD_LOGIC_VECTOR (7 downto 0);
            D_O    : out STD_LOGIC_VECTOR (7 downto 0);
            DONE_O : out STD_LOGIC;
            ERR_O  : out STD_LOGIC;
            CLK    : in  std_logic;
            SRST   : in  std_logic;
            SDA    : inout std_logic;
            SCL    : inout std_logic
        );
    end component;

    -- 7-Segment Display Component
    component Temp_Display is
        Port (
            CPU_RESETN : in  STD_LOGIC;
            CLK100MHZ  : in  STD_LOGIC;
            TEMP_DATA  : in  STD_LOGIC_VECTOR(15 downto 0);
            CA, CB, CC, CD, CE, CF, CG : out STD_LOGIC;
            AN        : out STD_LOGIC_VECTOR(7 downto 0);
            DP        : out STD_LOGIC
        );
    end component;

begin

    RESET_sig <= not CPU_RESETN;

    -- Pullup resistors
    SDA_ALT_IN <= 'Z';
    SCL_ALT_IN <= 'Z';
    PULLUP_SDA: PULLUP PORT MAP (O => AD2_SDA);
    PULLUP_SCL: PULLUP PORT MAP (O => AD2_SCL);

    -- Clock divider for the 2 Hz signal
    ClockDiv_inst: clock_divider
        generic map (DIVISOR => 50000000)
        port map (
            mclk  => SYS_CLK,
            sclk  => START_sig
        );

    -- State machine
    StateMachine: State_Machine
        port map (
            MSG_I    => MSG_I_sig,
            STB_I    => STB_I_sig,
            A_I      => A_I_sig,
            D_I      => D_I_sig,
            D_O      => D_O_sig,
            DONE_O   => DONE_sig,
            ERR_O    => ERR_sig,
            CLK      => SYS_CLK,
            SRST     => SRST_sig,
            START    => START_sig,
            RESET    => RESET_sig,
            DATA_OUT => DATA_OUT_sig
        );

    -- TWI controller
    TWICtl_i: TWICtl
        generic map (CLOCKFREQ => 100)
        port map (
            MSG_I  => MSG_I_sig,
            STB_I  => STB_I_sig,
            A_I    => A_I_sig,
            D_I    => D_I_sig,
            D_O    => D_O_sig,
            DONE_O => DONE_sig,
            ERR_O  => ERR_sig,
            CLK    => SYS_CLK,
            SRST   => SRST_sig,
            SDA    => AD2_SDA,
            SCL    => AD2_SCL
        );

    -- 7-Segment Display Controller
    Temp_Display_inst: Temp_Display
        port map (
            CPU_RESETN => CPU_RESETN,
            CLK100MHZ  => SYS_CLK,
            TEMP_DATA  => DATA_OUT_sig,  -- Connect temperature data from state machine
            CA => CA,
            CB => CB,
            CC => CC,
            CD => CD,
            CE => CE,
            CF => CF,
            CG => CG,
            AN => AN,
            DP => DP
        );

    -- Map the output data from state machine to LEDs
    LED <= DATA_OUT_sig;

end Structural;

