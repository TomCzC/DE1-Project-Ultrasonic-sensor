library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_control is
    Port (
        clk          : in  std_logic;               -- 100 MHz clock input
        reset        : in  std_logic;               -- Asynchronous reset
        distance1    : in  std_logic_vector(8 downto 0);  -- Sensor 1 distance (0-511 cm)
        distance2    : in  std_logic_vector(8 downto 0);  -- Sensor 2 distance (0-511 cm)
        threshold    : in  std_logic_vector(8 downto 0);  -- Threshold value (0-511 cm)
        show_data_btn: in  std_logic;               -- Button to show distances
        show_thresh_btn: in std_logic;             -- Button to show threshold
        seg          : out std_logic_vector(6 downto 0);  -- Seven-segment outputs
        an           : out std_logic_vector(7 downto 0);  -- Anode control for 8 digits
        leds         : out std_logic_vector(15 downto 0)  -- 16 LEDs (0-15)
    );
end display_control;

architecture Behavioral of display_control is
    constant REFRESH_DIVIDER : integer := 10;
    signal refresh_counter : integer range 0 to REFRESH_DIVIDER-1 := 0;
    signal refresh_clk : std_logic := '0';

    signal digit_counter : integer range 0 to 7 := 0;
    signal digit_value   : std_logic_vector(3 downto 0);

    type digit_array is array (0 to 7) of std_logic_vector(3 downto 0);
    signal digits : digit_array;

    signal show_data_db, show_thresh_db : std_logic := '0';
    signal show_data_prev, show_thresh_prev : std_logic := '0';
    signal debounce_counter : integer range 0 to 100000 := 0;

    type display_mode_type is (SHOW_ID, SHOW_DISTANCES, SHOW_THRESHOLD);
    signal display_mode : display_mode_type := SHOW_ID;
    signal previous_mode : display_mode_type := SHOW_ID;

    signal leds_left  : std_logic_vector(2 downto 0);
    signal leds_right : std_logic_vector(2 downto 0);

    constant THRESHOLD_LEVEL1 : integer := 50;
    constant THRESHOLD_LEVEL2 : integer := 100;

    signal an_internal : std_logic_vector(7 downto 0);  -- Internal anode signal

begin

    -- Clock divider
    process(clk)
    begin
        if rising_edge(clk) then
            if refresh_counter < REFRESH_DIVIDER-1 then
                refresh_counter <= refresh_counter + 1;
            else
                refresh_counter <= 0;
                refresh_clk <= not refresh_clk;
            end if;
        end if;
    end process;

    -- Debounce logic
    process(clk)
    begin
        if rising_edge(clk) then
            if debounce_counter > 0 then
                debounce_counter <= debounce_counter - 1;
            else
                show_data_prev <= show_data_btn;
                show_thresh_prev <= show_thresh_btn;

                if show_data_btn = '1' and show_data_prev = '0' then
                    show_data_db <= '1';
                    debounce_counter <= 100000;
                else
                    show_data_db <= '0';
                end if;

                if show_thresh_btn = '1' and show_thresh_prev = '0' then
                    show_thresh_db <= '1';
                    debounce_counter <= 100000;
                else
                    show_thresh_db <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Display mode logic
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                display_mode <= SHOW_ID;
                previous_mode <= SHOW_ID;
            else
                if show_data_db = '1' then
                    if display_mode = SHOW_THRESHOLD then
                        display_mode <= previous_mode;
                    else
                        if display_mode = SHOW_ID then
                            display_mode <= SHOW_DISTANCES;
                            previous_mode <= SHOW_DISTANCES;
                        else
                            display_mode <= SHOW_ID;
                            previous_mode <= SHOW_ID;
                        end if;
                    end if;
                end if;

                if show_thresh_db = '1' then
                    if display_mode = SHOW_THRESHOLD then
                        display_mode <= previous_mode;
                    else
                        previous_mode <= display_mode;
                        display_mode <= SHOW_THRESHOLD;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- LED logic
    process(clk)
        variable d1, d2, th : integer;
        variable diff1, diff2 : integer;
    begin
        if rising_edge(clk) then
            d1 := to_integer(unsigned(distance1));
            d2 := to_integer(unsigned(distance2));
            th := to_integer(unsigned(threshold));

            diff1 := abs(d1 - th);
            diff2 := abs(d2 - th);

            if d1 <= th then
                leds_left <= "111";
            elsif diff1 <= THRESHOLD_LEVEL1 then
                leds_left <= "110";
            elsif diff1 <= THRESHOLD_LEVEL2 then
                leds_left <= "100";
            else
                leds_left <= "000";
            end if;

            if d2 <= th then
                leds_right <= "111";
            elsif diff2 <= THRESHOLD_LEVEL1 then
                leds_right <= "011";
            elsif diff2 <= THRESHOLD_LEVEL2 then
                leds_right <= "001";
            else
                leds_right <= "000";
            end if;
        end if;
    end process;

    -- Digit assignment
    process(display_mode, distance1, distance2, threshold)
        variable d1, d2, th : integer;
    begin
        d1 := to_integer(unsigned(distance1));
        d2 := to_integer(unsigned(distance2));
        th := to_integer(unsigned(threshold));

        case display_mode is
            when SHOW_ID =>
                digits(2) <= "1101"; -- d
                digits(1) <= "0000"; -- 0
                digits(0) <= "0001"; -- 1
                digits(3) <= "1111"; -- -
                digits(4) <= "1111"; -- -
                digits(7) <= "1101"; -- d
                digits(6) <= "0000"; -- 0
                digits(5) <= "0010"; -- 2

            when SHOW_DISTANCES =>
                digits(2) <= std_logic_vector(to_unsigned((d1 / 100) mod 10, 4));
                digits(1) <= std_logic_vector(to_unsigned((d1 / 10) mod 10, 4));
                digits(0) <= std_logic_vector(to_unsigned(d1 mod 10, 4));
                digits(3) <= "1111";
                digits(4) <= "1111";
                digits(7) <= std_logic_vector(to_unsigned((d2 / 100) mod 10, 4));
                digits(6) <= std_logic_vector(to_unsigned((d2 / 10) mod 10, 4));
                digits(5) <= std_logic_vector(to_unsigned(d2 mod 10, 4));

            when SHOW_THRESHOLD =>
                digits(0) <= "1111";
                digits(1) <= "1111";
                digits(4) <= std_logic_vector(to_unsigned((th / 100) mod 10, 4));
                digits(3) <= std_logic_vector(to_unsigned((th / 10) mod 10, 4));
                digits(2) <= std_logic_vector(to_unsigned(th mod 10, 4));
                digits(5) <= "1111";
                digits(6) <= "1111";
                digits(7) <= "1111";
        end case;
    end process;

    -- Display multiplexing
    process(refresh_clk)
    begin
        if rising_edge(refresh_clk) then
            if digit_counter < 7 then
                digit_counter <= digit_counter + 1;
            else
                digit_counter <= 0;
            end if;
       
            digit_value <= digits(digit_counter);
        end if;
    end process;

    an <= an_internal;

    -- Segment decoder
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
            when "1101" => seg <= "1000010"; -- d
            when "1111" => seg <= "1111110"; -- -
            when others => seg <= "1111111"; -- Blank
        end case;
    end process;

    -- LED output
    process(leds_left, leds_right)
    begin
        leds <= (others => '0');
        leds(15) <= leds_left(2);
        leds(14) <= leds_left(1);
        leds(13) <= leds_left(0);
        leds(2)  <= leds_right(2);
        leds(1)  <= leds_right(1);
        leds(0)  <= leds_right(0);
    end process;

end Behavioral;
