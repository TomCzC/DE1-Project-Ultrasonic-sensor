library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
        CLK100MHZ : in  STD_LOGIC;
        SW        : in  STD_LOGIC_VECTOR(8 downto 0);
        JC0       : in  STD_LOGIC;   -- Left sensor echo
        JA0       : out STD_LOGIC;   -- Left sensor trigger               
        JB0       : in  STD_LOGIC;   -- Right sensor echo
        JD0       : out STD_LOGIC;   -- Right sensor trigger     
        BTNU      : in  STD_LOGIC;   -- Reset
        BTNC      : in  STD_LOGIC;   -- Show data button
        BTND      : in  STD_LOGIC;   -- Show threshold button
        LED       : out STD_LOGIC_VECTOR(15 downto 0);
        CA        : out STD_LOGIC;
        CB        : out STD_LOGIC;
        CC        : out STD_LOGIC;
        CD        : out STD_LOGIC;
        CE        : out STD_LOGIC;
        CF        : out STD_LOGIC;
        CG        : out STD_LOGIC;
        DP        : out STD_LOGIC;
        AN        : out STD_LOGIC_VECTOR(7 downto 0)
    );
end top_level;

architecture Behavioral of top_level is
    component echo_receiver is
        generic (
            MIN_DISTANCE : INTEGER := 10  -- Changed to 10 cm
        );
        port ( 
            trig      : in  STD_LOGIC;
            echo_in   : in  STD_LOGIC;
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            distance  : out STD_LOGIC_VECTOR(8 downto 0);
            status    : out STD_LOGIC 
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
            thd          : out STD_LOGIC;
            threshold    : in  STD_LOGIC_VECTOR(8 downto 0)  -- Added threshold input
        );
    end component;
    
    component trig_pulse is
        Port ( 
            clk    : in  STD_LOGIC;
            start  : in  STD_LOGIC;
            trig   : out STD_LOGIC
        );
    end component;
    
    component display_control is
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            distance1      : in  std_logic_vector(8 downto 0);
            distance2      : in  std_logic_vector(8 downto 0);
            threshold      : in  std_logic_vector(8 downto 0);
            show_data_btn  : in  std_logic;
            show_thresh_btn: in  std_logic;
            seg            : out std_logic_vector(6 downto 0);
            an             : out std_logic_vector(7 downto 0);
            leds           : out std_logic_vector(15 downto 0)
        );
    end component;
    
    signal reset : std_logic;
    
    -- Left sensor signals
    signal left_distance_raw : std_logic_vector(8 downto 0);
    signal left_distance_processed : std_logic_vector(8 downto 0);
    signal left_ready, left_timeout, left_valid, left_thd : std_logic;
    signal left_trigger_start, left_trigger_pulse : std_logic;
    
    -- Right sensor signals
    signal right_distance_raw : std_logic_vector(8 downto 0);
    signal right_distance_processed : std_logic_vector(8 downto 0);
    signal right_ready, right_timeout, right_valid, right_thd : std_logic;
    signal right_trigger_start, right_trigger_pulse : std_logic;
    
    -- Display signals
    signal seg_data : std_logic_vector(6 downto 0);
    signal anodes : std_logic_vector(7 downto 0);
    signal leds_internal : std_logic_vector(15 downto 0);
    
begin
    reset <= BTNU;
    
    -- Left sensor processing
    left_sensor: echo_receiver
        generic map (MIN_DISTANCE => 10)  -- Set to 10 cm
        port map (
            trig    => left_trigger_pulse,
            echo_in => JC0,
            clk     => CLK100MHZ,
            rst     => reset,
            distance => left_distance_raw,
            status  => left_ready
        );
    
    left_controller: controller
        port map (
            clk         => CLK100MHZ,
            reset       => reset,
            distance_in => left_distance_raw,
            data_ready  => left_ready,
            timeout     => '0',
            trigger_out => left_trigger_start,
            distance_out => left_distance_processed,
            valid       => left_valid,
            thd         => left_thd,
            threshold   => SW  -- Pass threshold from switches
        );
    
    left_trigger: trig_pulse
        port map (
            clk   => CLK100MHZ,
            start => left_trigger_start,
            trig  => left_trigger_pulse
        );
    
    -- Right sensor processing (identical to left)
    right_sensor: echo_receiver
        generic map (MIN_DISTANCE => 10)  -- Set to 10 cm
        port map (
            trig    => right_trigger_pulse,
            echo_in => JB0,
            clk     => CLK100MHZ,
            rst     => reset,
            distance => right_distance_raw,
            status  => right_ready
        );
    
    right_controller: controller
        port map (
            clk         => CLK100MHZ,
            reset       => reset,
            distance_in => right_distance_raw,
            data_ready  => right_ready,
            timeout     => '0',
            trigger_out => right_trigger_start,
            distance_out => right_distance_processed,
            valid       => right_valid,
            thd         => right_thd,
            threshold   => SW  -- Pass threshold from switches
        );
    
    right_trigger: trig_pulse
        port map (
            clk   => CLK100MHZ,
            start => right_trigger_start,
            trig  => right_trigger_pulse
        );
    
    -- Connect triggers to physical pins
    JA0 <= left_trigger_pulse;
    JD0 <= right_trigger_pulse;
    
    -- Display system
    display: display_control
        port map (
            clk            => CLK100MHZ,
            reset          => reset,
            distance1      => left_distance_processed,
            distance2      => right_distance_processed,
            threshold      => SW,
            show_data_btn  => BTNC,
            show_thresh_btn=> BTND,
            seg            => seg_data,
            an             => anodes,
            leds           => leds_internal
        );
    
    -- Seven-segment display connections
    CA <= seg_data(6);
    CB <= seg_data(5);
    CC <= seg_data(4);
    CD <= seg_data(3);
    CE <= seg_data(2);
    CF <= seg_data(1);
    CG <= seg_data(0);
    DP <= '1';  -- Decimal point always off
    AN <= anodes;
    
    -- LED connections
    LED <= leds_internal;
    
end Behavioral;
