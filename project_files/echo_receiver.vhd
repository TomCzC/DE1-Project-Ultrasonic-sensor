library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity echo_receiver is
	generic (
		DEVICE_NUMBER : INTEGER := 1;
		MIN_DISTANCE : INTEGER := 50 
	);
	port ( 
    trig		     : in STD_LOGIC;
		echo_in		 : in STD_LOGIC;
		clk		     : in STD_LOGIC;
		rst		     : in STD_LOGIC;
		dev_num		 : out STD_LOGIC_VECTOR (2 downto 0);
		distance	 : out STD_LOGIC_VECTOR (8 downto 0); -- vysledok v cm (snima od cca 2 to 400 cm => cca 400 hodnot => potrebnych 9 bitov
		status		 : out STD_LOGIC 
	);
end echo_receiver;

architecture Behavioral of echo_receiver is
	-- konstanty
	constant ONE_CM		: INTEGER :=  5827; -- (343 m/s (20_C)) 5878 (340 m/s (15_C)) potrebny pocet clk cyklov na 1 cm (clk = 100 MHz)
	-- vnutorne signaly
	signal sig_count	: INTEGER range 0 to ONE_CM + 1; -- vnutorne pocitadlo
	signal sig_result	: INTEGER range 0 to 401; -- vysledok v cm
	signal sig_prepare	: STD_LOGIC;
	signal sig_count_enable	: STD_LOGIC;
	
begin  
	getDistance : process(clk, trig, echo_in) is
	begin
		if (trig = '1') then -- vyslanie trigovacieho pulzu - priprav pocitadlo
			sig_prepare <= '1';
		end if;
		if (sig_prepare = '1' and echo_in = '1') then -- ak na echo_in prisiel '1' (HIGH) pulz
			sig_count_enable <= '1'; -- zacni pocitanie casu
		end if;		
		
		if (rising_edge(clk)) then -- kazdu nabeznu hranu hodinoveho signalu
			if (rst = '1') then -- resetovanie 
				sig_prepare <= '0';
				sig_count_enable <= '0';
				sig_count <= 0;
				sig_result <= 0;
				distance <= (others => '0');
				status <= '0';
			-- pocitanie casu '1' (HIGH) pulzu na echo_in 
			elsif (sig_count_enable = '1') then
				if (echo_in = '0') then -- prichod odrazenej vlny naspat - vynulovanie signalov a poslanie vysledku
					distance <= std_logic_vector(to_unsigned(sig_result, 9));
					sig_count_enable <= '0';
					sig_prepare <= '0';
					if (sig_result < MIN_DISTANCE) then -- svetelne vyhodnotenie obsadenia (LED-kov)
						status <= '0';
					else
		                                status <= '1';
					end if;
					sig_result <= 0;
					sig_count <= 0;       
				elsif (echo_in = '1' and sig_count = ONE_CM) then -- ak sa napocitalo tolko cyklov odpovedajucich 1 cm
					if (sig_count = 400) then
						sig_result <= sig_result;
					else
						sig_result <= sig_result + 1; -- pripocitaj 1 cm k vysledku
						sig_count <= 0; -- vynuluj vnutorne pocitadlo
					end if;
				else
					sig_count <= sig_count + 1;
				end if;
			end if;
		end if;
        end process;
        -- cislo zariadenia
        dev_num <= std_logic_vector(to_unsigned(DEVICE_NUMBER, 3));        
end Behavioral;
