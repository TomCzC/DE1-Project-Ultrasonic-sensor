library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trig_pulse is
    generic (
        PULSE_WIDTH : positive := 1000  -- Default 10Âµs pulse at 100MHz clock
    );
    port (
        clk      : in  STD_LOGIC;
        rst      : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        trig_out : out STD_LOGIC
    );
end trig_pulse;

architecture Behavioral of trig_pulse is
    signal counter      : integer range 0 to PULSE_WIDTH := 0;
    signal pulse_active : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Synchronous reset
                trig_out    <= '0';
                pulse_active <= '0';
                counter     <= 0;
            else
                -- Start new pulse when requested and no active pulse
                if start = '1' and pulse_active = '0' then
                    pulse_active <= '1';
                    counter      <= 0;
                    trig_out    <= '1';
                
                -- Continue active pulse
                elsif pulse_active = '1' then
                    if counter < PULSE_WIDTH-1 then
                        counter <= counter + 1;
                    else
                        -- End of pulse
                        pulse_active <= '0';
                        trig_out    <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
