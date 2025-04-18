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

# Hardware design
![INOUT](https://github.com/user-attachments/assets/b8bc4688-fddc-4d11-9dc0-70a9965f4a90)

![hardware](https://github.com/user-attachments/assets/9329ce82-92b5-4aab-9ac6-ef83b5c2c08e)

![IMG_20250402_133631](https://github.com/user-attachments/assets/09d61c43-c357-4c93-ac26-ce2f540db133)
