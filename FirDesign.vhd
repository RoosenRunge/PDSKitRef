LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_signed.all; --trabalha automaticamente com complemento de 2.

ENTITY FirDesign IS
	PORT(
	   clk : IN std_logic; --simula relogio de 50 MHz vindo da evaluation board.
		reset : IN std_logic;
		clk_ad   : OUT std_logic; -- sinal de entrada de clk do A/D (63* taxa de amostragem - especificação do A/D 0804)
		sinal_in : IN std_logic_vector(7 downto 0); --barramento do sinal de entrada de 8 bits vindos do A/D para o FIR.
		int_ad : IN std_logic; --sinal de interrupção fornecido pelo A/D na mesma taxa dos dados de entrada
		sinal_ou : OUT std_logic_vector(7 downto 0) --sinal de saida do FIR para o D/A 
	);
END FirDesign;

ARCHITECTURE rtl OF FirDesign IS

	SIGNAL clk_ad_int : std_logic;
	SIGNAL clk_ad_int1 : std_logic;
	SIGNAL int_ad_reg : std_logic_vector(2 downto 0);
	SIGNAL enable_ad : std_logic;
	
	CONSTANT number_of_coefs : INTEGER := 65;
	
	TYPE vector_delay_chain IS ARRAY (INTEGER RANGE <>) OF std_logic_vector(7 downto 0); -- tipo que ser
	
	SIGNAL delay_chain : vector_delay_chain(number_of_coefs-1 downto 0); --cadeia de atraso do filtro 
	
	CONSTANT MULT_FACTOR : REAL := 2.0**11; --fator de normalização para trabalhar com ponto fixo(complemento de 2) utilizando 12 bits
	                                        --(2^11-1 = 2047) Max pos.011111111111 -- Min neg. 100000000000 (-2^12 = -2048)--
		TYPE coefs_type IS ARRAY (NATURAL range <>) OF std_logic_vector(11 downto 0);

--coeficientes do filtro obtidos a partir do arquivo coefs.dat gerado de forma automática pelo código genCoefs.m
	CONSTANT coefs : coefs_type(number_of_coefs - 1 downto 0) := 

----Filtro passa baixa utilizando Janela de kaiser ws = 0.026*pi (0 - 250Hz)banda de passagem;  (wp = 0.0875*pi(1000Hz), pi) ;sigma= 0.015 (36dB rejeicao)=> para Fs=23kHz
--(
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0010596)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.001579)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0021705)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0028112)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0034706)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0041106)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0046865)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0051483)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0054425)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0055137)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0053074)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0047724)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0038631)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0025424)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.00078389)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0014262)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0040871)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0071823)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.010679)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.014529)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.018669)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.023018)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.027489)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.031981)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.03639)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.040606)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.044522)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.048036)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.051054)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.053492)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.055285)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.056381)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.056561)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.056381)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.055285)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.053492)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.051054)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.048036)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.044522)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.040606)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.03639)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.031981)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.027489)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.023018)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.018669)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.014529)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.010679)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0071823)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0040871)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0014262)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.00078389)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0025424)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0038631)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0047724)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0053074)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0055137)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0054425)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0051483)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0046865)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0041106)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0034706)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0028112)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0021705)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.001579)),12),	
--conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0010596)),12));	
	

	
----Filtro passa alta utilizando Janela de kaiser ws = 0.026*pi (0 - 250Hz)banda de rejeicao;  (wp = 0.0875*pi(1000Hz), pi) ;sigma= 0.015 (36dB rejeicao)=> para Fs=23kHz
(
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0010596)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.001579)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0021705)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0028112)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0034706)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0041106)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0046865)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0051483)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0054425)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0055137)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0053074)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0047724)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0038631)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0025424)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.00078389)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0014262)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0040871)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0071823)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.010679)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.014529)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.018669)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.023018)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.027489)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.031981)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.03639)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.040606)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.044522)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.048036)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.051054)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.053492)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.055285)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.056381)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.94344)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.056381)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.055285)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.053492)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.051054)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.048036)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.044522)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.040606)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.03639)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.031981)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.027489)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.023018)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.018669)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.014529)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.010679)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0071823)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0040871)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (-0.0014262)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.00078389)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0025424)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0038631)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0047724)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0053074)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0055137)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0054425)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0051483)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0046865)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0041106)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0034706)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0028112)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0021705)),12),	
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.001579)),12),
conv_std_logic_vector(INTEGER(MULT_FACTOR *  (0.0010596)),12));	

	

	TYPE result_mult_type IS ARRAY (NATURAL range <>) OF std_logic_vector(19 downto 0); 
	SIGNAL result_mult : result_mult_type(number_of_coefs - 1 downto 0);--armazena resultado das multiplic
	SIGNAL result_sum : std_logic_vector(21 downto 0); --armazena resultado das somas.
	SIGNAL sinal_ad_reg : std_logic_vector(7 downto 0); --sinal para registrar a entrada de sinal vinda do A/D
	SIGNAL counter1: INTEGER range 0 TO 16:=0; -- freq_AD = 1.472 kHz -> F_intr = Fs = 23 kHz

	
BEGIN
	
	clk_ad <= clk_ad_int1;
	
--processo para amostragem do sinal de interrupção vindo do A/D
	PROCESS(clk)
	BEGIN
		IF(rising_edge(clk)) THEN
			IF(reset = '1') THEN
				int_ad_reg <= (OTHERS => '0');
				enable_ad <= '0';
			ELSE
				int_ad_reg(0) <= int_ad;
				int_ad_reg(2 downto 1) <= int_ad_reg(1 downto 0);
				
				IF(int_ad_reg(2 downto 1) = "10") THEN 
				
					enable_ad <= '1';
				ELSE
					enable_ad <= '0';
				END IF;
				
			END IF;
		END IF;
	END PROCESS;
	
	-- Registrar barramento de 8 bits do sinal de entrada vindo do AD
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
			    sinal_ad_reg(7 downto 0) <= sinal_in(7 downto 0);
				delay_chain(0) <= sinal_ad_reg;
				delay_chain(number_of_coefs-1 downto 1) <= delay_chain(number_of_coefs-2 downto 0);
				
				sum_int := (OTHERS => '0');
				
				LOOP1 : FOR i IN 0 TO number_of_coefs-1 LOOP
					result_mult(i) <= delay_chain(i) * coefs(i); -- realização das multiplicações
					
					temp(19 downto 0) := result_mult(i);
					temp(21 downto 20) := (OTHERS => result_mult(i)(19));
					
					sum_int := sum_int + temp;--realização das somas
					
					
				END LOOP;
				
				result_sum <= sum_int;
	
				--sinal_ou(7)<= NOT result_sum(18);                --saida para sintese
                --sinal_ou(6 downto 0) <= result_sum(17 downto 11); -- o conversor D/A possui o bit mais significativo invertido				
				sinal_ou(7 downto 0) <= result_sum(18 downto 11);--saida para simulacao
				
	
				
			END IF;
		END IF;
	END PROCESS;
	
END rtl;