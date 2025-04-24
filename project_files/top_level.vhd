library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
        CLK100MHZ : in STD_LOGIC;
        SW       : in STD_LOGIC_VECTOR (8 downto 0);
        JC0      : in STD_LOGIC;   -- Echo sensor 1
        JA0      : out STD_LOGIC;   -- Trigger sensor 1               
        JB0      : in STD_LOGIC;   -- Echo sensor 2
        JD0      : out STD_LOGIC;   -- Trigger sensor 2     
        BTNC     : in STD_LOGIC;   -- Reset
        BTND     : in STD_LOGIC;   -- Show data button
        BTNU     : in STD_LOGIC;   -- Show threshold button
        LED      : out STD_LOGIC_VECTOR (15 downto 0);
        CA       : out STD_LOGIC;
        CB       : out STD_LOGIC;
        CC       : out STD_LOGIC;
        CD       : out STD_LOGIC;
        CE       : out STD_LOGIC;
        CF       : out STD_LOGIC;
        CG       : out STD_LOGIC;
        DP       : out STD_LOGIC;
        AN       : out STD_LOGIC_VECTOR (7 downto 0)
    );
end top_level;

architecture Behavioral of top_level is
    component echo_receiver is
        generic (
            DEVICE_NUMBER : INTEGER := 1;
            MIN_DISTANCE : INTEGER := 50 
        );
        port ( 
            trig        : in STD_LOGIC;
            echo_in     : in STD_LOGIC;
            clk        : in STD_LOGIC;
            rst        : in STD_LOGIC;
            dev_num    : out STD_LOGIC_VECTOR (2 downto 0);
            distance   : out STD_LOGIC_VECTOR (8 downto 0);
            status     : out STD_LOGIC 
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
            trig   : out STD_LOGIC
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
    
    signal reset : std_logic;
    
    -- Sensor 1 signals
    signal distance1_raw : std_logic_vector(8 downto 0);
    signal distance1_processed : std_logic_vector(8 downto 0);
    signal ready1, timeout1, valid1, thd1 : std_logic;
    signal trigger1_start, trigger1_pulse : std_logic;
    signal dev_num1 : std_logic_vector(2 downto 0);
    signal status1 : std_logic;
    
    -- Sensor 2 signals
    signal distance2_raw : std_logic_vector(8 downto 0);
    signal distance2_processed : std_logic_vector(8 downto 0);
    signal ready2, timeout2, valid2, thd2 : std_logic;
    signal trigger2_start, trigger2_pulse : std_logic;
    signal dev_num2 : std_logic_vector(2 downto 0);
    signal status2 : std_logic;
    
    -- Display signals
    signal seg_data : std_logic_vector(6 downto 0);
    signal anodes : std_logic_vector(7 downto 0);
    signal leds_internal : std_logic_vector(15 downto 0);
    
    -- Clock enable for display refresh
    signal display_refresh : std_logic;
    
begin
    reset <= BTNC;
    
    -- Display refresh clock enable
    display_refresh_gen: clock_en
        generic map (n_periods => 100000) -- 1kHz refresh
        port map (
            clk => CLK100MHZ,
            rst => reset,
            pulse => display_refresh
        );
    
    -- Sensor 1 components
    echo_receiver_inst1: echo_receiver
        generic map (
            DEVICE_NUMBER => 1,
            MIN_DISTANCE => 50
        )
        port map (
            trig => trigger1_pulse,
            echo_in => JC0,
            clk => CLK100MHZ,
            rst => reset,
            dev_num => dev_num1,
            distance => distance1_raw,
            status => status1
        );
    
    controller_inst1: controller
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance_in => distance1_raw,
            data_ready => status1,
            timeout => '0',  -- Not used in current echo_receiver
            trigger_out => trigger1_start,
            distance_out => distance1_processed,
            valid => valid1,
            thd => thd1
        );
    
    trig_pulse_inst1: trig_pulse
        port map (
            clk => CLK100MHZ,
            start => trigger1_start,
            trig => trigger1_pulse
        );
    
    -- Sensor 2 components
    echo_receiver_inst2: echo_receiver
        generic map (
            DEVICE_NUMBER => 2,
            MIN_DISTANCE => 50
        )
        port map (
            trig => trigger2_pulse,
            echo_in => JB0,
            clk => CLK100MHZ,
            rst => reset,
            dev_num => dev_num2,
            distance => distance2_raw,
            status => status2
        );
    
    controller_inst2: controller
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance_in => distance2_raw,
            data_ready => status2,
            timeout => '0',  -- Not used in current echo_receiver
            trigger_out => trigger2_start,
            distance_out => distance2_processed,
            valid => valid2,
            thd => thd2
        );
    
    trig_pulse_inst2: trig_pulse
        port map (
            clk => CLK100MHZ,
            start => trigger2_start,
            trig => trigger2_pulse
        );
    
    -- Connect triggers to outputs
    JA0 <= trigger1_pulse;
    JD0 <= trigger2_pulse;
    
    -- Display controller
    display: display_control
        port map (
            clk => CLK100MHZ,
            reset => reset,
            distance1 => distance1_processed,
            distance2 => distance2_processed,
            threshold => SW,
            show_data_btn => BTND,
            show_thresh_btn => BTNU,
            seg => seg_data,
            an => anodes,
            leds => leds_internal
        );
    
    -- Seven-segment display connections
    CA <= seg_data(6);
    CB <= seg_data(5);
    CC <= seg_data(4);
    CD <= seg_data(3);
    CE <= seg_data(2);
    CF <= seg_data(1);
    CG <= seg_data(0);
    DP <= '1';  -- Decimal point off
    AN <= anodes;
    
    -- LED connections
    LED <= leds_internal;
    
end Behavioral;
