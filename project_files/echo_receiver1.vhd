library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entity declaration for echo_receiver
entity echo_receiver is
    generic (
        DEVICE_NUMBER : integer := 1;   -- Sensor number (0 to 7)
        MIN_DISTANCE  : integer := 20   -- Minimum valid distance in centimeters (not used for thresholding here, but can be added)
    );
    port (
        clk      : in  std_logic;        -- 100 MHz clock
        rst      : in  std_logic;        -- Synchronous reset (active high)
        trig     : in  std_logic;        -- Trigger input: start measurement when high
        echo_in  : in  std_logic;        -- Echo input from ultrasonic sensor
        distance : out std_logic_vector(8 downto 0);  -- Output distance in centimeters
        sen_num  : out std_logic_vector(2 downto 0)   -- Sensor number in use
    );
end echo_receiver;

architecture Behavioral of echo_receiver is
    -- Constant for number of clock cycles corresponding to 1 cm.
    -- Calculation: time for 1 cm round-trip ~ 58µs and clock period = 10 ns (1/100MHz)
    -- Thus, ONE_CM = 58µs/10ns ≈ 5800 (using 5827 from your previous code for calibration)
    constant ONE_CM : integer := 5827;
    
    -- Define a simple state machine for the measurement process
    type state_type is (IDLE, WAIT_FOR_ECHO, COUNTING, DONE);
    signal state : state_type := IDLE;
    
    -- Internal signals for counting cycles and centimeters (distance)
    signal cycle_count  : integer range 0 to ONE_CM - 1 := 0;
    signal cm_count     : integer range 0 to 400 := 0; -- Count distance in cm (max 400)
    
begin

    -- Assign sensor number output (as a 3-bit vector)
    sen_num <= std_logic_vector(to_unsigned(DEVICE_NUMBER, 3));

    -- Main process: handles state machine and measurement
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- reset all signals and go to IDLE
                state       <= IDLE;
                cycle_count <= 0;
                cm_count    <= 0;
                distance    <= (others => '0');
            else
                case state is
                    when IDLE =>
                        -- Wait for a new trigger pulse
                        if trig = '1' then
                            -- Start a new measurement cycle
                            state       <= WAIT_FOR_ECHO;
                            cycle_count <= 0;
                            cm_count    <= 0;
                        end if;
                    
                    when WAIT_FOR_ECHO =>
                        -- Wait until the echo signal goes high
                        if echo_in = '1' then
                            state <= COUNTING;
                        end if;
                    
                    when COUNTING =>
                        if echo_in = '1' then
                            -- Count clock cycles while echo_in remains high
                            if cycle_count < ONE_CM - 1 then
                                cycle_count <= cycle_count + 1;
                            else
                                -- When ONE_CM cycles are counted, increment distance by 1 cm
                                if cm_count < 400 then
                                    cm_count    <= cm_count + 1;
                                end if;
                                cycle_count <= 0;
                            end if;
                        else
                            -- When echo_in falls, measurement is complete
                            state <= DONE;
                        end if;
                    
                    when DONE =>
                        -- Output the measured distance as a 9-bit vector.
                        -- (Conversion from integer to unsigned and then to std_logic_vector)
                        distance <= std_logic_vector(to_unsigned(cm_count, 9));
                        -- Go back to IDLE to await the next measurement cycle
                        state <= IDLE;
                    
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;

