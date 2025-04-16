library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
    Port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        start          : in  std_logic;
        param          : in  std_logic_vector(7 downto 0);
        dist_sim       : in  std_logic_vector(7 downto 0);
        dist_valid     : in  std_logic;
        distance_disp  : out std_logic_vector(7 downto 0);
        trig_start     : out std_logic
    );
end controller;

architecture Behavioral of controller is
    -- Definice stavového automatu
    type state_type is (IDLE, TRIGGER, WAIT_VALID, UPDATE);
    signal state : state_type := IDLE;
begin

    process(clk, rst)
    begin
        if rst = '1' then
            -- Asynchronní reset: nastavení výchozích hodnot
            state          <= IDLE;
            distance_disp  <= (others => '0');
            trig_start     <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    trig_start <= '0';
                    -- Po stisku tla?ítka start p?ejdeme do generování triggeru
                    if start = '1' then
                        state <= TRIGGER;
                    else
                        state <= IDLE;
                    end if;
                   
                when TRIGGER =>
                    -- Generace jednosm?rného pulzu pro spušt?ní m??ení
                    trig_start <= '1';
                    state <= WAIT_VALID;
                   
                when WAIT_VALID =>
                    -- Po jednom taktu deaktivujeme trigger
                    trig_start <= '0';
                    -- ?ekáme, dokud není platný výstup z m??ení
                    if dist_valid = '1' then
                        state <= UPDATE;
                    else
                        state <= WAIT_VALID;
                    end if;
                   
                when UPDATE =>
                    -- Na?teme m??enou vzdálenost a p?edáme ji dál na displej
                    distance_disp <= dist_sim;
                    -- Vrátíme se do výchozího stavu
                    state <= IDLE;
                   
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
