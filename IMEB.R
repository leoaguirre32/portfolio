require(RJDBC)
require(reshape)
require(gdata)
require(ggplot2)
require(car)
require(cluster)

setwd("/Users/leonardoaguirre/Desktop/Projetos/IMEB")

rm(list=ls())
#estabelecendo a conexão
drv <- JDBC("com.microsoft.sqlserver.jdbc.SQLServerDriver","/Users/leonardoaguirre/Downloads/sqljdbc_3.0/enu/sqljdbc4.jar") 
conn <- dbConnect(drv, "jdbc:sqlserver://192.168.0.105", "username", "password")

x<-dbGetQuery(conn,"select * from imeb.dbo.exame_atendimento")

#lista de todas as tabelas no banco de dados Imeb
tabelas<- dbGetQuery(conn,"USE Imeb 
                          SELECT SchemaName = SCHEMA_NAME(schema_id), TableName = name 
                          FROM sys.objects WHERE TYPE = 'U' AND is_ms_shipped = 0")

#verificando número de observações das tabelas
for (i in 1:nrow(tabelas))  {print(paste(
  tabelas$TableName[i],dbGetQuery(conn,paste("select count(*) from",tabelas$TableName[i],sep=" "))),sep="-")}

#puxando os 300 primeiros registros de cada tabela

dados<-lapply(X=tabelas$TableName,FUN=function(x){
  dbGetQuery(conn,paste("select top 300 * from",x,sep=" "))})

#Período dados disponibilizados: 2010-01-04 a 2012-05-30

#Monta a base de exames
imeb.mulher.exame_atend<-dbGetQuery(conn,"select * from imeb.dbo.exame_atendimento where codigo_filial=5")
imeb.mulher.exame_atend<-aggregate(VALOR_TOTAL_EXAME ~ CODIGO_ATENDIMENTO + CODIGO_EXAME,FUN='sum',na.rm=T,data=imeb.mulher.exame_atend)
imeb.mulher.atend<-dbGetQuery(conn,"select * from imeb.dbo.atendimento where codigo_atendimento in 
                              (select distinct codigo_atendimento from imeb.dbo.exame_atendimento where codigo_filial=5)")
imeb.mulher.atend<-subset(imeb.mulher.atend,select=c("CODIGO_ATENDIMENTO","VALOR_BRUTO","VALOR_DESCONTO","VALOR_EXAME",
                                                     "VALOR_LIQUIDO","VALOR_FRANQUIA","VALOR_MATERIAL","VALOR_MEDICAMENTO",
                                                     "HORA","DATA_ATENDIMENTO","IDADE","VALOR_BASE_CALCULO","CODIGO_CLIENTE",
                                                     "CODIGO_USUARIO","CODIGO_SITUACAO","CODIGO_CONVENIO","CODIGO_PLANO",
                                                     "CODIGO_CID","CODIGO_CONTRATADO","CODIGO_MOTIVO","CODIGO_MEDICO_SOLICITANTE"))
# ...
x<-dbGetQuery(conn,"select * from imeb.dbo.EXAME")
y<-dbGetQuery(conn,"select * from imeb.dbo.CATEGORIA_EXAME")
z<-dbGetQuery(conn,"select * from imeb.dbo.GRUPO_EXAME")
x<-subset(x,select=c(CODIGO_EXAME,CODIGO_GRUPO_EXAME,DESCRICAO))
names(x)<-c("CODIGO_EXAME","CODIGO_GRUPO_EXAME","DESCRICAO_EXAME")
x<-merge(x,z,by="CODIGO_GRUPO_EXAME",all.x=T)
x<-merge(x,y,by="CODIGO_CATEGORIA_EXAME",all.x=T)
names(x)<-c("CODIGO_CATEGORIA_EXAME","CODIGO_GRUPO_EXAME","CODIGO_EXAME","DESCRICAO_EXAME","DESCRICAO_GRUPO_EXAME","DESCRICAO_CATEGORIA_EXAME")
imeb.mulher.atend<-merge(imeb.mulher.atend,x,by="CODIGO_EXAME",all.x=T)
rm(x,y,z)


imeb.mulher.atend<-subset(imeb.mulher.atend,select=c(-VALOR_BRUTO,-VALOR_DESCONTO,-VALOR_EXAME,-VALOR_LIQUIDO,
                                                     -VALOR_FRANQUIA,-VALOR_MATERIAL,-VALOR_MEDICAMENTO,-DATA_ATENDIMENTO,
                                                     -VALOR_BASE_CALCULO,-CODIGO_USUARIO,-CODIGO_SITUACAO,-CODIGO_CID,
                                                     -CODIGO_CONTRATADO,-CODIGO_MOTIVO,-HORA))

imeb.mulher.cliente<-dbGetQuery(conn,paste("select * from imeb.dbo.cliente where codigo_cliente in (",
                                           paste(unique(imeb.mulher.atend$CODIGO_CLIENTE), collapse = ","),")",sep=" "))
imeb.mulher.atend<-merge(imeb.mulher.atend,subset(imeb.mulher.cliente,
                         select=c(CODIGO_CLIENTE,ENDERECO,UF,CIDADE,BAIRRO,SEXO,NOME,RG_INSCRICAO,CPF_CNPJ)),by="CODIGO_CLIENTE",all.x=T)
imeb.mulher.atend$RG<-gsub(pattern="[[:alpha:][:punct:][:space:]+]","",imeb.mulher.atend$RG_INSCRICAO)
# ...

#Descritivas Clientes
summary(y$IDADE)
par(oma=c(0,0,0,0),mar=c(5,5,5,5))
hist(imeb.mulher.atend$IDADE,xlab="Idade",ylab="Número de Pacientes",main="",col=rgb(243,94,90,maxColorValue=255),nclass=40)

hist(y$IDADE,xlab="Idade",ylab="Número de Pacientes",main="",col=rgb(243,94,90,maxColorValue=255),nclass=40)
par(oma=c(0,0,0,0),mar=c(1,1,1,1))
a<-data.frame(table(imeb.mulher.atend$EXAME_AGREG)/sum(table(imeb.mulher.atend$EXAME_AGREG)))
names(a)<-c("Var1","PCT")
lab<-c("Core Biopsy","Mamografia","Mamotomia","Marcação Biópsia de Mama","Marcação Pré-Cirúrgica","Outros")
lab <- paste(lab, "\n", round(100*a$PCT,1), "%",sep="")
cor<-c(rgb(166, 206, 227,maxColorValue=255),rgb(31, 120, 180,maxColorValue=255),rgb(178, 223, 138,maxColorValue=255),
       rgb(51, 160, 44,maxColorValue=255),rgb(251, 154, 153,maxColorValue=255),rgb(227, 26, 28,maxColorValue=255))
pie(a$PCT,labels=lab,col=cor)


table(imeb.mulher.atend$ESPECIALIDADE_MEDICA_AGREG)/sum(table(imeb.mulher.atend$ESPECIALIDADE_MEDICA_AGREG))

a<-aggregate(VALOR_TOTAL_EXAME ~ EXAME_AGREG,FUN="sum",data=imeb.mulher.atend)
a$perc<-a$VALOR_TOTAL_EXAME/sum(imeb.mulher.atend$VALOR_TOTAL_EXAME)
names(a)<-c("Var1","VALOR_TOTAL_EXAME","PCT")
lab<-c("Core Biopsy","Mamografia","Mamotomia","Marcação Biópsia de Mama","Marcação Pré-Cirúrgica","Outros")
lab <- paste(lab, "\n", round(100*a$PCT,1), "%",sep="")
cor<-c(rgb(166, 206, 227,maxColorValue=255),rgb(31, 120, 180,maxColorValue=255),rgb(178, 223, 138,maxColorValue=255),
       rgb(51, 160, 44,maxColorValue=255),rgb(251, 154, 153,maxColorValue=255),rgb(227, 26, 28,maxColorValue=255))
pie(a$PCT,labels=lab,col=cor)


fatura_hora<-aggregate(VALOR_TOTAL_EXAME ~ CONVENIO_PARTICULAR + hora_agreg,FUN='length',data=imeb.mulher.atend)
ggplot(fatura_hora, aes(hora_agreg, weight=VALOR_TOTAL_EXAME,fill=CONVENIO_PARTICULAR)) + labs(y="Número de Exames / Procedimentos",x="Hora") +
  geom_bar(position="dodge",binwidth = 0.5) + scale_fill_hue(name="", breaks=c("C", "P"),labels=c("Convênio", "Particular")) +
  scale_x_continuous(limits=c(6,20),breaks=6:20)

fatura_dia_hora<-aggregate(CODIGO_ATENDIMENTO ~ hora_agreg3 + dia_semana,FUN='length',data=imeb.mulher.atend)

ggplot(fatura_dia_hora, aes(dia_semana,hora_agreg3)) + geom_tile(aes(fill = CODIGO_ATENDIMENTO), colour = "white") + 
  scale_fill_gradient(low = "white",high = rgb(243,94,90,maxColorValue=255)) + labs(x=NULL,y="Hora") + coord_flip() +
  scale_x_discrete(label=c("Segunda","Terça","Quarta","Quinta","Sexta","Sábado")) +
  opts(legend.position="none")



# Análise de clusters
mydata<-subset(final,select=c(IDADE,VALOR_TOTAL_EXAME,d_gine,d_masto,d_outros,d_particular,d_mamografia,
                          d_biopsy,d_mamotomia,d_marc_bm,d_marc_pc,d_outros2))

#selecionando número de clusters
for (i in 2:7) {teste<-pam(mydata,k=i)
                 print(i)
                 print(teste$silinfo$avg.width)}


teste<-pam(mydata,k=3)
teste$silinfo

y<-cbind(final,teste$clustering)
names(y)[16]<-"cluster"
#plot(silhouette(teste), col = c("red", "green", "blue","grey"))
#teste$silinfo
y$cluster<-as.factor(recode(y$cluster,"'1'='Grupo 1';'2'='Grupo 3';'3'='Grupo 2'"))
                                              
aggregate(. ~ cluster,FUN="mean",data=y[,3:16],na.rm=T)
aggregate(VALOR_TOTAL_EXAME ~ cluster,FUN="length",data=y)
aggregate(VALOR_TOTAL_EXAME ~ cluster,FUN="sum",data=y)

medias<-t(aggregate(. ~ cluster,FUN="mean",data=y[,3:16],na.rm=T))

write.csv2(medias,file="clusters_clientes.csv")
