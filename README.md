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
| JA0       | Data 2    | Data 3    |
| JC0       | Data 5    | Data 6    |
| JD0       | Data 2    | Data 3    |
| JB0       | Data 5    | Data 6    |
| SW[8:0]   | Data 2    | Data 3    |
| BTNU      | Tlačítko  | Reset     |
| BTNC      | Data 5    | Zbrazení vzdálenosti    |
| BTND      | Data 5    | Data 6    |


# Hardware design
![INOUT](https://github.com/user-attachments/assets/b8bc4688-fddc-4d11-9dc0-70a9965f4a90)

![hardware](https://github.com/user-attachments/assets/9329ce82-92b5-4aab-9ac6-ef83b5c2c08e)

![IMG_20250402_133631](https://github.com/user-attachments/assets/09d61c43-c357-4c93-ac26-ce2f540db133)
