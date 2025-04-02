# Team members

Adam Čermák;
Tomáš Běčák;
Mykhailo Krasichkov;
Daniel Kroužil

# Abstract

Projekt simuluje systém varování řidiče před překážkou při couvání, podobně jako parkovací
senzory. Využívá k tomu FPGA desku Nexys A7-50T a 7segmentové displeje pro zobrazení
vzdálenosti a prahové hodnoty

An abstract is a short summary of your project, usually about a paragraph (6-7 sentences, 150-250 words) long. A well-written abstract serves multiple purposes: (a) an abstract lets readers get the gist or essence of your project quickly; (b) an abstract prepares readers to follow the detailed information, description, and results in your report; (c) and, later, an abstract helps readers remember key points from your project.

# Components & Functions

- Přepínače SW(15:8):
o Slouží k nastavení simulované vzdálenosti (0-255 cm).
- Přepínače SW(7:0):
o Slouží k nastavení prahové hodnoty pro varování (0-255 cm).
- Tlačítko BTNC (start):
o Spouští simulaci měření vzdálenosti v modulu Ultrasonic_Receiver.vhd.
- Tlačítko BTND (reset):
o Resetuje celý systém do výchozího stavu (vzdálenost, prahová hodnota,
displeje, LED dioda).
- 7segmentové displeje:
o Displeje 0-2 zobrazují simulovanou vzdálenost.
o Displeje 5-7 zobrazují nastavenou prahovou hodnotu.
- Červená LED dioda:
o Slouží jako vizuální varování, rozsvítí se, pokud je simulovaná vzdálenost menší
než prahová hodnota.
- Ultrasonic_Transmitter.vhd:
o Simuluje vysílání ultrazvukového signálu.
- Ultrasonic_Receiver.vhd:
o Simuluje příjem ultrazvukového signálu a generuje signály dist_sim
(simulovaná vzdálenost) a dist_valid (indikace platnosti dat).
- Controller.vhd:
o Zpracovává data z přepínačů a modulu Ultrasonic_Receiver.vhd.
o Generuje data pro zobrazení na displejích.
o Ovládá červenou LED diodu.
o Provádí resetování systému.
- Display_Control.vhd:
o Zobrazuje desítkové číslice na 7segmentových displejích.


# Controller

``` 
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
```

# Testbench Controller

``` tb
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

```

# Transmitter

```
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ultrasonic_transmitter is
    Port (
        clk        : in  std_logic;
        trig_start : in  std_logic;
        trig_sim   : out std_logic
    );
end ultrasonic_transmitter;

architecture Behavioral of ultrasonic_transmitter is
    -- Konstantu určující šířku generovaného pulzu (počet taktů)
    constant PULSE_WIDTH : integer := 10;  -- upravte dle potřeby
    signal counter : integer range 0 to PULSE_WIDTH := 0;
    type state_type is (IDLE, PULSE);
    signal state : state_type := IDLE;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    trig_sim <= '0';
                    if trig_start = '1' then
                        state   <= PULSE;
                        counter <= 0;
                        trig_sim <= '1';
                    end if;
                   
                when PULSE =>
                    if counter < PULSE_WIDTH - 1 then
                        counter <= counter + 1;
                        trig_sim <= '1';
                    else
                        trig_sim <= '0';
                        state   <= IDLE;
                    end if;
                   
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
```

# Hardware design
![INOUT](https://github.com/user-attachments/assets/b8bc4688-fddc-4d11-9dc0-70a9965f4a90)

![hardware](https://github.com/user-attachments/assets/9329ce82-92b5-4aab-9ac6-ef83b5c2c08e)
