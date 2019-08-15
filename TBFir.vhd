LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_signed.all; 
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY TBFir IS
END TBFir;

ARCHITECTURE behavior OF TBFir IS


COMPONENT FirDesign
	PORT(
	  
	   clk : IN std_logic; --simula relogio de 50 MHz vindo da evaluation board.
		reset : IN std_logic;
		clk_ad   : OUT std_logic; -- sinal de entrada de clk do A/D (63* taxa de amostragem - especificação do A/D 0804)
		sinal_in : IN std_logic_vector(7 downto 0); --barramento do sinal de entrada de 8 bits vindos do A/D para o FIR.
		int_ad : IN std_logic; --sinal de interrupção fornecido pelo A/D na mesma taxa dos dados de entrada
		
		
		sinal_ou : OUT std_logic_vector(7 downto 0) --sinal de saida do FIR para o D/A 
		--sinal_ou : OUT std_logic_vector(21 downto 0)
	);
	END COMPONENT;
	
--connection signals

signal clk : std_logic :='0';
signal int_ad :  std_logic :='0';
signal enable_o: std_logic :='0';
signal reset: std_logic := '1';
signal clk_ad: std_logic;
signal sinal_in : std_logic_vector(7 downto 0);

--signal sinal_ou :  std_logic_vector(21 downto 0);
signal sinal_ou :  std_logic_vector(7 downto 0);

CONSTANT clock_period : time := 20 ns;
CONSTANT MULT_FACTOR : REAL := 2.0**7;
CONSTANT number_of_amostras : INTEGER := 8;	
signal contador : INTEGER range 0 to number_of_amostras-1;

--componente instatiation
BEGIN

uut: mult1 PORT MAP (
clk => clk,
reset => reset,
clk_ad => clk_ad,
sinal_in => sinal_in,
int_ad => int_ad,
sinal_ou => sinal_ou
);



--relogios e resets

clk <= not clk after clock_period/2;
int_ad <= not int_ad after clock_period;
enable_o <= '1' after 20*60 ns;
reset <= '0' after 60 ns;


  -------------------------------------------------
   -- Leitura do vetor de estimulos fornecido pelo arquivo
   --inputSignal.dat gerado no Octave.
   PROCESS
      FILE     fid1    : TEXT;
      VARIABLE line1   : LINE;
      VARIABLE sinalAD : std_logic_vector(7 downto 0);
      VARIABLE sinalAD_conv: std_logic_vector(7 downto 0);
   BEGIN
      file_open(fid1,"inputSignal.dat",READ_MODE);
      sinal_in <= (OTHERS => '0');
      wait until reset='0';
      WHILE TRUE LOOP
         wait until rising_edge(clk);
         readline(fid1,line1);
         read(line1, sinalAD);
        sinalAD_conv(7) := not sinalAD(7);
        sinalAD_conv(6 downto 0):= sinalAD(6 downto 0);
         sinal_in <= sinalAD_conv;
      END LOOP;
   END PROCESS;
   
  ----------------------------------------------------
--criação do arquivo outputSignal.dat com os valores de saida
-- pos simulação do filtro FIR, fornecidos pelo ModelSim 
  ----------------------------------------------------
   -- Write
   PROCESS
      FILE     fid2  : TEXT;
      VARIABLE line2 : LINE;
   BEGIN
      file_open(fid2, "ouputSignal.dat", WRITE_MODE);
      WHILE TRUE LOOP
         wait until rising_edge(clk) AND enable_o='1';
          write(line2,  conv_integer(sinal_ou),RIGHT, 10);
         writeline(fid2, line2);
      END LOOP;
   END PROCESS;

  

 
END behavior;	
