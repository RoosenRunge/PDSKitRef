clear all;
N = 450;
w1=0.00869565217391304347826086956522*pi; %frequencia do primeiro ton
w2= 0.08695652173913043478260869565217*pi; %frequencia do segundo ton

fid = fopen('inputSignal.dat', 'w'); %cria o arquivo inputSignal.m

for n=1:N
  temp = round((2^7*0.5*(0.8*sin(w1*n)+0.25*sin(w2*n)))+2^7+1); %%cria uma soma de senos com w1 e w2
                                                                %%normalizado entre 0 até 255.
                                                                %%correspondendo aos niveis do 
                                                                %%conversor AD de 8 bits
  saida = dec2bin(temp,8); % converte para uma palavra binaria de 8 bits
  fprintf(fid,'%s\r\n', saida); % escreve no arquivo inputSignal.dat 
  x(n) = temp/256;
end  
fclose(fid);  

%gera o grafico da entrada para visualização no Octave
figure 1;
plot(x)
grid on

