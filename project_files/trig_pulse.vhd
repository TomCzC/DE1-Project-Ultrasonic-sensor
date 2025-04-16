library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity trig_pulse is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           trig1 : out STD_LOGIC;
           trig2 : out STD_LOGIC;
           trig3 : out STD_LOGIC;
           trig4 : out STD_LOGIC);
end trig_pulse;

architecture Behavioral of trig_pulse is
    signal counter      : integer range 0 to 10 := 0;
    signal pulse_active : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if start = '1' and pulse_active = '0' then
                pulse_active <= '1';
                counter <= 1;
            elsif pulse_active = '1' then
                if counter < 1 then
                    counter <= counter + 1;
                else
                    pulse_active <= '0';
                    counter <= 0;
                end if;
            end if;
        end if;
    end process;

    trig1 <= pulse_active;
    trig2 <= pulse_active;
    trig3 <= pulse_active;
    trig4 <= pulse_active;


end Behavioral;
