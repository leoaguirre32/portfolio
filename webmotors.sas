options nonotes nosource;
libname leo "\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\Particular";
%macro marca(marca);
filename carros URL  
"http://www.webmotors.com.br/Webmotors/Compra/carrosResultado/carros-resultado.aspx?marca=&marca.%nrstr(&modelo=&descrModelo=&precoinicial=&precofinal=&uf=&cidade=&anoInicial=&anoFinal=)"
LRECL=10000;

data temp;
	infile carros dsd flowover missover TRUNCOVER;
 	input  dados $1-10000;
run;

proc sql noprint; select x into:x from leo.simbolo; quit;

data temp; set temp;
dados2=left(translate(dados,"","&x."));
drop dados;
rename dados2=dados;
run;

data npag; set temp(where=(substr(dados,1,76)='<div class="busca"><ul class="buscas"><div class="buscasTitulo"><li><strong>')); run;
data npag; set npag;
n=1*scan(left(tranwrd(dados,'<div class="busca"><ul class="buscas"><div class="buscasTitulo"><li><strong>H&#225; ',"")),1," ");
x=n/20;
y=int(x);
if x>y then pag=sum(y,1);
else pag=y;
run;
proc sql noprint; select pag into:n from npag;quit;
%put &n.;
%macro x;
%do pagina=1 %to &n.;
filename carros URL  
"http://www.webmotors.com.br/Webmotors/Compra/carrosResultado/carros-resultado.aspx?marca=&marca.%nrstr(&modelo=&descrModelo=&precoinicial=&precofinal=&uf=&cidade=&anoInicial=&anoFinal=&pagina=)&pagina."
LRECL=10000;

data temp;
	infile carros dsd flowover missover TRUNCOVER;
 	input  dados $1-10000;
run;

proc sql noprint; select x into:x from leo.simbolo; quit;


data temp; set temp;
dados2=left(translate(dados,"","&x."));
drop dados;
rename dados2=dados;
run;

data temp; set temp(where=(substr(dados,1,29) in ('<li class="list2" ><ul class=' '<li class="list3"> <ul class=' '<li class="list4"><ul class="' '<li class="list5"><ul class="'))); run;

data temp2;
length oferta $100. ano $9. portas $2. km $15. cor $12. valor $15. uf $2. marca $20. modelo $20.; set temp;
rx=rxparse("'nome'");
pos=rxmatch(rx,dados);
oferta=scan(substr(dados,pos+3,length(dados)),1,'<');
drop rx pos;
oferta=left(tranwrd(oferta,'e">',""));

rx=rxparse("'Ano:'");
pos=rxmatch(rx,dados);
ano=scan(substr(dados,pos+13,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'Portas:'");
pos=rxmatch(rx,dados);
portas=scan(substr(dados,pos+16,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'Km:'");
pos=rxmatch(rx,dados);
km=scan(substr(dados,pos+12,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'Cor:'");
pos=rxmatch(rx,dados);
cor=scan(substr(dados,pos+13,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'R$'");
pos=rxmatch(rx,dados);
valor=scan(substr(dados,pos+2,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
nome=scan(substr(dados,pos+57,length(dados)),1,'<');
drop rx pos;

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
nome2=scan(substr(dados,pos+57,length(dados)),4,'<');
drop rx pos;

nome2=left(tranwrd(nome2,"strong>",""));

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
nome4=scan(substr(dados,pos+57,length(dados)),3,'<');
drop rx pos;

nome4=left(tranwrd(nome4,"strong>",""));

if length(nome)>50 then nome3=upcase(nome2);
else nome3=upcase(nome);
if nome3="" then nome3=upcase(nome4);

drop nome nome2 nome4;
rename nome3=nome;

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
cidade1=scan(substr(dados,pos+57,length(dados)),5,'<');
drop rx pos;

cidade1=left(tranwrd(cidade1,"h5>",""));

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
cidade2=scan(substr(dados,pos+57,length(dados)),8,'<');
drop rx pos;

cidade2=left(tranwrd(cidade2,"h5>",""));

rx=rxparse("'coluna4'");
pos=rxmatch(rx,dados);
cidade3=scan(substr(dados,pos+57,length(dados)),7,'<');
drop rx pos;

cidade3=left(tranwrd(cidade3,"h5>",""));

if cidade1="/strong>" then cidade=cidade2;
else cidade=cidade1;
if cidade="/li>" then cidade=cidade3;

drop cidade1 cidade2 cidade3;

uf=left(scan(cidade,2,"-"));

rx=rxparse("'.'");
pos=rxmatch(rx,oferta);
cilindradas=1000*substr(oferta,pos-1,3);
drop rx pos;

rx=rxparse("'.'");
pos=rxmatch(rx,oferta);
modelo=substr(oferta,1,pos-2);
drop rx pos;

marca=scan(oferta,1," ");

pagina=&pagina;
drop dados;
run;

proc sql noprint; select distinct marca into:abc from temp2;quit;
data temp2;retain oferta marca modelo2 cilindradas ano cor km portas cidade uf valor nome; set temp2;
modelo2=left(tranwrd(modelo,compress("&abc."),""));
drop modelo;
rename modelo2=modelo;
run;
proc append data=temp2 base=base; run;
%put &abc &pagina;
%end;
%mend x; %x;
%mend marca; 

%marca(2);%marca(3);%marca(4);%marca(5);%marca(12);%marca(16);%marca(26);%marca(28);%marca(30);%marca(35);

data leo.webmotors2; set base; run;
