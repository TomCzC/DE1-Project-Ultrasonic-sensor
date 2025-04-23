library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_control_tb is
end display_control_tb;

architecture behavior of display_control_tb is

    component display_control
        Port ( clk          : in  std_logic;
               reset        : in  std_logic;
               distance1    : in  std_logic_vector(8 downto 0);
               distance2    : in  std_logic_vector(8 downto 0);
               threshold    : in  std_logic_vector(8 downto 0);
               show_data_btn: in  std_logic;
               show_thresh_btn: in std_logic;
               seg          : out std_logic_vector(6 downto 0);
               an           : out std_logic_vector(7 downto 0);
               leds         : out std_logic_vector(15 downto 0)
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal distance1    : std_logic_vector(8 downto 0) := (others => '0');
    signal distance2    : std_logic_vector(8 downto 0) := (others => '0');
    signal threshold    : std_logic_vector(8 downto 0) := (others => '0');
    signal show_data_btn: std_logic := '0';
    signal show_thresh_btn: std_logic := '0';
    signal seg          : std_logic_vector(6 downto 0);
    signal an           : std_logic_vector(7 downto 0);
    signal leds         : std_logic_vector(15 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: display_control
        port map (
            clk => clk,
            reset => reset,
            distance1 => distance1,
            distance2 => distance2,
            threshold => threshold,
            show_data_btn => show_data_btn,
            show_thresh_btn => show_thresh_btn,
            seg => seg,
            an => an,
            leds => leds
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    stimulus_process : process
    begin
        reset <= '0';

        distance1 <= "011000100"; -- 200
        distance2 <= "100101100"; -- 300
        threshold <= "011111010"; -- 250
        show_data_btn <= '1';
        wait for 100 ns;
        show_data_btn <= '0';
        wait for 100 ns;

        distance1 <= "001100100"; -- 100
        distance2 <= "001001010"; -- 150
        threshold <= "001111000"; -- 120
        show_thresh_btn <= '1';
        wait for 100 ns;
        show_thresh_btn <= '0';
        wait for 100 ns;

        distance1 <= "111111111"; -- 511
        distance2 <= "111111111"; -- 511
        threshold <= "001111000"; -- 120

        distance1 <= "010101010"; -- 170
        distance2 <= "011011100"; -- 220
        threshold <= "001111000"; -- 120

        wait;
    end process;

    monitor_process : process(clk)
        function decode_segment(seg: std_logic_vector(6 downto 0)) return character is
        begin
            case seg is
                when "0000001" => return '0';
                when "1001111" => return '1';
                when "0010010" => return '2';
                when "0000110" => return '3';
                when "1001100" => return '4';
                when "0100100" => return '5';
                when "0100000" => return '6';
                when "0001111" => return '7';
                when "0000000" => return '8';
                when "0000100" => return '9';
                when "0111000" => return 'd'; -- custom d
                when "0111110" => return '-'; -- custom dash
                when others    => return '?';
            end case;
        end;

    begin
        if rising_edge(clk) then
            for i in 0 to 7 loop
                if an(i) = '0' then -- active low anode
                    report "AN(" & integer'image(i) & ") shows '" & decode_segment(seg) & "'";
                end if;
            end loop;
        end if;
    end process;

end behavior;
