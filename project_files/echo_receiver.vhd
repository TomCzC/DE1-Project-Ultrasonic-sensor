library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity echo_receiver is
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
end echo_receiver;

architecture Behavioral of echo_receiver is
    constant CLK_FREQ   : INTEGER := 100_000_000;  -- 100 MHz
    constant SOUND_SPEED: INTEGER := 34300;        -- cm/s
    constant ONE_CM     : INTEGER := (CLK_FREQ * 2) / SOUND_SPEED; -- Clock cycles per cm
    
    signal echo_sync    : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal echo_clean   : STD_LOGIC := '0';
    signal pulse_count  : INTEGER range 0 to ONE_CM * 400 + 1 := 0;
    signal cm_count     : INTEGER range 0 to 400 := 0;
    signal measuring    : STD_LOGIC := '0';
    signal last_trig    : STD_LOGIC := '0';
    
begin
    -- Enhanced echo processing with noise filtering
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pulse_count <= 0;
                cm_count <= 0;
                measuring <= '0';
                distance <= (others => '0');
                status <= '0';
                echo_sync <= (others => '0');
                echo_clean <= '0';
            else
                -- Synchronize and debounce echo input
                echo_sync <= echo_sync(1 downto 0) & echo_in;
                
                -- Edge detection for trigger
                last_trig <= trig;
                
                -- Start measurement on rising edge of trigger
                if trig = '1' and last_trig = '0' then
                    measuring <= '1';
                    pulse_count <= 0;
                    cm_count <= 0;
                    status <= '0';
                end if;
                
                -- Distance measurement
                if measuring = '1' then
                    if echo_sync(2) = '1' then  -- Echo received
                        if pulse_count < ONE_CM then
                            pulse_count <= pulse_count + 1;
                        else
                            if cm_count < 400 then
                                cm_count <= cm_count + 1;
                            end if;
                            pulse_count <= 0;
                        end if;
                    else                        -- Echo ended
                        if cm_count > 0 then
                            measuring <= '0';
                            distance <= std_logic_vector(to_unsigned(cm_count, 9));
                            status <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
