library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
    Port (
        clk          : in  STD_LOGIC;                      -- System clock (100 MHz)
        reset        : in  STD_LOGIC;                      -- Active-high reset
        distance_in  : in  STD_LOGIC_VECTOR(8 downto 0);   -- Distance input from echo_receiver
        data_ready   : in  STD_LOGIC;                      -- Data ready signal from echo_receiver
        timeout      : in  STD_LOGIC;                      -- Timeout signal from echo_receiver
        trigger_out  : out STD_LOGIC;                      -- Trigger pulse to ultrasonic sensor
        distance_out : out STD_LOGIC_VECTOR(8 downto 0);   -- Processed distance output
        valid        : out STD_LOGIC;                      -- Valid data indicator
        thd        : out STD_LOGIC                         -- Distance alarm (configurable threshold)
    );
end controller;

architecture Behavioral of controller is
    -- Constants
    constant TRIGGER_PULSE_WIDTH : integer := 1000;  -- 10µs trigger pulse (1000 cycles at 100MHz)
    constant MEASUREMENT_INTERVAL : integer := 100_000_000;  -- 1 second between measurements
    
    -- Configurable alarm threshold (in cm)
    constant ALARM_THRESHOLD : integer := 100;  -- 1 meter threshold
    
    -- States for the controller FSM
    type state_type is (
        IDLE,
        SEND_TRIGGER,
        WAIT_ECHO,
        PROCESS_DATA,
        WAIT_INTERVAL
    );
    
    -- Internal signals
    signal state        : state_type := IDLE;
    signal counter      : unsigned(31 downto 0) := (others => '0');
    signal distance_reg : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    
begin
    -- Main control process
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset all signals and registers
                state <= IDLE;
                trigger_out <= '0';
                valid <= '0';
                thd <= '0';
                distance_out <= (others => '0');
                distance_reg <= (others => '0');
                counter <= (others => '0');
            else
                -- Default outputs
                valid <= '0';
                
                case state is
                    when IDLE =>
                        -- Wait before starting new measurement cycle
                        trigger_out <= '0';
                        if counter >= MEASUREMENT_INTERVAL-1 then
                            counter <= (others => '0');
                            state <= SEND_TRIGGER;
                        else
                            counter <= counter + 1;
                        end if;
                    
                    when SEND_TRIGGER =>
                        -- Generate 10µs trigger pulse
                        trigger_out <= '1';
                        if counter >= TRIGGER_PULSE_WIDTH-1 then
                            counter <= (others => '0');
                            trigger_out <= '0';
                            state <= WAIT_ECHO;
                        else
                            counter <= counter + 1;
                        end if;
                    
                    when WAIT_ECHO =>
                        -- Wait for echo receiver to complete measurement
                        if timeout = '1' then
                            -- No echo received (object too far)
                            distance_reg <= (others => '1');  -- Max distance value
                            state <= PROCESS_DATA;
                        elsif data_ready = '1' then
                            -- Valid measurement received
                            distance_reg <= distance_in;
                            state <= PROCESS_DATA;
                        end if;
                    
                    when PROCESS_DATA =>
                        -- Process the measured distance
                        distance_out <= distance_reg;
                        valid <= '1';
                        
                        -- Set alarm if below threshold (configurable)
                        if unsigned(distance_reg) < ALARM_THRESHOLD then
                            thd <= '1';
                        else
                            thd <= '0';
                        end if;
                        
                        state <= WAIT_INTERVAL;
                        counter <= (others => '0');
                    
                    when WAIT_INTERVAL =>
                        -- Short delay before next measurement
                        if counter >= 1000 then  -- 10µs delay
                            state <= IDLE;
                        else
                            counter <= counter + 1;
                        end if;
                    
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
