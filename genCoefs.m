clear all;
%%1000 = pi !
%%%final da banda de passagem
wp = 0.026*pi;
%%%%inicio d banda de corte
ws = 0.0875*pi;
%%%%banda de transição
wt = ws - wp;
%%%%%%%%%%% CALCULANDO O COMPRIMENTO DA JANELA PARA A FUNÇÃO DE JANELAMENTO ESCOLHIDA!%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% A formula sai da tabela em função da banda de
%%%%%%%%%%% transição desejada e da função escolhida.( Aqui o numero de coeficientes está sendo denominado de M) 

wc = (ws + wp)/2;%%frequencia de corte



%kaiser param%%%%%%%%%%%%
sigma= 0.015;
A = -20*log10(sigma);
Beta = 0.1102*(A-8.7);
L = ceil((A-8)/(2.285*wt));
%%%%%%%%%%%%%%%%%%%%%%%%%

M=L-1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%função que gera filtro ideal com freq de corte wc 
%hI = sin(wc(n-alpha))/(pi(n-aplha))
%hI =  ideal_lp(wc, L);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%função que gera filtro ideal com freq de corte wc 
%hd = sen(wc(n-alpha))/(pi(n-aplha))
%basta os valores corresponde a resposta da multiplicação pela função
%janela, pois fora a janela vale 0 e consequentemente também
%h[n]=hd[n].W[n]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alpha = M/2;
n = 0:M;
m = (n - alpha)+ 1e-12;%%epsolon apenas para evitar ocorrencia de 0/0!
hI = sin(wc*m)./(pi*m);








%%transformação em passa alta%%%%%%%
%%filtro passa tudo%%%%
hdT=ideal_lp(pi, L);
%%%%%%%%%%%%%%%%%%%%subtração passa-tudo menos passa-baixa
hI=hdT-hI;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%janela utilzada com M coeficientes

%window = (rectwin(L))';
 %window = (triang(L))';
 %window = (hann(L))';
%window = (hamming(L))';
%window =(blackman(L)');
window = (kaiser(L,Beta)');
%mutiplicação no tempo (convolução na frequência) do filtro ideal com a janela de truncamento para gerar o FIR

h =hI.*window;

%[h,w] = freqz(b,a,n) calculate the frequency response.
%The frequency vector w has length n and has values ranging from 0 to ?
%radians per sample. b->polynomial numerator, a->polynomial denominator
[H, w] = freqz(h, 1, 1000);



mag = abs(H);%valor absoluto (linear)
db = 20*log10((mag + eps)/(max(mag)));%%valor relativo a banda de passagem( 0 dB) em dB.
pha = angle(H);%resposta em fase


%fator de normalização do vetor =>1000 pontos correspondem a 2*pi

delta_w = 2*pi/1000;
Rp = -(min(db(1:wp/delta_w+1)))
As = -round(max(db(ws/delta_w+1:501)))

x=0:1/1000:1-1/1000;%normalizando para 0 até 1.

figure(1)
stem(h);%%resposta impulsiva do filtro FIR
%title('Impulse Respónse')
ylabel('coefficient value','FontSize', 16)
xlabel ('n (sequence domain)','FontSize', 16)
figure(2)
plot(x,db);%%resposta em frequencia ( magnitude)
ylabel('magnitude (dB)','FontSize', 16 )
xlabel('normalized frequency','FontSize', 16)
grid on;

%gera um arquivo de saida com os valores dos coeficientes para 
%serem inseridos manualmente no codigo VHDL do filtro FIR (FirDesign.vhd)
fid = fopen('coefs.dat', 'w');

for n=1:L
  
  saida = num2str(h(n));
  fprintf(fid,'%s\r\n', saida);  
end  
fclose(fid);






