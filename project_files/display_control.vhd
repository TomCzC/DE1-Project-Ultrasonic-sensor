library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display_control is
    Port (
        clk          : in  std_logic;               -- Clock input
        reset        : in  std_logic;               -- Asynchronous reset
        distance1    : in  std_logic_vector(11 downto 0); -- Sensor 1 distance
        distance2    : in  std_logic_vector(11 downto 0); -- Sensor 2 distance
        show_data    : in  std_logic;               -- Control input to switch display mode
        seg          : out std_logic_vector(6 downto 0);  -- Seven-segment outputs (CA to CG)
        an           : out std_logic_vector(7 downto 0)   -- Anode control for 8 digits
    );
end display_control;

architecture Behavioral of display_control is

    signal counter        : std_logic_vector(2 downto 0) := (others => '0');
    signal digit_value    : std_logic_vector(3 downto 0);
    signal current_anode  : std_logic_vector(7 downto 0) := "11111110";

    type digit_array is array (0 to 7) of std_logic_vector(3 downto 0);
    signal digits         : digit_array;

begin

    -- Multiplexing process
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            current_anode <= "11111110";
        elsif rising_edge(clk) then
            counter <= counter + 1;
            current_anode <= current_anode(6 downto 0) & current_anode(7);
        end if;
    end process;

    -- Digit select
    process(counter)
    begin
        digit_value <= digits(to_integer(unsigned(counter)));
        an <= not ("00000001" sll to_integer(unsigned(counter)));
    end process;

    -- Digit values (data or intro)
    process(distance1, distance2, show_data)
        variable d1, d2 : integer;
    begin
        if show_data = '1' then
            d1 := to_integer(unsigned(distance1));
            d2 := to_integer(unsigned(distance2));

            digits(0) <= std_logic_vector(to_unsigned((d1 / 100) mod 10, 4));
            digits(1) <= std_logic_vector(to_unsigned((d1 / 10) mod 10, 4));
            digits(2) <= std_logic_vector(to_unsigned(d1 mod 10, 4));

            digits(3) <= "1111"; -- '-' special
            digits(4) <= "1111"; -- '-' special

            digits(5) <= std_logic_vector(to_unsigned((d2 / 100) mod 10, 4));
            digits(6) <= std_logic_vector(to_unsigned((d2 / 10) mod 10, 4));
            digits(7) <= std_logic_vector(to_unsigned(d2 mod 10, 4));

        else
            digits(0) <= "1101"; -- 'd'
            digits(1) <= "0000"; -- '0'
            digits(2) <= "0001"; -- '1'

            digits(3) <= "1111"; -- '-'
            digits(4) <= "1111"; -- '-'

            digits(5) <= "1101"; -- 'd'
            digits(6) <= "0000"; -- '0'
            digits(7) <= "0010"; -- '2'
        end if;
    end process;

    -- Seven-segment decoder
    process(digit_value)
    begin
        case digit_value is
            when "0000" => seg <= "0000001"; -- 0
            when "0001" => seg <= "1001111"; -- 1
            when "0010" => seg <= "0010010"; -- 2
            when "0011" => seg <= "0000110"; -- 3
            when "0100" => seg <= "1001100"; -- 4
            when "0101" => seg <= "0100100"; -- 5
            when "0110" => seg <= "0100000"; -- 6
            when "0111" => seg <= "0001111"; -- 7
            when "1000" => seg <= "0000000"; -- 8
            when "1001" => seg <= "0000100"; -- 9
            when "1101" => seg <= "0110001"; -- 'd'
            when "1111" => seg <= "0111111"; -- '-' (custom)
            when others => seg <= "1111111"; -- Blank
        end case;
    end process;

end Behavioral;
