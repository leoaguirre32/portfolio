data doutor_lattes; set lattes.pesquisador(where=(DSC_NIVEL_FORM="Doutorado")); run;
data doutor_lattes; set doutor_lattes(keep=nme_rh COD_SEXO ANO_OBTEN_FORM NRO_ID_CNPQ);
nome=compress(nme_rh,"()[]{}+-,/._%&=ß><;:?*®$#@!'`¥^~£¢¨π≤≥|\");
nome=upcase(translate(lowcase(nome),"aaaaaaeeeeiiiioooooouuuuyyc","·‚„‡‰™ÈÍËÎÌÏÔÓÛÚÙıˆ∫˙˘˚¸˝ˇÁ"));
run;
data a; set cnpq.formacao(keep= NRO_ID_CNPQ nme_inst DSC_NIVEL_FORM where=(DSC_NIVEL_FORM="Doutorado")); run;
proc sort data=doutor_lattes;  by NRO_ID_CNPQ; run;
proc sort data=a;  by NRO_ID_CNPQ; run;
data doutor_lattes; merge doutor_lattes(in=a) a(keep=NRO_ID_CNPQ nme_inst); if a; by NRO_ID_CNPQ; run;
proc sort data=doutor_lattes nodupkey; by nme_rh cod_sexo ANO_OBTEN_FORM nome NME_INST; run;

data dados_pesq; set lattes2.dados_gerais(keep=cpf NOME_COMPLETO DATA_NASCIMENTO empresa nome_unidade nome_orgao UF_EMPRESA);
nome=compress(NOME_COMPLETO,"()[]{}+-,/._%&=ß><;:?*®$#@!'`¥^~£¢¨π≤≥|\");
nome=upcase(translate(lowcase(nome),"aaaaaaeeeeiiiioooooouuuuyyc","·‚„‡‰™ÈÍËÎÌÏÔÓÛÚÙıˆ∫˙˘˚¸˝ˇÁ"));
run;

data c; merge fundos.Projeto_fs_caracpesq(keep=int_idaprojeto nome_pesquisador) 
fundos.projeto_fs_caracproj(keep=int_idaprojeto dte_inicio dte_termino valor_contratado fundo); by int_idaprojeto; run;
data c; set c;
ano_inicio=1*(substr(dte_inicio,2,4));
ano_termino=1*(substr(dte_termino,2,4));
run;
data c; set c;
nome=compress(nome_pesquisador,"()[]{}+-,/._%&=ß><;:?*®$#@!'`¥^~£¢¨π≤≥|\");
nome=compress(upcase(translate(lowcase(nome),"aaaaaaeeeeiiiioooooouuuuyyc","·‚„‡‰™ÈÍËÎÌÏÔÓÛÚÙıˆ∫˙˘˚¸˝ˇÁ")));
run;
proc sort data=c(where=(nome ne "")) out=xxx(keep=nome fundo ano_inicio ano_termino) nodupkey; by nome fundo ano_inicio ano_termino; run;
data xxx; set xxx; t=sum(ano_termino,-ano_inicio); run;

data xxx; set xxx;
if ano_inicio<=2000<=ano_termino then d2000=1; else d2000=0;
if ano_inicio<=2001<=ano_termino then d2001=1; else d2001=0;
if ano_inicio<=2002<=ano_termino then d2002=1; else d2002=0;
if ano_inicio<=2003<=ano_termino then d2003=1; else d2003=0;
if ano_inicio<=2004<=ano_termino then d2004=1; else d2004=0;
if ano_inicio<=2005<=ano_termino then d2005=1; else d2005=0;
if ano_inicio<=2006<=ano_termino then d2006=1; else d2006=0;
if ano_inicio<=2007<=ano_termino then d2007=1; else d2007=0;
if ano_inicio<=2008<=ano_termino then d2008=1; else d2008=0;
run;

proc means data=xxx(drop=t ano_inicio ano_termino) noprint nway;
class nome fundo;
output out=soma(drop=_type_ _freq_) sum()=;
run;
proc freq data=xxx noprint; table fundo / out=lista_fundos; run;
data _null_; set lista_fundos; 
call symput('fundo'||trim(left(_n_)),fundo);
run;
%macro a;
%do ano=2000 %to 2008;
data soma&ano; set soma(keep=d&ano fundo nome);run;
%macro x;
data soma&ano; set soma&ano(where=(d&ano>=1));
%do i=1 %to 21;
if fundo="&&fundo&i" and d&ano>=1 then d_&i=1; else d_&i=0;
drop d&ano;%end;run;
proc means data=soma&ano noprint nway; class nome; output out=s&ano(drop=_type_ _freq_) sum()=;run;
data s&ano; set s&ano;ano=&ano;run;
%mend x; %x;%end;%mend a; %a;

data final; set s2000 s2001 s2002 s2003 s2004 s2005 s2006 s2007 s2008; run;
proc sort data= final; by nome ano; run;

proc sql; create table pesq_cenpes as select distinct nome_correto as nome, 1 as cenpes from cenpes.pesquisador; quit;

proc sql; create table temp as select distinct CPF from dados_pesq order by cpf; quit;
data anos; set temp;
do ano=2000 to 2008;
output;end;
run;

data publica; merge lattes2.artigo_final (in=a) lattes2.cpf; if a; by id; run;
data publica; set publica; ano2=ano*1; drop ano; rename ano2=ano; if ano<2000 or ano>2008 then delete;run;
proc sort data=publica; by cpf ano; run;
data publica; set publica(where=(cpf ne "")); run;
data publica; merge anos publica; by cpf ano; run;
data publica; set publica(drop=id); 
if artigo_nacional=. then artigo_nacional=0;
if artigo_internac=. then artigo_internac=0;
if livro_nacional=. then livro_nacional=0;
if livro_internac=. then livro_internac=0;
run;

proc sort data=doutor_lattes; by nome descending ANO_OBTEN_FORM; run;
proc sort data=doutor_lattes nodupkey; by nome; run;

data doutor_lattes; set doutor_lattes; nome2=compress(nome); run;
data final; set final; nome2=compress(nome); run;
data pesq_cenpes; set pesq_cenpes; nome2=compress(nome); run;
data dados_pesq; set dados_pesq; nome2=compress(nome); run;

proc sort data=dados_pesq; by nome2; run;
proc sort data=doutor_lattes; by nome2; run;
data doutor_lattes; merge doutor_lattes(in=a) dados_pesq(in=b); by nome2; if a and b; run;

proc sort data=doutor_lattes; by cpf; run;
proc sort data=publica; by cpf ano; run;
data doutor_lattes; merge doutor_lattes(in=a) publica; by cpf; if a; run;
data doutor_lattes; set doutor_lattes(where=(cpf ne ""));run;

proc sort data=doutor_lattes; by nome2 ano; run;
proc sort data=final; by nome2 ano; run;
data doutor_lattes; merge doutor_lattes (in=a) final; by nome2 ano; if a; run;

proc sort data=pesq_cenpes; by nome2; run;
data doutor_lattes; merge doutor_lattes (in=a) pesq_cenpes(keep=nome2 cenpes); by nome2; if a; run;

%macro x;
data doutor_lattes; set doutor_lattes; if cenpes=. then cenpes=0;
%do i=1 %to 21;
if d_&i=. then d_&i=0;
%end; run;
%mend x; %x;

data doutor_lattes; retain NRO_ID_CNPQ NME_RH nome2 cpf ano COD_SEXO; set doutor_lattes(drop=nome nome_completo); run;

proc freq data=doutor_lattes noprint; table nome2 / out=temp; run;
proc sql; create table temp as
select distinct nome2, ano, count(*) as n
from doutor_lattes group by nome2,ano order by nome2,ano;
quit;
proc sort data=temp; by descending n; run;
data temp; set temp(where=(n>1));run;
proc sql; create table temp2 as select * from doutor_lattes where nome2 in (select nome2 from temp);quit;
proc sql; select count(distinct nome2) from temp; quit;

proc sql; create table sergio.doutor_sem_hom as select * from doutor_lattes where nome2 not in (select nome2 from temp);quit;
data sergio.doutor_lattes;set doutor_lattes;run;

data espelho;set sergio.Doutor_sem_hom(obs=20); run;
proc export data=espelho outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\espelho.xls"; run;

proc sql; 
select count(distinct NRO_ID_GRUPO) from cnpq.grupo; 
select count(distinct NRO_ID_GRUPO) from cnpq.linha_area; 
select count(distinct NRO_ID_GRUPO) from cnpq.Pesquisador_grupo;
quit;

proc sql;
create table cnpq_pesq as select distinct NRO_ID_CNPQ, NRO_ID_GRUPO 
from cnpq.Pesquisador_grupo group by NRO_ID_CNPQ, NRO_ID_GRUPO order by NRO_ID_CNPQ, NRO_ID_GRUPO; quit;

proc sort data=cnpq_pesq; by NRO_ID_GRUPO; run;
proc sort data=cnpq.grupo; by NRO_ID_GRUPO; run;
data cnpq_pesq; merge cnpq_pesq(in=a) cnpq.grupo(keep=NME_AREA_CONHEC NRO_ID_GRUPO); by NRO_ID_GRUPO; if a; run;

proc sql;
create table x as select distinct NRO_ID_CNPQ, NME_AREA_CONHEC, count(*) as n 
from cnpq_pesq group by NRO_ID_CNPQ, NME_AREA_CONHEC order by NRO_ID_CNPQ, NME_AREA_CONHEC; quit;

proc sort data=x; by NRO_ID_CNPQ descending n; run;
proc sort data=x nodupkey; by NRO_ID_CNPQ; run;

proc sort data=sergio.Doutor_sem_hom; by NRO_ID_CNPQ; run;

data sergio.Doutor_sem_hom; merge sergio.Doutor_sem_hom(in=a) x(drop=n); if a; by NRO_ID_CNPQ; run;

proc sql;
create table coop as select distinct NRO_ID_CNPQ, 1 as coop from cnpq_pesq where NRO_ID_GRUPO in
(select NRO_ID_GRUPO from cnpq.Grupo_empresa);
quit;

data sergio.Doutor_sem_hom; merge sergio.Doutor_sem_hom(in=a) coop; if a; by NRO_ID_CNPQ; run;

proc sql;select * from cnpq.pesquisador_grupo where NRO_ID_CNPQ="0000183606503103";quit;

data sergio.Doutor_sem_hom; set sergio.Doutor_sem_hom; if NME_AREA_CONHEC ne "" and coop=. then coop=0; run;

data sergio.Doutor_sem_hom;set sergio.Doutor_sem_hom; 
ano_nasc=1*(substr(DATA_NASCIMENTO,5,4));
if sum(d_1,d_2,d_3,d_4,d_5,d_6,d_7,d_8,d_9,d_10,d_11,d_12,d_13,d_14,d_15,d_16,d_17,d_18,d_19,d_20,d_21)=0 then trat=0;
if sum(d_1,d_2,d_3,d_4,d_5,d_6,d_7,d_8,d_9,d_10,d_11,d_12,d_13,d_14,d_15,d_16,d_17,d_18,d_19,d_20,d_21) ne 0 then trat=1;
run;

proc means data=sergio.Doutor_sem_hom noprint nway; 
class NRO_ID_CNPQ;
output out=dtrat(drop=_type_ _freq_) sum(trat)=;
run;
data dtrat; set dtrat; if trat=0 then dtrat=0; else dtrat=1; run;

proc sql;
create table controle as select NRO_ID_CNPQ, NME_AREA_CONHEC, ano_nasc, empresa from sergio.Doutor_sem_hom
where NRO_ID_CNPQ in (select NRO_ID_CNPQ from dtrat where dtrat=0); 
create table trat as select NRO_ID_CNPQ, NME_AREA_CONHEC, ano_nasc,  empresa from sergio.Doutor_sem_hom 
where NRO_ID_CNPQ in (select NRO_ID_CNPQ from dtrat where dtrat=1); 
quit;

proc sort data=trat nodupkey; by NRO_ID_CNPQ; run;
proc sort data=controle nodupkey; by NRO_ID_CNPQ; run;

data variaveis; input var $11.; cards;
NRO_ID_CNPQ
ano_nasc
; run;

data _null_; set variaveis; 
call symput('var'||trim(left(_n_)),var);
run;

data controle; set controle;
%macro a;
%do i=1 %to 2; 
rename &&var&i=contr_&&var&i; 
%end;
%mend a; %a;
run;

data trat; set trat;
%macro a;
%do i=1 %to 2; 
rename &&var&i=trat_&&var&i; 
%end;
%mend a; %a;
run;

proc sort data=trat; by NME_AREA_CONHEC empresa; run;
proc sort data=controle; by NME_AREA_CONHEC empresa; run;

proc sql;
create table match as 
select trat.*,controle.* from trat, controle
where (trat.empresa=controle.empresa and trat.NME_AREA_CONHEC=controle.NME_AREA_CONHEC); 
quit;

data match; set match;
dif=abs(sum(contr_ano_nasc,-trat_ano_nasc));
run;

data final; set match(where=(dif<=2)); if trat_NRO_ID_CNPQ=contr_NRO_ID_CNPQ then delete;run;
data final2; set final(where=(empresa ne "" and NME_AREA_CONHEC ne ""));run;
proc sql; 
select count(distinct NRO_ID_CNPQ) into:n from sergio.Doutor_sem_hom where trat=1 and NME_AREA_CONHEC ne ""; 
select count(distinct trat_NRO_ID_CNPQ) from final2 ; 
select 100*(count(distinct trat_NRO_ID_CNPQ)/&n) from final; 
quit;

proc sql;
create table a as select * from sergio.Doutor_sem_hom where (NRO_ID_CNPQ in
(select trat_NRO_ID_CNPQ as NRO_ID_CNPQ from final2)) or 
(NRO_ID_CNPQ in (select contr_NRO_ID_CNPQ as NRO_ID_CNPQ from final2));
quit;

proc sql;
create table dtrat as select distinct trat_NRO_ID_CNPQ as NRO_ID_CNPQ, 1 as dtrat from final2;
quit;

proc sort data=dtrat; by NRO_ID_CNPQ; run;
proc sort data=a; by NRO_ID_CNPQ; run;

data a; merge a(in=a) dtrat; if a; by NRO_ID_CNPQ; run;
data a; set a; if dtrat=. then dtrat=0; run;

proc sort data=final2; by trat_NRO_ID_CNPQ; run;
data teste; set final2(obs=100); by trat_NRO_ID_CNPQ;
if first.trat_NRO_ID_CNPQ then x=1;
run;
data teste;set teste;
run;

data sergio.painel_match; set a; run;
data sergio.link; set final2; run;
data exporta; set sergio.painel_match(drop=nome2 cpf NOME_UNIDADE NOME_ORGAO NME_INST); run;

proc export data=exporta outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\painel_match.csv"; run;

proc export data=final2(obs=27) outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\teste.xls"; run;

proc export data=a(drop=NME_RH nome2 cpf obs=27) outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\teste.xls"; run;

proc means data=sergio.painel_match min max; var ano_nasc; run;

data sergio.painel_match; set sergio.painel_match;
total_artigo=sum(artigo_nacional,artigo_internac);
if ano_nasc<=1949 then cohort=1;
if 1950<=ano_nasc<=1959 then cohort=2;
if 1960<=ano_nasc<=1969 then cohort=3;
if 1970<=ano_nasc<=1979 then cohort=4;
if 1980<=ano_nasc<=1989 then cohort=5;
run;

proc sort data=sergio.painel_match; by NRO_ID_CNPQ; run; 
data sergio.painel_match; set sergio.painel_match;by NRO_ID_CNPQ; if first.NRO_ID_CNPQ then x=1; run;

data exporta; set sergio.painel_match(drop=nome2 NME_RH cpf NME_INST); rename NRO_ID_CNPQ=id; run;

data exporta2; set exporta; if _n_<=5004; run;
proc export data=exporta2 outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\amostra.csv"; run;

proc export data=lista_fundos outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\dummy_ct.xls"; run;

proc contents data=exporta short; run;



/*---------------------------------------DESCRITIVAS-------------------------------------*/
/*---------------------------------------DESCRITIVAS-------------------------------------*/
/*---------------------------------------DESCRITIVAS-------------------------------------*/
/*---------------------------------------DESCRITIVAS-------------------------------------*/
/*---------------------------------------DESCRITIVAS-------------------------------------*/

proc means data=sergio.painel_match sum maxdec=0; var d_:; run; 
proc means data=sergio.painel_match sum maxdec=0; var d_:; where dtrat=1;run; 
proc means data=sergio.painel_match sum maxdec=0; var d_:; where dtrat=0;run; 

proc means data=sergio.painel_match noprint nway; 
class UF_EMPRESA ;
output out=uf(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class UF_EMPRESA;
output out=uf2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class UF_EMPRESA;
output out=uf3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data uf; merge uf uf2 uf3; by UF_EMPRESA; run;
proc export data=uf outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class EMPRESA ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class EMPRESA;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class EMPRESA;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data empresa; merge tab tab2 tab3; by EMPRESA; run;
proc export data=empresa outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class nme_inst ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class nme_inst;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class nme_inst;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data nme_inst; merge tab tab2 tab3; by nme_inst; run;
proc export data=nme_inst outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class NME_AREA_CONHEC ;
output out=tab(drop=_type_ _freq_) sum(x)=qtd_geral mean(total_artigo)=media_artigo_geral std(total_artigo)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab2(drop=_type_ _freq_) sum(x)=qtd_controle  mean(total_artigo)=media_artigo_controle std(total_artigo)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab3(drop=_type_ _freq_) sum(x)=qtd_tratamento  mean(total_artigo)=media_artigo_tratamento std(total_artigo)=std_artigo_tratamento;
run; 
data AREA_CONHEC; merge tab tab2 tab3; by NME_AREA_CONHEC; run;
proc export data=AREA_CONHEC outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class NME_AREA_CONHEC ;
output out=tab(drop=_type_ _freq_) sum(x)=qtd_geral mean(artigo_nacional)=media_artigo_geral std(artigo_nacional)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab2(drop=_type_ _freq_) sum(x)=qtd_controle  mean(artigo_nacional)=media_artigo_controle std(artigo_nacional)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab3(drop=_type_ _freq_) sum(x)=qtd_tratamento  mean(artigo_nacional)=media_artigo_tratamento std(artigo_nacional)=std_artigo_tratamento;
run; 
data AREA_CONHEC_artigo_nac; merge tab tab2 tab3; by NME_AREA_CONHEC; run;
proc export data=AREA_CONHEC_artigo_nac outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class NME_AREA_CONHEC ;
output out=tab(drop=_type_ _freq_) sum(x)=qtd_geral mean(artigo_internac)=media_artigo_geral std(artigo_internac)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab2(drop=_type_ _freq_) sum(x)=qtd_controle  mean(artigo_internac)=media_artigo_controle std(artigo_internac)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class NME_AREA_CONHEC;
output out=tab3(drop=_type_ _freq_) sum(x)=qtd_tratamento  mean(artigo_internac)=media_artigo_tratamento std(artigo_internac)=std_artigo_tratamento;
run; 
data AREA_CONHEC_artigo_internac; merge tab tab2 tab3; by NME_AREA_CONHEC; run;
proc export data=AREA_CONHEC_artigo_internac outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class ano_nasc ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class ano_nasc;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class ano_nasc;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data ano_nasc; merge tab tab2 tab3; by ano_nasc; run;
proc export data=ano_nasc outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class cohort ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class cohort;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class cohort;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data cohort; merge tab tab2 tab3; by cohort; run;
proc export data=cohort outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class cohort ;
output out=tab(drop=_type_ _freq_) sum(x)=qtd_geral mean(total_artigo)=media_artigo_geral std(total_artigo)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class cohort;
output out=tab2(drop=_type_ _freq_) sum(x)=qtd_controle  mean(total_artigo)=media_artigo_controle std(total_artigo)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class cohort;
output out=tab3(drop=_type_ _freq_) sum(x)=qtd_tratamento  mean(total_artigo)=media_artigo_tratamento std(total_artigo)=std_artigo_tratamento;
run; 
data cohort_artigos; merge tab tab2 tab3; by cohort; run;
proc export data=cohort_artigos outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class COD_SEXO ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class COD_SEXO;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class COD_SEXO;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data SEXO; merge tab tab2 tab3; by COD_SEXO; run;
proc export data=SEXO outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class COD_SEXO ;
output out=tab(drop=_type_ _freq_) sum(x)=qtd_geral mean(total_artigo)=media_artigo_geral std(total_artigo)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class COD_SEXO;
output out=tab2(drop=_type_ _freq_) sum(x)=qtd_controle  mean(total_artigo)=media_artigo_controle std(total_artigo)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class COD_SEXO;
output out=tab3(drop=_type_ _freq_) sum(x)=qtd_tratamento  mean(total_artigo)=media_artigo_tratamento std(total_artigo)=std_artigo_tratamento;
run; 
data sexo_artigos; merge tab tab2 tab3; by COD_SEXO; run;
proc export data=sexo_artigos outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class ano ;
output out=tab(drop=_type_ _freq_) sum(total_artigo)=qtd_geral mean(total_artigo)=media_artigo_geral std(total_artigo)=std_artigo_geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class ano;
output out=tab2(drop=_type_ _freq_) sum(total_artigo)=qtd_controle  mean(total_artigo)=media_artigo_controle std(total_artigo)=std_artigo_controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class ano;
output out=tab3(drop=_type_ _freq_) sum(total_artigo)=qtd_tratamento  mean(total_artigo)=media_artigo_tratamento std(total_artigo)=std_artigo_tratamento;
run; 
data ano_artigos; merge tab tab2 tab3; by ano; run;
proc export data=ano_artigos outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;

proc means data=sergio.painel_match noprint nway; 
class coop ;
output out=tab(drop=_type_ _freq_) sum(x)=geral;
run; 
proc means data=sergio.painel_match(where=(dtrat=0)) noprint nway; 
class coop;
output out=tab2(drop=_type_ _freq_) sum(x)=controle;
run; 
proc means data=sergio.painel_match(where=(dtrat=1)) noprint nway; 
class coop;
output out=tab3(drop=_type_ _freq_) sum(x)=tratamento;
run; 
data coop; merge tab tab2 tab3; by coop; run;
proc export data=coop outfile="\\sbsb2\DPTI\Usuarios\Leonardo Aguirre\SÈrgio Kannebley\descritivas.xls"; run;
