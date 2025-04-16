library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_controller is
-- Testbench nemá žádné porty.
end tb_controller;

architecture Behavioral of tb_controller is

    -- Signály pro propojení s testovaným modulem
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal start         : std_logic := '0';
    signal param         : std_logic_vector(7 downto 0) := (others => '0');
    signal dist_sim      : std_logic_vector(7 downto 0) := (others => '0');
    signal dist_valid    : std_logic := '0';
    signal distance_disp : std_logic_vector(7 downto 0);
    signal trig_start    : std_logic;
   
    -- Perioda hodin
    constant clk_period : time := 10 ns;

begin

    -- Instance testovaného modulu (DUT)
    DUT: entity work.controller
        port map (
            clk           => clk,
            rst           => rst,
            start         => start,
            param         => param,
            dist_sim      => dist_sim,
            dist_valid    => dist_valid,
            distance_disp => distance_disp,
            trig_start    => trig_start
        );

    -- Generátor hodin
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimula?ní proces
    stim_proc: process
    begin
        -- Inicializace: aktivujeme reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;
       
        -- Simulace: stisk tla?ítka start
        start <= '1';
        wait for clk_period;
        start <= '0';
       
        -- Krátká prodleva p?ed simulací validního m??ení
        wait for 30 ns;
       
        -- Simulace m??ení: aktivace dist_valid s p?eddefinovanou hodnotou dist_sim
        dist_sim   <= "00101010";  -- nap?íklad 42 v desítkové soustav?
        dist_valid <= '1';
        wait for clk_period;
        dist_valid <= '0';
       
        -- Prodleva, abychom mohli pozorovat výstupy
        wait for 50 ns;
       
        -- Další testovací sekvence: op?tovné spušt?ní
        start <= '1';
        wait for clk_period;
        start <= '0';
        wait for 30 ns;
       
        dist_sim   <= "01010101";  -- nap?íklad 85 v desítkové soustav?
        dist_valid <= '1';
        wait for clk_period;
        dist_valid <= '0';
       
        wait for 50 ns;
        -- Ukon?ení simulace
        wait;
    end process;

end Behavioral;
