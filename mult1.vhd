LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_signed.all; --trabalha automaticamente com complemento de 2.

ENTITY mult1 IS
	PORT(
	  ----
	  ---  50 MHz
	   clk : IN std_logic;
		reset : IN std_logic;
		clk_ad   : OUT std_logic; -- sinal de entrada de clk do A/D (70 * taxa de amostragem = 70*40KHz =2.8MHz (ou algum outro valor))
		sinal_in : IN std_logic_vector(7 downto 0); --barramento dos simbolos de entrada.
		int_ad : IN std_logic; --sinal de interupção do A/D, corresponde a taxa "real" interna dos símbolos amostrados.
		
		
		sinal_ou : OUT std_logic_vector(7 downto 0)
		  --sinal_ou : OUT std_logic_vector(21 downto 0)
	);
END mult1;

ARCHITECTURE rtl OF mult1 IS
	SIGNAL counter : std_logic_vector(19 downto 0);-- contador para geração do relógio de mais baixa taxa 2^20
	CONSTANT inc_counter : std_logic_vector(19 downto 0) := "00001110010101100000";--step de contagem(58720) => bin( 2^20/(50e6/2.8e6))
	SIGNAL clk_ad_int : std_logic;
	SIGNAL int_ad_reg : std_logic_vector(2 downto 0);
	SIGNAL enable_ad : std_logic;
	
	CONSTANT number_of_coefs : INTEGER := 20;
	
	TYPE vector_delay_chain IS ARRAY (INTEGER RANGE <>) OF std_logic_vector(7 downto 0); -- tipo que será utlizado para criar a cadeia de atrasos do filtro.	
	SIGNAL delay_chain : vector_delay_chain(number_of_coefs-1 downto 0); --cadeia de atraso do filtro (12 atrasos)
	
	CONSTANT MULT_FACTOR : REAL := 2.0**11; --fator de normalização (representação em 12 bits com sinal ->(maior valor .999 menor valor -1)
	                                                              --(2^11-1 = 2047) Max pos.011111111111 -- Min neg. 100000000000 (-2^12 = -2048)--
		TYPE coefs_type IS ARRAY (NATURAL range <>) OF std_logic_vector(11 downto 0);
	
	
	CONSTANT coefs : coefs_type(number_of_coefs - 1 downto 0) := 
	(
	--filtro passa baixa com janela de hanning truncado para 20 taps wp=0.2->-3dB 0.6->40db.
	  conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.0024765),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR *  0.0015036),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0028747)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0130483)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0228354)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0156457)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.0252248),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR *  0.1001695),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.1851837),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.2420954),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.2420954),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.1851837),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.1001695),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.0252248),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0156457)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0228354)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0130483)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * (-0.0028747)),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.0015036),12), -- double
     conv_std_logic_vector(INTEGER(MULT_FACTOR * 0.0024765),12) -- double
    
	);
	
	TYPE result_mult_type IS ARRAY (NATURAL range <>) OF std_logic_vector(19 downto 0); --tipo que serÃ¡ utilizado para armazenar os resultados das multiplicações
	SIGNAL result_mult : result_mult_type(number_of_coefs - 1 downto 0);--armazena resultado das multiplicações por cada coeficiente/atraso. (10 downto 0)of (19 downto 0).
	SIGNAL result_sum : std_logic_vector(21 downto 0); --armazena resultado das somas.
	SIGNAL sinal_ad_reg : std_logic_vector(7 downto 0);
	
BEGIN
--processo gerador do relÃ³gio para amostragem no A/D (clk_ad)

	PROCESS(clk)
	BEGIN
		IF(rising_edge(clk)) then
			if(reset = '1') then
				clk_ad_int <= '0';
				counter <= (OTHERS => '0');
			else
				counter <= counter + inc_counter;
				clk_ad_int <= counter(19);
			end if;
		end IF;
	END PROCESS;
	
	
	clk_ad <= clk_ad_int;
	
--processo para amostragem da entrada de interrupção do A/D (clk de simbolo) -> para "conformação do sinal"	- gera enable interno de símbolo	PROCESS(clk)
	PROCESS(clk)
	BEGIN
		IF(rising_edge(clk)) THEN
			IF(reset = '1') THEN
				int_ad_reg <= (OTHERS => '0');
				enable_ad <= '0';
			ELSE
				int_ad_reg(0) <= int_ad;
				int_ad_reg(2 downto 1) <= int_ad_reg(1 downto 0);
				
				IF(int_ad_reg(2 downto 1) = "10") THEN -- na transição de '1' para '0'
					enable_ad <= '1';
				ELSE
					enable_ad <= '0';
				END IF;
				
			END IF;
		END IF;
	END PROCESS;
	
	-- Registrar sinal do AD
	PROCESS(clk)
		VARIABLE sum_int : std_logic_vector(21 downto 0);
		VARIABLE temp : std_logic_vector(21 downto 0);
	BEGIN
		IF(rising_edge(clk)) THEN
			IF(reset = '1') THEN
				sinal_ad_reg <= (OTHERS => '0');
				delay_chain <= (OTHERS => (OTHERS => '0'));
				result_mult <= (OTHERS => (OTHERS => '0'));
				result_sum <= (OTHERS => '0');
				sinal_ou <= (OTHERS => '0');
			ELSIF(enable_ad = '1') THEN
				sinal_ad_reg <= sinal_in;
				delay_chain(0) <= sinal_ad_reg;
				delay_chain(number_of_coefs-1 downto 1) <= delay_chain(number_of_coefs-2 downto 0);
				
				sum_int := (OTHERS => '0');
				
				LOOP1 : FOR i IN 0 TO number_of_coefs-1 LOOP
					result_mult(i) <= delay_chain(i) * coefs(i); -- multiplicação da cadeia de atraso pelos coeficientes neste instante de simbolo de entrada
					
					temp(19 downto 0) := result_mult(i);
					temp(21 downto 20) := (OTHERS => result_mult(i)(19)); --extensão de sinal + divisão por 2 para evitar overflow na soma.(representação em 22 bits aqui)
					
					sum_int := sum_int + temp;
					
					
				END LOOP;
				
				result_sum <= sum_int;
				sinal_ou <= result_sum;
				sinal_ou <= result_sum(17 downto 18-7);
				sinal_ou(7)<= NOT result_sum(18);
				--sinal_ou <= result_sum(21downto 21-7);
				--sinal_ou <= result_sum(7 downto 0);
				
			END IF;
		END IF;
	END PROCESS;
	
END rtl;