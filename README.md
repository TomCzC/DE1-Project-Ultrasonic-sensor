# Team members

Adam Čermák;
Tomáš Běčák;
Mykhailo Krasichkov;
Daniel Kroužil

# Abstract

Tento projekt realizuje měření vzdálenosti pomocí dvou ultrazvukových senzorů HC-SR04, řízených FPGA. Systém umožňuje:
-Měření vzdálenosti v rozsahu 2–400 cm s rozlišením 1 cm
-Zobrazení hodnot na 7-segmentovém displeji
-Nastavení prahové hodnoty pomocí přepínačů (SW)
-Vizuální signalizaci pomocí LED diod
Senzory pracují nezávisle – jeden měří vzdálenost vlevo, druhý vpravo.

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

# Hardware design
![INOUT](https://github.com/user-attachments/assets/b8bc4688-fddc-4d11-9dc0-70a9965f4a90)

![hardware](https://github.com/user-attachments/assets/9329ce82-92b5-4aab-9ac6-ef83b5c2c08e)

![IMG_20250402_133631](https://github.com/user-attachments/assets/09d61c43-c357-4c93-ac26-ce2f540db133)
