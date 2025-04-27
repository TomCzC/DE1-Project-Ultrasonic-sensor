  **Vysoké učení technické v Brně, Fakulta elektrotechniky a komunikačních technologií, Ústav radioelektroniky, 2024/2025**  

---

# Řídicí systém pro ultrazvukové senzory parkovacího asistenta


##  členové týmu

 - Adam Čermák - Odpovědný za controller a poster
 - Tomáš Běčák - Odpovědný za Github, schéma a display_control
 - Mykhailo Krasichkov - Odpovědný za echo_detect, trig_pulse a zapojení na desce
 - Daniel Kroužil - Odpovědný za Github, controller a poster

## Popis projektu

Tento projekt realizuje měření vzdálenosti pomocí dvou ultrazvukových senzorů HS-SR04, řízených FPGA. Systém umožňuje:
 - **Měření vzdálenosti:**
   - Rozsah: **2-400 cm**
   - Rozlišení: **1 cm** (výpočet v ```echo_receiver.vhd``` pomocí ```ONE_CM``` konstanty)
 - **Zobrazení:**
   - 7-segmentový displej (výchozí režim: ```d01--d02```).
   - Prahová hodnota *Threshold* nastavitelná přepínač ```SW [8:0]```.
 - **Signalizace:**
   - LED indikace (levé: LED15-LED13, pravé: LED2-LED0)
 
## Hardware

Použité komponenty
 - FPGA deska Nexys A7-50T
 - Ultrazvukové senzory HC-SR04 (2×)
 - Arduino UNO Digital R3 (2×)

## Zapojení 

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

## Hardware design
<img src="images/top_level schematic.jpg" alt="top level block diagram" width="1000"/>

## Funkce systému
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
   - Stisk ```BTNC```: Zobrazí aktuální vzdálenosti v cm (levý a pravý senzor).
   - Stisk ```BTND```: Zobrazí nastavený práh (hodnota z přepínačů ```SW [8:0]```).

**3. Signalizace LED diodami**
 - **Levé LED (LED15-LED13):** Indikují blízkost levého senzoru.
   - 111 = Vzdálenost **≤ práh**.
   - 110 = Vzdálenost **≤ práh + 5 cm**.
   - 100 = Vzdálenost **≤ práh + 10 cm**.
   - 000 = Vzdálenost **> práh + 10 cm**.
 - **Pravé LED (LED2-LED0):** Stejná logika pro pravý senzor.

## Jak to funguje uvnitř?
Hlavní soubory
 - [top_level.vhd](project_files/top_level.vhd) – Tento hlavní 'top' modul propojuje všechny komponenty.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – Tento modul slouží k měření vzdálenosti na základě doby trvání signálu ```echo_in```, přičemž po obdržení impulsu ```trig``` začne počítat počet hodinových cyklů během logické jedničky na ```echo_in```, převede je na centimetry pomocí konstanty ```ONE_CM``` a výsledek poskytne na výstupu ```distance``` spolu s indikací platnosti měření pomocí signálu ```status```.
   - Při psaní echo_receiver jsme se inspirovali projektem z minulého roku. Náš echo_receiver má oproti loňské verzi lepší synchronizaci vstupu ```echo_in```, přesnější řízení měření pomocí stavového automatu a vyšší odolnost proti rušení. Navíc detekuje náběžnou hranu signálu ```trig``` a pracuje stabilněji při vysokých hodinových frekvencích.  
 - [controller.vhd](project_files/controller.vhd) – Tento modul implementuje řídicí jednotku, která periodicky generuje ```trigger``` pulz pro měření vzdálenosti, čeká na ```echo``` nebo ```timeout```, zpracuje přijatá data a vyhodnocuje, zda naměřená vzdálenost překročila nastavený práh.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – Tento modul generuje pulz šířky ```PULSE_WIDTH``` (v taktech hodin) na výstupu ```trig_out```, když dostane impuls na vstupu start. Používá synchronní reset ```rst```. Při 100 MHz hodinách a ```PULSE_WIDTH := 1000``` vytvoří pulz o délce 10 µs.
 - [display_control.vhd](project_files/display_control.vhd) – Tento modul implementuje systém řízení sedmisegmentového displeje, který podle tlačítek přepíná mezi zobrazením ID (```d01--d02```), vzdáleností ze dvou senzorů a aktuální prahovou hodnotou, přičemž zároveň indikuje vzdálenost vůči prahu pomocí LED.

### Časování měření
 - Každý senzor měří 1× za 0,5 s (50M cyklů při 100 MHz (viz controller.vhd)).

<img src="images/stavy.jpg" alt="Button states" width="500"/>

https://github.com/user-attachments/assets/559e6796-e8bb-4ae0-9059-a520a27b77e6


---

# English version - Ultrasonic Sensor Controller for Parking Assist System

## Team members

 - Adam Čermák - Responsible for controller a poster
 - Tomáš Běčák - Responsible for Github a display_control
 - Mykhailo Krasichkov - Responsible for echo_detect, trig_pulse and sensor connection to the FPGA board.
 - Daniel Kroužil - Responsible for controller a poster


## 📌 Abstract  
A dual-sensor ultrasonic measurement system built on the Nexys A7-50T FPGA, featuring:  
- **Distance Measurement**:  
  - Range: **2–400 cm** with **1 cm resolution**.  
  - Dual independent sensors (left/right).  
- **Dynamic Visualization**:  
  - 7-segment display for real-time distance/threshold values.  
  - LED indicators for proximity zones relative to a user-defined threshold.  
- **User Interaction**:  
  - Threshold set via **9-bit DIP switches (SW[8:0])** (0–511 cm).  
  - Buttons to toggle display modes.  


## 🛠️ Hardware Setup  
### Key Components  
- **FPGA Board**: Nexys A7-50T (central control unit).  
- **Sensors**: 2× HC-SR04 ultrasonic modules.
- Arduino UNO Digital R3 (2×)

### Pin Connections  
| **FPGA Pin** | **Component**      | **Function**       |  
|--------------|--------------------|--------------------|  
| `JA0`        | Left Sensor        | Trigger            |  
| `JC0`        | Left Sensor        | Echo               |  
| `JD0`        | Right Sensor       | Trigger            |  
| `JB0`        | Right Sensor       | Echo               |  
| `SW[8:0]`    | DIP Switches       | Threshold Setting  |  
| `BTNU`       | Button             | System Reset       |  
| `BTNC`       | Button             | Show Distances     |  
| `BTND`       | Button             | Show Threshold     |  


## Hardware design
<img src="images/top_level (1).jpg" alt="top level block diagram" width="1000"/>  
*Hardware architecture overview.*  


## ⚙️ System Features  
### 1. Distance Measurement  
- **Trigger Pulse**: 10 µs pulse sent periodically to sensors.  
- **Echo Processing**:  
  - Distance calculated from echo pulse duration.  
  - **Timeout Handling**: Returns 511 cm if no echo detected (object out of range).  

### 2. Display Modes  
- **Default**: Shows sensor IDs (`d01--d02`).  
- **Button Controls**:  
  - `BTNC`: Displays left/right distances (e.g., `200--300`).  
  - `BTND`: Shows threshold value set via switches.  

### 3. LED Proximity Indicators  
- **Left LEDs (LED15-LED13)**:  
  - `111` = **Below threshold**.  
  - `110` = **≤5 cm above threshold**.  
  - `100` = **≤10 cm above threshold**.  
  - `000` = **>10 cm above threshold**.  
- **Right LEDs (LED2-LED0)**: Same logic for the right sensor.  


## 🔍 Internal Workflow  
### Core Components  
 - [top_level.vhd](project_files/top_level.vhd) – This main 'top' module connects all components.
 - [echo_receiver.vhd](project_files/echo_receiver.vhd) – This module is used for measuring distance based on the duration of the echo_in signal. After receiving a trig pulse, it starts counting the number of clock cycles while echo_in is at logic high, converts them into centimeters using the ONE_CM constant, and provides the result on the distance output along with a validity indication using the status signal.  
   - When writing echo_receiver, we were inspired by a project from last year. Our echo_receiver has improved input synchronization for echo_in compared to the previous version, more accurate measurement control using a state machine, and higher noise immunity. Additionally, it detects the rising edge of the trig signal and works more reliably at high clock frequencies.  
 - [controller.vhd](project_files/controller.vhd) – This module implements the control unit, which periodically generates a trigger pulse for distance measurement, waits for an echo or timeout, processes the received data, and evaluates whether the measured distance has exceeded the set threshold.
 - [trig_pulse.vhd](project_files/trig_pulse.vhd) – This module generates a pulse of width PULSE_WIDTH (in clock cycles) on the trig_out output when it receives a pulse on the start input. It uses a synchronous reset rst. With a 100 MHz clock and PULSE_WIDTH := 1000, it produces a pulse of 10 µs length.
 - [display_control.vhd](project_files/display_control.vhd) – This module implements the seven-segment display control system, which switches between displaying the ID ("d01--d02"), the distance from two sensors, and the current threshold value based on buttons, while also indicating the distance relative to the threshold using LEDs.


### Timing  
- **Measurement Interval**: Each sensor updates **once per second**.  
- **Debounced Buttons**: Ensure stable mode switching.  

## 📂 Source Files  
- [top_level.vhd](project_files/top_level.vhd)  
- [echo_receiver.vhd](project_files/echo_receiver.vhd)  
- [controller.vhd](project_files/controller.vhd)  
- [trig_pulse.vhd](project_files/trig_pulse.vhd)  
- [display_control.vhd](project_files/display_control.vhd)  

---
    
**Brno University of Technology, Faculty of Electrical Engineering and Communication, Department of Radio Electronics, 2024/2025**  

---


---
