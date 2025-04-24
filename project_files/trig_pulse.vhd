library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity trig_pulse is
    Port ( 
        clk   : in STD_LOGIC;
        start : in STD_LOGIC;
        trig  : out STD_LOGIC
    );
end trig_pulse;

architecture Behavioral of trig_pulse is
    constant PULSE_WIDTH : integer := 1000; -- 10µs pulse at 100MHz clock
    signal counter : integer range 0 to PULSE_WIDTH := 0;
    signal pulse_active : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if start = '1' and pulse_active = '0' then
                pulse_active <= '1';
                counter <= 0;
            elsif pulse_active = '1' then
                if counter < PULSE_WIDTH-1 then
                    counter <= counter + 1;
                else
                    pulse_active <= '0';
                end if;
            end if;
        end if;
    end process;

    trig <= pulse_active;
end Behavioral;
