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
        thd          : out STD_LOGIC;
        threshold    : in  STD_LOGIC_VECTOR(8 downto 0)  -- Added threshold input
    );
end controller;

architecture Behavioral of controller is
    constant TRIGGER_PULSE_WIDTH : integer := 1000;  -- 10µs at 100MHz
    constant MEASUREMENT_INTERVAL : integer := 100_000_000;  -- 1 second
    
    type state_type is (IDLE, SEND_TRIGGER, WAIT_ECHO, PROCESS_DATA);
    signal state : state_type := IDLE;
    
    signal counter : unsigned(31 downto 0) := (others => '0');
    signal distance_reg : STD_LOGIC_VECTOR(8 downto 0) := (others => '0');
    signal trigger_active : std_logic := '0';
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= IDLE;
                trigger_out <= '0';
                valid <= '0';
                thd <= '0';
                distance_out <= (others => '0');
                counter <= (others => '0');
                distance_reg <= (others => '0');
                trigger_active <= '0';
            else
                case state is
                    when IDLE =>
                        trigger_out <= '0';
                        valid <= '0';
                        if counter >= MEASUREMENT_INTERVAL-1 then
                            counter <= (others => '0');
                            state <= SEND_TRIGGER;
                        else
                            counter <= counter + 1;
                        end if;
                        
                    when SEND_TRIGGER =>
                        trigger_out <= '1';
                        state <= WAIT_ECHO;
                        counter <= (others => '0');
                        
                    when WAIT_ECHO =>
                        trigger_out <= '0';
                        if timeout = '1' then
                            distance_reg <= (others => '1');  -- Max distance on timeout
                            state <= PROCESS_DATA;
                        elsif data_ready = '1' then
                            distance_reg <= distance_in;
                            state <= PROCESS_DATA;
                        end if;
                        
                    when PROCESS_DATA =>
                        distance_out <= distance_reg;
                        valid <= '1';
                        -- Compare to external threshold (SW inputs)
                        if (unsigned(distance_reg) < unsigned(threshold)) then
                            thd <= '1';
                        else
                            thd <= '0';
                        end if;
                        state <= IDLE;
                        counter <= (others => '0');
                        
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
