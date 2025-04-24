library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity echo_receiver is
    Port (
        clk         : in  STD_LOGIC;                    -- System clock (100 MHz)
        reset       : in  STD_LOGIC;                    -- Active-high reset
        echo_pulse  : in  STD_LOGIC;                    -- Echo pulse from ultrasonic sensor
        distance    : out STD_LOGIC_VECTOR(8 downto 0); -- Calculated distance in cm (9-bit)
        ready       : out STD_LOGIC;                    -- High when distance measurement is ready
        timeout     : out STD_LOGIC                     -- High when no echo detected (timeout)
    );
end echo_receiver;

architecture Behavioral of echo_receiver is
    -- Constants
    constant CLK_FREQ      : integer := 100_000_000;    -- 100 MHz clock
    constant SOUND_SPEED   : integer := 34300;          -- Speed of sound in cm/s (343 m/s)
    constant TIMEOUT_CYCLES: integer := CLK_FREQ * 60 / 1000; -- 60ms timeout (~10m range)
    constant MAX_DISTANCE  : integer := 511;            -- Maximum representable distance (2^9 - 1)
    
    -- Internal signals
    signal counter         : unsigned(31 downto 0) := (others => '0');
    signal echo_reg        : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal echo_start      : STD_LOGIC := '0';
    signal echo_end        : STD_LOGIC := '0';
    signal measuring       : STD_LOGIC := '0';
    signal timeout_counter : unsigned(31 downto 0) := (others => '0');
    
begin
    -- Edge detection for echo pulse (double-flop synchronizer)
    process(clk)
    begin
        if rising_edge(clk) then
            echo_reg <= echo_reg(0) & echo_pulse;
            if reset = '1' then
                echo_reg <= "00";
            end if;
        end if;
    end process;
    
    echo_start <= '1' when echo_reg = "01" else '0'; -- Rising edge detection
    echo_end   <= '1' when echo_reg = "10" else '0'; -- Falling edge detection
    
    -- Measurement process
    process(clk)
        variable distance_temp : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                counter <= (others => '0');
                distance <= (others => '0');
                ready <= '0';
                timeout <= '0';
                measuring <= '0';
                timeout_counter <= (others => '0');
            else
                ready <= '0';
                timeout <= '0';
                
                -- Start measurement on rising edge of echo
                if echo_start = '1' then
                    measuring <= '1';
                    counter <= (others => '0');
                    timeout_counter <= (others => '0');
                end if;
                
                -- During measurement
                if measuring = '1' then
                    -- Increment counter while echo is high
                    if echo_pulse = '1' then
                        counter <= counter + 1;
                        timeout_counter <= timeout_counter + 1;
                        
                        -- Check for timeout (no echo end detected)
                        if timeout_counter >= TIMEOUT_CYCLES then
                            measuring <= '0';
                            timeout <= '1';
                            distance <= std_logic_vector(to_unsigned(MAX_DISTANCE, 9));
                            ready <= '1';
                        end if;
                    else
                        -- Echo ended, calculate distance
                        if echo_end = '1' then
                            measuring <= '0';
                            -- Distance calculation for 100 MHz clock:
                            -- distance_temp = (counter * 343) / 20000
                            distance_temp := (to_integer(counter) * 343) / 20000;
                            
                            -- Cap the distance at MAX_DISTANCE
                            if distance_temp > MAX_DISTANCE then
                                distance_temp := MAX_DISTANCE;
                            end if;
                            
                            distance <= std_logic_vector(to_unsigned(distance_temp, 9));
                            ready <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
