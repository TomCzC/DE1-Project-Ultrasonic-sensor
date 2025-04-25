library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
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
end controller;

architecture Behavioral of controller is
    -- Timing constants
    constant TRIGGER_PULSE_WIDTH : integer := 1000;  -- 10µs at 100MHz
    constant MEASUREMENT_INTERVAL : integer := 100_000_000;  -- 1 second
    
    -- State machine
    type state_type is (IDLE, SEND_TRIGGER, WAIT_ECHO, PROCESS_DATA);
    signal state : state_type := IDLE;
    
    -- Internal signals
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal distance_reg : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    signal trigger_active : std_logic := '0';
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset all signals
                state <= IDLE;
                trigger_out <= '0';
                valid <= '0';
                thd <= '0';
                distance_out <= (others => '0');
                counter <= (others => '0');
                distance_reg <= (others => '0');
                trigger_active <= '0';
            else
                -- Default outputs
                valid <= '0';
                thd <= '0';
                
                case state is
                    when IDLE =>
                        -- Wait for measurement interval
                        if counter >= MEASUREMENT_INTERVAL-1 then
                            counter <= (others => '0');
                            state <= SEND_TRIGGER;
                        else
                            counter <= counter + 1;
                        end if;
                        
                    when SEND_TRIGGER =>
                        -- Generate 10µs trigger pulse
                        trigger_out <= '1';
                        trigger_active <= '1';
                        counter <= (others => '0');
                        state <= WAIT_ECHO;
                        
                    when WAIT_ECHO =>
                        -- End trigger pulse after 10µs
                        if counter >= TRIGGER_PULSE_WIDTH-1 then
                            trigger_out <= '0';
                            trigger_active <= '0';
                        else
                            counter <= counter + 1;
                        end if;
                        
                        -- Wait for echo response
                        if timeout = '1' then
                            distance_reg <= (others => '1');  -- Max distance on timeout
                            state <= PROCESS_DATA;
                        elsif data_ready = '1' then
                            distance_reg <= distance_in;
                            state <= PROCESS_DATA;
                        end if;
                        
                    when PROCESS_DATA =>
                        -- Output the measured distance
                        distance_out <= distance_reg;
                        valid <= '1';
                        
                        -- Set threshold alert (thd) based on echo_receiver's status
                        thd <= '1' when (data_ready = '1' and unsigned(distance_reg) < unsigned(distance_in)) else '0';
                        
                        -- Prepare for next measurement
                        state <= IDLE;
                        counter <= (others => '0');
                        
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
