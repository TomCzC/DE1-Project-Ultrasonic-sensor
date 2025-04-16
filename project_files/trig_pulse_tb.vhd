library ieee;
use ieee.std_logic_1164.all;

entity tb_trig_pulse is
end tb_trig_pulse;

architecture tb of tb_trig_pulse is

    component trig_pulse
        port (clk   : in std_logic;
              start : in std_logic;
              trig1 : out std_logic;
              trig2 : out std_logic;
              trig3 : out std_logic;
              trig4 : out std_logic);
    end component;

    signal clk   : std_logic;
    signal start : std_logic;
    signal trig1 : std_logic;
    signal trig2 : std_logic;
    signal trig3 : std_logic;
    signal trig4 : std_logic;

    constant TbPeriod : time := 10 ns; -- ***EDIT*** Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : trig_pulse
    port map (clk   => clk,
              start => start,
              trig1 => trig1,
              trig2 => trig2,
              trig3 => trig3,
              trig4 => trig4);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- ***EDIT*** Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- ***EDIT*** Adapt initialization as needed
        start <= '0';
        -- ***EDIT*** Add stimuli here
        wait for 10 * TbPeriod;
        start <='1';
        wait for 20 * TbPeriod;
        start <='0';
        wait for 30 * TbPeriod;
        start <='1';
        wait for 0.5 * TbPeriod;
        start <='0';
        wait for 10 * TbPeriod;
        start <='1';
        wait for 5 * TbPeriod;
        start<='0';
        wait for 20 * TbPeriod;    
        
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_trig_pulse of tb_trig_pulse is
    for tb
    end for;
end cfg_tb_trig_pulse;
