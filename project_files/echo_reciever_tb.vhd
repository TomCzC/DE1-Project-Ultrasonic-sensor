library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity tb_echo_receiver is
end tb_echo_receiver;

architecture Behavioral of tb_echo_receiver is

    -- Component Declaration
    component echo_receiver
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            echo_pulse  : in  STD_LOGIC;
            distance    : out STD_LOGIC_VECTOR(8 downto 0);
            ready       : out STD_LOGIC;
            timeout     : out STD_LOGIC
        );
    end component;

    -- Constants
    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz clock
    constant SOUND_SPEED_CM_PER_US : real := 0.0343;  -- 343 m/s in cm/µs
    
    -- Signals
    signal clk          : STD_LOGIC := '0';
    signal reset        : STD_LOGIC := '1';
    signal echo_pulse   : STD_LOGIC := '0';
    signal distance     : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    signal ready        : STD_LOGIC := '0';
    signal timeout      : STD_LOGIC := '0';
    
    -- Test cases with distances and corresponding echo durations
    type test_case is record
        distance_cm : integer;
        duration    : time;
    end record;
    
    type test_array is array (natural range <>) of test_case;
    constant tests : test_array := (
        (10, 583 us),    -- 10 cm
        (50, 2.915 ms),  -- 50 cm
        (100, 5.83 ms),  -- 1 m
        (200, 11.66 ms), -- 2 m
        (300, 17.49 ms), -- 3 m
        (500, 29.15 ms)  -- 5 m (max range)
    );

begin

    -- Instantiate Unit Under Test
    uut: echo_receiver
        port map (
            clk => clk,
            reset => reset,
            echo_pulse => echo_pulse,
            distance => distance,
            ready => ready,
            timeout => timeout
        );

    -- Clock Generation (100 MHz)
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus Process
    stim_proc: process
        variable start_time : time;
    begin
        -- Initialize and reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for CLK_PERIOD*10;
        
        -- Verify reset cleared outputs
        assert distance = "000000000" and ready = '0' and timeout = '0'
            report "Reset test failed" severity error;
        
        -- Test 1: Timeout condition (no echo)
        wait for 60 ms;  -- Wait for timeout period
        assert distance = "111111111" and ready = '1' and timeout = '1'
            report "Timeout test failed" severity error;
        wait for CLK_PERIOD*10;
        
        -- Test distance measurements
        for i in tests'range loop
            -- Generate echo pulse
            echo_pulse <= '1';
            start_time := now;
            wait for tests(i).duration;
            echo_pulse <= '0';
            
            -- Wait for measurement completion
            wait until ready = '1' for 1 ms;
            assert ready = '1' 
                report "Ready signal not asserted for test case " & integer'image(i) 
                severity error;
                
            -- Verify distance (allow ±1cm tolerance)
            assert abs(to_integer(unsigned(distance)) - tests(i).distance_cm) <= 1
                report "Distance error for " & integer'image(tests(i).distance_cm) & 
                       " cm test. Got " & integer'image(to_integer(unsigned(distance))) &
                       " cm at time " & time'image(now - start_time)
                severity error;
            
            wait for CLK_PERIOD*10;
        end loop;
        
        -- Test maximum distance (511 cm)
        echo_pulse <= '1';
        wait for 29.8 ms;  -- ~511 cm
        echo_pulse <= '0';
        wait until ready = '1';
        assert to_integer(unsigned(distance)) = 511
            report "Max distance test failed. Got " & integer'image(to_integer(unsigned(distance)))
            severity error;
        
        -- Test beyond maximum distance (should clip to 511)
        echo_pulse <= '1';
        wait for 35 ms;  -- ~600 cm
        echo_pulse <= '0';
        wait until ready = '1';
        assert to_integer(unsigned(distance)) = 511
            report "Distance clipping test failed"
            severity error;
        
        -- Simulation complete
        report "=== ALL TESTS PASSED ===";
        wait;
    end process;

end Behavioral;
