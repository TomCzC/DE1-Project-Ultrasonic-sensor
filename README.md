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
    constant PULSE_WIDTH : integer := 10;
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

# Reciever

```
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ultrasonic_receiver is
    Port (
        clk        : in  std_logic;
        trig_sim   : in  std_logic;
        dist_sim   : out std_logic_vector(7 downto 0);
        dist_valid : out std_logic
    );
end ultrasonic_receiver;

architecture Behavioral of ultrasonic_receiver is
    -- Konstanty pro simulaci
    constant DELAY_CYCLES : integer := 20;  -- počet taktů pro simulaci doby šíření
    constant SIM_DISTANCE : std_logic_vector(7 downto 0) := "00101010";  -- simulovaná vzdálenost, např. 42 cm

    signal counter : integer range 0 to DELAY_CYCLES := 0;
    type state_type is (IDLE, DELAY, VALID);
    signal state : state_type := IDLE;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    dist_valid <= '0';
                    -- V tomto stavu čekáme na aktivní vstup trig_sim
                    if trig_sim = '1' then
                        counter <= 0;
                        state   <= DELAY;
                    end if;
                   
                when DELAY =>
                    -- Simulujeme dobu šíření signálu
                    if counter < DELAY_CYCLES - 1 then
                        counter <= counter + 1;
                    else
                        state <= VALID;
                    end if;
                   
                when VALID =>
                    -- Po uplynutí zpoždění je výstup měření aktivován na jeden takt
                    dist_sim   <= SIM_DISTANCE;
                    dist_valid <= '1';
                    state      <= IDLE;
                   
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
```


# Trig pulse

```
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity trig_pulse is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           trig1 : out STD_LOGIC;
           trig2 : out STD_LOGIC;
           trig3 : out STD_LOGIC;
           trig4 : out STD_LOGIC);
end trig_pulse;

architecture Behavioral of trig_pulse is
    signal counter      : integer range 0 to 10 := 0;
    signal pulse_active : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if start = '1' and pulse_active = '0' then
                pulse_active <= '1';
                counter <= 1;
            elsif pulse_active = '1' then
                if counter < 1 then
                    counter <= counter + 1;
                else
                    pulse_active <= '0';
                    counter <= 0;
                end if;
            end if;
        end if;
    end process;

    trig1 <= pulse_active;
    trig2 <= pulse_active;
    trig3 <= pulse_active;
    trig4 <= pulse_active;


end Behavioral;
```

# Trig pulse testbench

```
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
```

# Hardware design
![INOUT](https://github.com/user-attachments/assets/b8bc4688-fddc-4d11-9dc0-70a9965f4a90)

![hardware](https://github.com/user-attachments/assets/9329ce82-92b5-4aab-9ac6-ef83b5c2c08e)

![IMG_20250402_133631](https://github.com/user-attachments/assets/09d61c43-c357-4c93-ac26-ce2f540db133)
