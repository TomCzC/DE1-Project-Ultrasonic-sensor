library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    port ( 
        CLK100MHZ : in  STD_LOGIC;
        SW        : in  STD_LOGIC_VECTOR(8 downto 0);
        BTNU      : in  STD_LOGIC;   -- Reset
        -- Ultrasonic sensor connections
        JC0       : in  STD_LOGIC;   -- Left sensor echo
        JA0       : out STD_LOGIC;   -- Left sensor trigger               
        JB0       : in  STD_LOGIC;   -- Right sensor echo
        JD0       : out STD_LOGIC;   -- Right sensor trigger     
        -- Display and control
        BTNC      : in  STD_LOGIC;   -- Show data button
        BTND      : in  STD_LOGIC;   -- Show threshold button
        LED       : out STD_LOGIC_VECTOR(15 downto 0);
        -- 7-segment display
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
    -- Component declarations
    component trig_pulse is
        generic (
            PULSE_WIDTH : positive := 1000  -- 10µs pulse at 100MHz
        );
        port (
            clk      : in  STD_LOGIC;
            rst      : in  STD_LOGIC;
            start    : in  STD_LOGIC;
            trig_out : out STD_LOGIC
        );
    end component;
    
    component echo_receiver is
        generic (
            MIN_DISTANCE : INTEGER := 10  -- 10 cm minimum distance
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
        port (
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            distance_in  : in  STD_LOGIC_VECTOR(8 downto 0);
            data_ready   : in  STD_LOGIC;
            timeout      : in  STD_LOGIC;
            trigger_out  : out STD_LOGIC;
            distance_out : out STD_LOGIC_VECTOR(8 downto 0);
            valid        : out STD_LOGIC;
            thd          : out STD_LOGIC;
            threshold    : in  STD_LOGIC_VECTOR(8 downto 0)
        );
    end component;
    
    component display_control is
        port (
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
    
    -- Internal signals
    signal reset : std_logic;
    
    -- Left sensor signals
    signal left_distance_raw      : std_logic_vector(8 downto 0);
    signal left_distance_processed: std_logic_vector(8 downto 0);
    signal left_ready, left_valid, left_thd : std_logic;
    signal left_trigger_start     : std_logic;
    signal left_trigger_internal  : std_logic;  -- Added internal trigger signal
    
    -- Right sensor signals
    signal right_distance_raw      : std_logic_vector(8 downto 0);
    signal right_distance_processed: std_logic_vector(8 downto 0);
    signal right_ready, right_valid, right_thd : std_logic;
    signal right_trigger_start     : std_logic;
    signal right_trigger_internal  : std_logic;  -- Added internal trigger signal
    
    -- Display signals
    signal seg_data : std_logic_vector(6 downto 0);
    signal leds_internal : std_logic_vector(15 downto 0);
    
begin
    reset <= BTNU;
    
    -- Connect internal trigger signals to output ports
    JA0 <= left_trigger_internal;
    JD0 <= right_trigger_internal;
    
    -- Left sensor processing chain
    left_trigger: trig_pulse
        generic map (PULSE_WIDTH => 1000)  -- 10µs pulse
        port map (
            clk      => CLK100MHZ,
            rst      => reset,
            start    => left_trigger_start,
            trig_out => left_trigger_internal  -- Changed to internal signal
        );
    
    left_sensor: echo_receiver
        generic map (MIN_DISTANCE => 10)
        port map (
            trig     => left_trigger_internal,  -- Changed to internal signal
            echo_in  => JC0,
            clk      => CLK100MHZ,
            rst      => reset,
            distance => left_distance_raw,
            status   => left_ready
        );
    
    left_controller: controller
        port map (
            clk         => CLK100MHZ,
            reset       => reset,
            distance_in => left_distance_raw,
            data_ready  => left_ready,
            timeout     => '0',
            trigger_out => left_trigger_start,
            distance_out=> left_distance_processed,
            valid       => left_valid,
            thd         => left_thd,
            threshold   => SW
        );
    
    -- Right sensor processing chain (identical to left)
    right_trigger: trig_pulse
        generic map (PULSE_WIDTH => 1000)  -- 10µs pulse
        port map (
            clk      => CLK100MHZ,
            rst      => reset,
            start    => right_trigger_start,
            trig_out => right_trigger_internal  -- Changed to internal signal
        );
    
    right_sensor: echo_receiver
        generic map (MIN_DISTANCE => 10)
        port map (
            trig     => right_trigger_internal,  -- Changed to internal signal
            echo_in  => JB0,
            clk      => CLK100MHZ,
            rst      => reset,
            distance => right_distance_raw,
            status   => right_ready
        );
    
    right_controller: controller
        port map (
            clk         => CLK100MHZ,
            reset       => reset,
            distance_in => right_distance_raw,
            data_ready  => right_ready,
            timeout     => '0',
            trigger_out => right_trigger_start,
            distance_out=> right_distance_processed,
            valid       => right_valid,
            thd         => right_thd,
            threshold   => SW
        );
    
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
            an             => AN,
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
    
    -- LED connections
    LED <= leds_internal;
end Behavioral;
