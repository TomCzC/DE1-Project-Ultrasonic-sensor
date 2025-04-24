# Team members

Adam Čermák;
Tomáš Běčák;
Mykhailo Krasichkov;
Daniel Kroužil

# Abstract

Tento projekt realizuje měření vzdálenosti pomocí dvou ultrazvukových senzorů HS-SR04, řízených FPGA. Systém umožňuje:
 - Měření vzdálenosti v rozsahu 2–400 cm s rozlišením 1 cm
 - Zobrazení hodnot na 7-segmentovém displeji
 - Nastavení prahové hodnoty pomocí přepínačů (SW)
 - Vizuální signalizaci pomocí LED diod
Senzory pracují nezávisle – jeden měří vzdálenost vlevo, druhý vpravo.

# Hardware

Použité komponenty
 - FPGA deska (Nexys A7-50T)
 - Ultrazvukové senzory HC-SR04 (2×)

# Zapojení 

| Sloupec 1 | Sloupec 2 | Sloupec 3 |
|-----------|-----------|-----------|
| JA0       | Levý senzor    | Trigger (spouštěcí signál)   |
| JC0       | Levý senzor    | 	Echo (návratový signál)    |
| JD0       | Pravý senzor    | Trigger    |
| JB0       | Pravý senzor    | Echo    |
| SW[8:0]   | Přepínače | Data 3    |
| BTNU      | Tlačítko  | Nastavení prahové hodnoty (0–511 cm)     |
| BTNC      | Tlačítko  | Zbrazení vzdálenosti    |
| BTND      | Tlačítko  | Zobrazit práh    |

# Hardware design


# Funkce systému
1. Měření vzdálenosti
 - Každý senzor periodicky vysílá ultrazvukový impuls (10 µs).
 - Čas mezi vysláním a přijetím ozvěny (echo) určuje vzdálenost.
 - Pokud senzor nezachytí ozvěnu (objekt příliš daleko), systém detekuje timeout a vrátí maximální hodnotu (511 cm).
2. Zobrazení na 7-segmentovém displeji
 - Výchozí režim: Zobrazuje d01---d02 (identifikace senzorů).
 - Stisk BTNC: Zobrazí vzdálenosti v cm (levý a pravý senzor).
 - Stisk BTND: Zobrazí nastavený práh (hodnota z přepínačů SW).
3. Signalizace LED diodami
Levé LED (LED15-LED13): Indikují blízkost levého senzoru.
   - 111 = objekt blíže než práh
   - 100 = objekt v mezním pásmu
   - 000 = žádný objekt v dosahu
 - Pravé LED (LED2-LED0): Stejná logika pro pravý senzor.

# Jak to funguje uvnitř?
Hlavní soubory
 - [top_level.vhd](project_files/top_level.vhd) – Propojuje všechny komponenty.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – Detekuje echo a počítá vzdálenost.
 - [controller.vhd](project_files/controller.vhd) – Řídí měřicí cyklus a komunikaci se senzory.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – Generuje 10µs trigger pro HC-SR04.
 - [display_control.vhd](project_files/display_control.vhd) – Ovládá displej a LED.
Časování měření
 - Každý senzor měří 1× za sekundu.
 - Pokud není detekována ozvěna, systém automaticky pokračuje v další měřicí smyčce.





