-- Testbench for trig_pulse module
-- Automatically generated at https://vhdl.lapinoo.net
-- Generation date: 2.4.2024 09:38:54 UTC

library ieee;
use ieee.std_logic_1164.all;

entity tb_trig_pulse is
end tb_trig_pulse;

architecture tb of tb_trig_pulse is

    -- Declaration of the DUT (Device Under Test)
    component trig_pulse
        generic (
            PULSE_WIDTH : integer
        );
        port (
            start    : in  std_logic;
            trig_out : out std_logic;
            clk      : in  std_logic;
            rst      : in  std_logic
        );
    end component;

    -- Signals to connect to DUT
    signal start    : std_logic := '0';
    signal trig_out : std_logic;
    signal clk      : std_logic := '0';
    signal rst      : std_logic;

    -- Clock period for 100 MHz (10 ns)
    constant TbPeriod : time := 10 ns;
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    -- DUT instantiation
    dut : trig_pulse
        generic map (
            PULSE_WIDTH => 10  -- Pulse width for the test
        )
        port map (
            start    => start,
            trig_out => trig_out,
            clk      => clk,
            rst      => rst
        );

    -- Clock generation for 100 MHz
    TbClock <= not TbClock after TbPeriod / 2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    -- Stimuli process
    stimuli : process
    begin
        -- Initialize start signal
        start <= '0';

        -- Reset generation (active low)
        rst <= '1';
        wait for 2 * TbPeriod;  -- Reset pulse duration
        rst <= '0';
        wait for 2 * TbPeriod;

        -- Start signal activation (first pulse)
        start <= '1';
        wait for 0.5 * TbPeriod;  -- Duration of start signal high
        start <= '0';
        wait for 30 * TbPeriod;   -- Wait for next operation

        -- Second pulse with a similar pattern
        start <= '1';
        wait for 0.5 * TbPeriod;
        start <= '0';
        wait for 5 * TbPeriod;

        -- Reset during pulse to test DUT reset behavior
        rst <= '1';
        wait for 2 * TbPeriod;  -- Wait for reset duration
        rst <= '0';
        wait for 30 * TbPeriod;

        -- Third pulse initiation
        start <= '1';
        wait for 0.5 * TbPeriod;
        start <= '0';
        wait for 30 * TbPeriod;

        -- End of simulation
        TbSimEnded <= '1';
        wait;  -- End the simulation after final events
    end process;

end tb;

-- Configuration block for some simulators
configuration cfg_tb_trig_pulse of tb_trig_pulse is
    for tb
    end for;
end cfg_tb_trig_pulse;
