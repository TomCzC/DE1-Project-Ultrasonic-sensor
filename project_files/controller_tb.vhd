library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_tb is
end controller_tb;

architecture behavior of controller_tb is

    component controller
        port (
            clk          : in std_logic;
            reset        : in std_logic;
            distance_in  : in std_logic_vector(8 downto 0);
            data_ready   : in std_logic;
            timeout      : in std_logic;
            trigger_out  : out std_logic;
            distance_out : out std_logic_vector(8 downto 0);
            valid        : out std_logic;
            thd          : out std_logic;
            threshold    : in std_logic_vector(8 downto 0)
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal distance_in  : std_logic_vector(8 downto 0) := (others => '0');
    signal data_ready   : std_logic := '0';
    signal timeout      : std_logic := '0';
    signal trigger_out  : std_logic;
    signal distance_out : std_logic_vector(8 downto 0);
    signal valid        : std_logic;
    signal thd          : std_logic;
    signal threshold    : std_logic_vector(8 downto 0) := (others => '0');

    constant clk_period : time := 10 ns;

begin

    uut: controller
        port map (
            clk => clk,
            reset => reset,
            distance_in => distance_in,
            data_ready => data_ready,
            timeout => timeout,
            trigger_out => trigger_out,
            distance_out => distance_out,
            valid => valid,
            thd => thd,
            threshold => threshold
        );

    clk_process : process
    begin
        while true loop
            clk <= '0'; wait for clk_period / 2;
            clk <= '1'; wait for clk_period / 2;
        end loop;
    end process;

    stimulus_process : process
    begin
        reset <= '1';
        wait for 20 ns;           -- Shorter reset
        reset <= '0';
        wait for 20 ns;
        threshold <= "001111000"; -- 120
        
        wait until trigger_out = '1';  -- Wait for controller to trigger
        
        threshold <= "001111000"; -- 120
                
        -- First measurement
        distance_in <= "000110010"; -- 50
        data_ready <= '1';
        wait for 100 ns;
    
        -- Second measurement
        distance_in <= "001100100"; -- 100
        data_ready <= '1';
        wait for 100 ns;
    
        -- Third measurement
        distance_in <= "010111100"; -- 188
        data_ready <= '1';
        wait for 100 ns;
    
        -- Fourth measurement
        distance_in <= "000000101"; -- 5
        data_ready <= '1';
        wait for 100 ns;
    
        -- Fifth measurement
        distance_in <= "011111000"; -- 248
        data_ready <= '1';
        wait for 100 ns;
        data_ready <= '0';
        wait for 50 ns;
    
        -- Let it timeout
        wait;
    
    end process;

end behavior;
