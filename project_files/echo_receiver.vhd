library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity echo_receiver is
    generic (
        MIN_DISTANCE : INTEGER := 10 
    );
    port ( 
        trig      : in  STD_LOGIC;
        echo_in   : in  STD_LOGIC;
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        distance  : out STD_LOGIC_VECTOR(8 downto 0); -- Distance in cm (0-400)
        status    : out STD_LOGIC 
    );
end echo_receiver;

architecture Behavioral of echo_receiver is
    constant ONE_CM : INTEGER := 5827; -- Clock cycles per cm at 100MHz
    signal sig_count     : INTEGER range 0 to ONE_CM + 1;
    signal sig_result    : INTEGER range 0 to 401;
    signal sig_prepare   : STD_LOGIC;
    signal sig_count_enable : STD_LOGIC;
    
begin  
    getDistance : process(clk, trig, echo_in)
    begin
        if (trig = '1') then -- Trigger pulse received
            sig_prepare <= '1';
        end if;
        
        if (sig_prepare = '1' and echo_in = '1') then -- Echo pulse started
            sig_count_enable <= '1';
        end if;        
        
        if rising_edge(clk) then
            if rst = '1' then -- Reset
                sig_prepare <= '0';
                sig_count_enable <= '0';
                sig_count <= 0;
                sig_result <= 0;
                distance <= (others => '0');
                status <= '0';
                
            elsif sig_count_enable = '1' then
                if echo_in = '0' then -- Echo pulse ended
                    distance <= std_logic_vector(to_unsigned(sig_result, 9));
                    sig_count_enable <= '0';
                    sig_prepare <= '0';
                    status <= '0' when (sig_result < MIN_DISTANCE) else '1';
                    sig_result <= 0;
                    sig_count <= 0;
                    
                elsif echo_in = '1' and sig_count = ONE_CM then
                    if sig_result < 400 then
                        sig_result <= sig_result + 1; -- Increment cm counter
                    end if;
                    sig_count <= 0;
                else
                    sig_count <= sig_count + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
