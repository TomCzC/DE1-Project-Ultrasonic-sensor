  **Vysoké učení technické v Brně, Fakulta elektrotechniky a komunikačních technologií, Ústav radioelektroniky, 2024/2025**  

---

# Řídicí systém pro ultrazvukové senzory parkovacího asistenta


## 👥 Členové týmu

 - Adam Čermák - Odpovědný za controller a poster
 - Tomáš Běčák - Odpovědný za Github, schéma a display_control
 - Mykhailo Krasichkov - Odpovědný za echo_detect, trig_pulse a zapojení na desce
 - Daniel Kroužil - Odpovědný za Github, controller a poster

## 📝 Popis projektu

Tento projekt realizuje měření vzdálenosti pomocí dvou ultrazvukových senzorů HS-SR04, řízených FPGA. Systém umožňuje:
 - **Měření vzdálenosti:**
   - Rozsah: **2-400 cm** s rozlišením 1 cm (výpočet v ```echo_receiver.vhd``` pomocí ```ONE_CM``` konstanty).
   - Dva nezávislé senzory (levý/pravý).
 - **Zobrazení:**
   - 7-segmentový displej (výchozí režim: ```d01--d02```).
   - Prahová hodnota Threshold nastavitelná přepínači ```SW [8:0]```.
 - **Signalizace:**
   - LED indikace (levé: LED15-LED13, pravé: LED2-LED0).
 
## 🔌 Hardware

Použité komponenty
 - FPGA deska Nexys A7-50T
 - Ultrazvukové senzory HC-SR04 (2×)
 - Arduino UNO Digital R3 (2×)

## 🎚️ Zapojení 

| Pin       | Komponenta     | Funkce                                                          |
|-----------|----------------|-----------------------------------------------------------------|
| JA0       | Levý senzor    | Trigger                                                         |
| JC0       | Levý senzor    | Echo                                                            |
| JD0       | Pravý senzor   | Trigger                                                         |
| JB0       | Pravý senzor   | Echo                                                            |
| SW[8:0]   | Přepínače      | Nastavení prahové hodnoty (0–511 cm)                            |
| BTNU      | Tlačítko       | Reset                                                           |
| BTNC      | Tlačítko       | Zbrazení vzdálenosti na osmimístném sedmisegmentovém displeji   |
| BTND      | Tlačítko       | Zobrazit práhové hodnoty (0-511 cm)                             |

## 🛠️ Hardware design

<img src="images/top_level schematic.jpg" alt="top level block diagram" width="1000"/>
*Obr. 1 Schéma návrhu řešení*
<img src="images/sensor_connection.jpg" alt="top level block diagram" width="500"/>
*Obr. 2 Propojení HC-SR04 s piny desky Nexys A7-50t (zdroj: GitHub [vhdl-course Tomas Fryza](https://github.com/tomas-fryza/vhdl-labs/blob/master/lab8-project/images/ultrasonic_resistors.jpg))*

## ⚙️ Funkce systému

**1. Měření vzdálenosti**
 - **Ultrazvukový impuls**
   - Každý senzor periodicky vysílá **10 µs pulz** (generuje ```trig_pulse.vhd```).
   - Čas mezi vysláním a přijetím ozvěny (echo) určuje vzdálenost.
 - **Detekce překročení rozsahu:**
   - Objekt je příliš vzdálený a senzor nezachytí ozvěnu (echo se nevrátí do 250 ms (nastaveno v ```controller.vhd```)):
     - Systém detekuje timeout a vrátí maximální hodnotu (511 cm).

**2. Zobrazení na 7-segmentovém displeji**
 - **Výchozí režim:** Zobrazuje ID senzorů → ```d01--d02```.
 - **Ovládání tlačítky:**
   - Stisk ```BTNC```: Zobrazí aktuální vzdálenosti v cm pro levý a pravý senzor (např. ```200--300```).
   - Stisk ```BTND```: Zobrazí nastavený práh (hodnota z přepínačů ```SW [8:0]```).

**3. Signalizace LED diodami**
 - **Levé LED (LED15-LED13):** Indikují blízkost levého senzoru.
   - 111 = Vzdálenost **≤ práh**.
   - 110 = Vzdálenost **≤ práh + 5 cm**.
   - 100 = Vzdálenost **≤ práh + 10 cm**.
   - 000 = Vzdálenost **> práh + 10 cm**.
 - **Pravé LED (LED2-LED0):** Stejná logika pro pravý senzor.

## 🔍 Jak to funguje uvnitř?

📂 **Hlavní soubory**
 - [top_level.vhd](project_files/top_level.vhd) – Tento hlavní 'top' modul propojuje všechny komponenty.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – Tento modul slouží k měření vzdálenosti na základě doby trvání signálu ```echo_in```. Po obdržení impulsu se ```echo_in``` přiřadí hodnota logické 1 a ```trig``` začne počítat počet hodinových cyklů (*clock cycles*), které převede na centimetry pomocí konstanty ```ONE_CM```. Výsledek poskytne na výstupu ```distance``` spolu s indikací platnosti měření pomocí signálu ```status```.
   - Při psaní echo_receiver jsme se inspirovali projektem z minulého roku. Náš echo_receiver má oproti loňské verzi lepší synchronizaci vstupu ```echo_in```, přesnější řízení měření pomocí stavového automatu a vyšší odolnost proti rušení. Navíc detekuje náběžnou hranu signálu ```trig``` a pracuje stabilněji při vysokých hodinových frekvencích.  
 - [controller.vhd](project_files/controller.vhd) – Tento modul implementuje řídicí jednotku, která periodicky generuje ```trigger``` pulz pro měření vzdálenosti, čeká na ```echo``` nebo ```timeout```, zpracuje přijatá data a vyhodnocuje, zda naměřená vzdálenost překročila nastavený práh.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – Tento modul generuje pulz šířky ```PULSE_WIDTH``` (v taktech hodin) na výstupu ```trig_out```, když dostane impuls na vstupu start. Používá synchronní reset ```rst```. Při 100 MHz hodinách a ```PULSE_WIDTH := 1000``` vytvoří pulz o délce 10 µs.
 - [display_control.vhd](project_files/display_control.vhd) – Tento modul implementuje systém řízení sedmisegmentového displeje, který podle tlačítek přepíná mezi zobrazením ID (```d01--d02```), vzdáleností ze dvou senzorů a aktuální prahovou hodnotou, přičemž zároveň indikuje vzdálenost vůči prahu pomocí LED.

## ⏱️ Časování měření
 - Každý senzor měří 1× za 0,5 s (50M cyklů při 100 MHz (viz controller.vhd)).

<img src="images/stavy.jpg" alt="Button states" width="750"/>

https://github.com/user-attachments/assets/559e6796-e8bb-4ae0-9059-a520a27b77e6

---
---

# English version - Ultrasonic Sensor Controller for Parking Assist System

    
**Brno University of Technology, Faculty of Electrical Engineering and Communication, Department of Radio Electronics, 2024/2025**  

---

# Control System for Ultrasonic Sensors of Parking Assistant

## 👥 Team Members

 - Adam Čermák - Responsible for controller and poster
 - Tomáš Běčák - Responsible for GitHub, schematic, and display_control
 - Mykhailo Krasichkov - Responsible for echo_detect, trig_pulse, and board wiring
 - Daniel Kroužil - Responsible for GitHub, controller, and poster

## 📝 Project Description

This project implements distance measurement using two HS-SR04 ultrasonic sensors, controlled by FPGA. The system allows:
 - **Distance Measurement:**
   - Range: **2-400 cm** with 1 cm resolution (calculated in ```echo_receiver.vhd``` using the ```ONE_CM``` constant).
   - Dual independent sensors (left/right).
 - **Display:**
   - 7-segment display (default mode: ```d01--d02```).
   - Threshold adjustable via switch ```SW [8:0]```.
 - **Signaling:**
   - LED indicators (left: LED15-LED13, right: LED2-LED0).

## 🔌 Hardware

Components used:
 - FPGA board Nexys A7-50T
 - Ultrasonic sensors HC-SR04 (2×)
 - Arduino UNO Digital R3 (2×)

## 🎚️ Wiring

| Pin       | Component      | Function                                                         |
|-----------|----------------|------------------------------------------------------------------|
| JA0       | Left sensor     | Trigger                                                          |
| JC0       | Left sensor     | Echo                                                             |
| JD0       | Right sensor    | Trigger                                                          |
| JB0       | Right sensor    | Echo                                                             |
| SW[8:0]   | Switches        | Set threshold value (0–511 cm)                                   |
| BTNU      | Button          | Reset                                                            |
| BTNC      | Button          | Display distance on eight-digit 7-segment display               |
| BTND      | Button          | Display threshold values (0-511 cm)                             |

## 🛠️ Hardware Design

<img src="images/top_level schematic.jpg" alt="top level block diagram" width="1000"/>

## ⚙️ System Functionality

**1. Distance Measurement**
 - **Ultrasonic pulse**
   - Each sensor periodically sends a **10 µs pulse** (generated by ```trig_pulse.vhd```).
   - The time between sending and receiving the echo determines the distance.
 - **Out of range detection:**
   - If the object is too far and the sensor does not detect an echo within 250 ms (set in ```controller.vhd```):
     - The system detects a timeout and returns the maximum value (511 cm).

**2. Display on 7-segment Display**
 - **Default mode:** Displays sensor IDs → ```d01--d02```.
 - **Button control:**
   - Press ```BTNC```: Displays current distances in cm for left and right sensor (e.g. ```200--300```).
   - Press ```BTND```: Displays the set threshold (value from switches ```SW [8:0]```).

**3. LED Signaling**
 - **Left LEDs (LED15-LED13):** Indicate proximity for the left sensor.
   - 111 = Distance **≤ threshold**.
   - 110 = Distance **≤ threshold + 5 cm**.
   - 100 = Distance **≤ threshold + 10 cm**.
   - 000 = Distance **> threshold + 10 cm**.
 - **Right LEDs (LED2-LED0):** Same logic for the right sensor.

## 🔍 How Does It Work Inside?

📂 **Main Files**
 - [top_level.vhd](project_files/top_level.vhd) – This main 'top' module connects all components together.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – This module is used for measuring distance based on the duration of the ```echo_in``` signal. After receiving a pulse, ```echo_in``` is set to logical 1 and ```trig``` starts counting the number of clock cycles, which are then converted into centimeters using the ```ONE_CM``` constant. The result is provided at the ```distance``` output along with a measurement validity indication via the ```status``` signal.
   - When writing the echo_receiver, we were inspired by a project from last year. Our echo_receiver has improved synchronization of the ```echo_in``` input, more precise control of measurement using a state machine, and better resistance to noise. It also detects the rising edge of the ```trig``` signal and works more stably at high clock frequencies.
 - [controller.vhd](project_files/controller.vhd) – This module implements the control unit, periodically generating a ```trigger``` pulse for distance measurement, waiting for an ```echo``` or ```timeout```, processing received data, and evaluating whether the measured distance exceeds the set threshold.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – This module generates a pulse of width ```PULSE_WIDTH``` (in clock cycles) on the ```trig_out``` output when it receives a pulse on the start input. It uses a synchronous reset ```rst```. At 100 MHz clock and ```PULSE_WIDTH := 1000```, it generates a pulse of 10 µs.
 - [display_control.vhd](project_files/display_control.vhd) – This module implements a 7-segment display control system that switches between displaying sensor IDs (```d01--d02```), distances from two sensors, and the current threshold based on button presses, while simultaneously indicating distance relative to the threshold using LEDs.

## ⏱️ Measurement Timing
 - Each sensor measures once every 0.5 s (50M cycles at 100 MHz (see controller.vhd)).

<img src="images/stavy.jpg" alt="Button states" width="750"/>

https://github.com/user-attachments/assets/559e6796-e8bb-4ae0-9059-a520a27b77e6

