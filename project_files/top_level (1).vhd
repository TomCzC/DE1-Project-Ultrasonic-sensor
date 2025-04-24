library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
        CLK100MHZ : in STD_LOGIC;
        SW       : in STD_LOGIC_VECTOR (8 downto 0);
        JC0      : in STD_LOGIC;   -- Echo sensor 1
        JA0      : out STD_LOGIC;   -- Trigger               
        JB0      : in STD_LOGIC;   -- Echo sensor 2
        JD0      : out STD_LOGIC;   -- Trigger     
        BTNC     : in STD_LOGIC;   -- Reset
        BTND     : in STD_LOGIC;   -- Show data button
        BTNU     : in STD_LOGIC;   -- Show threshold button
        LED      : out STD_LOGIC_VECTOR (15 downto 0);  -- 16 LEDs
        CA       : out STD_LOGIC;  -- Seven segment A
        CB       : out STD_LOGIC;  -- Seven segment B
        CC       : out STD_LOGIC;  -- Seven segment C
        CD       : out STD_LOGIC;  -- Seven segment D
        CE       : out STD_LOGIC;  -- Seven segment E
        CF       : out STD_LOGIC;  -- Seven segment F
        CG       : out STD_LOGIC;  -- Seven segment G
        DP       : out STD_LOGIC;  -- Decimal point
        AN       : out STD_LOGIC_VECTOR (7 downto 0)  -- Anodes for digits
    );
end top_level;

architecture Behavioral of top_level is
    -- Component declarations
    component echo_receiver is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            echo_pulse  : in  STD_LOGIC;
            distance    : out STD_LOGIC_VECTOR(8 downto 0);
            ready       : out STD_LOGIC;
            timeout     : out STD_LOGIC
        );
    end component;
    
    component controller is
        Port (
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            distance_in  : in  STD_LOGIC_VECTOR(8 downto 0);
            data_ready   : in  STD_LOGIC;
            timeout      : in  STD_LOGIC;
            trigger_out  : out STD_LOGIC;
            distance_out : out STD_LOGIC_VECTOR(8 downto 0);
            valid        : out STD_LOGIC;
            thd          : out STD_LOGIC
        );
    end component;
    
    component trig_pulse is
        Port ( 
            clk    : in STD_LOGIC;
            start  : in STD_LOGIC;
            trig1  : out STD_LOGIC;
            trig2  : out STD_LOGIC
        );
    end component;
    
    component display_control is
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            distance1     : in  std_logic_vector(8 downto 0);
            distance2     : in  std_logic_vector(8 downto 0);
            threshold     : in  std_logic_vector(8 downto 0);
            show_data_btn : in  std_logic;
            show_thresh_btn: in std_logic;
            seg           : out std_logic_vector(6 downto 0);
            an            : out std_logic_vector(7 downto 0);
            leds          : out std_logic_vector(15 downto 0)
        );
    end component;
    
    component clock_en is
        generic (
            n_periods : integer := 3
        );
        port (
            clk   : in    std_logic;
            rst   : in    std_logic;
            pulse : out   std_logic
        );
    end component;
    
    -- Signals
    signal reset : std_logic;
    
    -- Sensor 1 signals
    signal distance1_raw : std_logic_vector(8 downto 0);
    signal distance1_processed : std_logic_vector(8 downto 0);
    signal ready1, timeout1, valid1, thd1 : std_logic;
    signal trigger1 : std_logic;
    
    -- Sensor 2 signals
    signal distance2_raw : std_logic_vector(8 downto 0);
    signal distance2_processed : std_logic_vector(8 downto 0);
    signal ready2, timeout2, valid2, thd2 : std_logic;
    signal trigger2 : std_logic;
    
    -- Display signals
    signal seg_data : std_logic_vector(6 downto 0);
    signal anodes : std_logic_vector(7 downto 0);
    signal leds_internal : std_logic_vector(15 downto 0);
    
    -- Trigger control
    signal trigger_start : std_logic;
    
    -- Clock enable for display refresh
    signal display_refresh : std_logic;
    
begin
    -- Reset signal assignment
    reset <= BTNC;
    
    -- Instantiate clock enable for display refresh (1kHz refresh rate)
    display_refresh_gen: clock_en
        generic map (
            n_periods => 100000  -- 100MHz / 100000 = 1kHz
        )
        port map (
            clk => CLK100MHZ,
            rst => reset,
            pulse => display_refresh
        );
    
    -- Instantiate echo receivers
    echo_receiver_inst1: echo_receiver
        port map (
            clk => CLK100MHZ,
            reset => reset,
            echo_pulse => JC0,
            distance => distance1_raw,
            ready => ready1,
            timeout => timeout1
        );
    
    echo_receiver_inst2: echo_receiver
        port map (
            clk => CLK100MHZ,
            reset => reset,
            echo_pulse => JB0,
            distance => distance2_raw,
            ready => ready2,
            timeout => timeout2
        );
    
    -- Instantiate controllers
    controller_inst1: controller
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance_in => distance1_raw,
            data_ready => ready1,
            timeout => timeout1,
            trigger_out => trigger_start,
            distance_out => distance1_processed,
            valid => valid1,
            thd => thd1
        );
    
    controller_inst2: controller
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance_in => distance2_raw,
            data_ready => ready2,
            timeout => timeout2,
            trigger_out => open,  -- Only need one trigger start signal
            distance_out => distance2_processed,
            valid => valid2,
            thd => thd2
        );
    
    -- Instantiate trigger pulse generator
    trigger_gen: trig_pulse
        port map (
            clk => CLK100MHZ,
            start => trigger_start,
            trig1 => trigger1,
            trig2 => trigger2
        );
    
    -- Connect triggers to outputs
    
    -- Instantiate display controller
    display: display_control
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance1 => distance1_processed,
            distance2 => distance2_processed,
            threshold => SW(8 downto 0),
            show_data_btn => BTND,
            show_thresh_btn => BTNU,
            seg => seg_data,
            an => anodes,
            leds => leds_internal
        );
    
    -- Connect seven-segment display outputs
    CA <= seg_data(6);
    CB <= seg_data(5);
    CC <= seg_data(4);
    CD <= seg_data(3);
    CE <= seg_data(2);
    CF <= seg_data(1);
    CG <= seg_data(0);
    DP <= '1';  -- Decimal point always off
    AN <= anodes;
    
    -- LED assignments
    LED <= leds_internal;
    
    -- Unused outputs
        JD0      <= '0';
        JD1      <= '0';
        JD2      <= '0';
        JD3      <= '0';
        
        JA0      <= '0';
        JA1      <= '0';
        JA2      <= '0';
        JA3      <= '0';
    
end Behavioral;