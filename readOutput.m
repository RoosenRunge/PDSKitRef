fid = fopen('ouputSignal.dat','r');
c = fscanf(fid, '%d ', [1 inf]);

%%Lê os dados do arquivo ouputSignal.dat que foram armazenados no formato de 8 bits.

fid =fopen('inputSignal.dat','r');
%gera o vetor 'c' a partir da leitura(fscanf) do arquivo fid, 
%%dados lidos do formato 'string", e convertido em um vetor de 8 colunas
%% e comprimento até o final do arquivo (inf). count retorna o comprimento do vetor.

[c1,count] = fscanf(fid,'%s' , [8, inf]   );
c1 =c1';%% é necessário transpor

%Plota os graficos do sinal de entrada fornecido para a simulação
%e do sinal de saida obtido após a simulação

figure(1);
subplot(2,1,1);
plot(bin2dec(c1)/220);
%plot(bin2dec(c1));
grid on
%%plot(x);
ylabel(' normalized input FIR');

%subplot(1,3,2);
%stem(c);
%title('saída amostrada FIR');

subplot(2,1,2);
%figure(2);
plot(c/50+0.5);
%plot(c);
grid on
ylabel('normalized output FIR');
