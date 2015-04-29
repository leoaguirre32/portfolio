# ...
#########################################################
#########################################################

##################      DBMaster       ################## 

#########################################################
#########################################################

## reads data

seg_cnae<-read.spss(file="Setores_Industriais_CNAE_Segmento.sav", use.value.labels=T, to.data.frame=T)

filtro_cnae<-unique(as.character(seg_cnae$CNAE))

## reads RAIS
rais <- read.csv.ffdf(file="RAIS_trabalhador_2013/RAIS_trabalhador_2013.csv", header=TRUE, VERBOSE=TRUE, first.rows=200000, sep=";",
                      next.rows=200000, colClasses="factor",fileEncoding="latin1")

rais <- subset(rais, select=c("MotivoDesligamento","CBOOcupação2002","FaixaEtária","Escolaridadeapós2005","MêsAdmissão",
                              "MêsDesligamento","CNAE2.0Subclasse","VínculoAtivo3113","Município"))
rais$UF_ESTAB <- ffdfwith(rais, substr(as.character(Município),1,2))

rais <- subset(rais, select=c("MotivoDesligamento","CBOOcupação2002","FaixaEtária","Escolaridadeapós2005","MêsAdmissão",
                              "MêsDesligamento","CNAE2.0Subclasse","VínculoAtivo3113","UF_ESTAB"))
save.ffdf(rais,overwrite=T)

## loads data ##
load.ffdf("/Users/leonardoaguirre/Desktop/Projetos/CNI/RAIS/ffdb")

## check data

sub <- subset(rais, VínculoAtivo3113==1)
nrow(sub)
x <- data.frame(table(sub$UF_ESTAB, sub$CNAE2.0Subclasse))
names(x) <- c("UF_ESTAB", "CNAE2.0Subclasse", "Empregados")
x$cnae2 <- substr(as.character(x$CNAE2.0Subclasse), 1, 2)

tab <- aggregate(Empregados ~ UF_ESTAB + cnae2, data=x, FUN= 'sum')

x <- ffdfdply(sub[c('UF_ESTAB', 'CNAE2.0Subclasse', 'MêsAdmissão')], 
                  split=sub$CNAE2.0Subclasse, FUN=function(data){
                    data.frame(count(data, c('UF_ESTAB', 'CNAE2.0Subclasse', 'MêsAdmissão')))})

x <- data.frame(x)
confere com numeros do MTE (captura de tela)
sum(x$freq[x$UF_ESTAB=="Ceará" & x$MêsAdmissão==12])
sum(x$freq[x$UF_ESTAB=="Distrito Federal" & x$MêsAdmissão==1])


x <- ffdfdply(rais[c('UF_ESTAB', 'CNAE2.0Subclasse', 'MêsDesligamento')], 
              split=rais$CNAE2.0Subclasse, FUN=function(data){
                data.frame(count(data, c('UF_ESTAB', 'CNAE2.0Subclasse', 'MêsDesligamento')))})

x <- data.frame(x)
confere com numeros do MTE (captura de tela)
sum(x$freq[x$UF_ESTAB=="Ceará" & x$MêsDesligamento==12])
sum(x$freq[x$UF_ESTAB=="Distrito Federal" & x$MêsDesligamento==1])



rais <- subset(rais, CNAE2.0Subclasse %in% filtro_cnae)

# admission and dismissal

sub <- subset(rais, !MêsDesligamento %in% c(0, -1))
des <- data.frame(table(sub$UF_ESTAB, sub$CNAE2.0Subclasse))
names(des) <- c("UF_ESTAB", "CNAE2.0Subclasse", "Desligados")


sub <- subset(rais, !MêsAdmissão %in% c(0, -1))
adm <- data.frame(table(sub$UF_ESTAB, sub$CNAE2.0Subclasse))
names(adm) <- c("UF_ESTAB", "CNAE2.0Subclasse", "Admitidos")

rm(sub)

Empr_t <- data.frame(table(rais$UF_ESTAB, rais$CNAE2.0Subclasse))

# filter active
rais <- subset(rais, VínculoAtivo3113==1)

## number of accidents ####
acid<-read.csv2("Acidente_Trabalho_motivo_2012.csv",header=T,fileEncoding="latin1",
                colClasses=c(rep("character",2),rep("numeric",4)))

acid$acidentes<-apply(acid[,3:6],1,sum,na.rm=T)
acid$CNAE20Classe<-substr(sprintf("%05d",as.numeric(acid$Classe.do.CNAE.2.0)),1,4)
acid<-subset(acid,select=c(-Classe.do.CNAE.2.0, -acidentes))
cod_uf<-read.csv2("cod_UF.csv",header=T,fileEncoding="utf-8",colClasses="character")

acid<-merge(acid,cod_uf,by.x="UF",by.y="SIGLA",all.x=T)
acid<-subset(acid,select=c(CÓDIGO,CNAE20Classe,Típico.Com.Cat,Trajeto.Com.Cat,Doença.do.Trabalho.Com.Cat,Sem.Cat))
names(acid)<-c("UF_ESTAB","CNAE20Classe","AcidentesComCATTipico","AcidentesComCATTrajeto",
               "AcidentesComCATDoencadoTrabalho","AcidentesSemCATRegistrada")

Empr <- data.frame(table(rais$UF_ESTAB, rais$CNAE2.0Subclasse))
names(Empr) <- c("UF_ESTAB", "CNAE2.0Subclasse", "Empregados")
Empr2<-Empr
Empr2$CNAE20Classe<-substr(Empr2$CNAE2.0Subclasse,1,4)
tot_empr <- aggregate(Empregados~UF_ESTAB + CNAE20Classe, sum, na.rm=T, data=Empr2)
tot_empr <- subset(tot_empr, Empregados>0)
acid <- merge(acid, tot_empr, by=c("UF_ESTAB","CNAE20Classe"), all.x=F, all.y=T)

acid<-merge(acid,Empr2,by=c("UF_ESTAB","CNAE20Classe"),all.x=T,all.y=F)

acid$AcidentesComCATTipico<-acid$AcidentesComCATTipico*acid$Empregados.y/acid$Empregados.x
acid$AcidentesComCATTrajeto<-acid$AcidentesComCATTrajeto*acid$Empregados.y/acid$Empregados.x
acid$AcidentesComCATDoencadoTrabalho<-acid$AcidentesComCATDoencadoTrabalho*acid$Empregados.y/acid$Empregados.x
acid$AcidentesSemCATRegistrada<-acid$AcidentesSemCATRegistrada*acid$Empregados.y/acid$Empregados.x
acid<-subset(acid,select=c(UF_ESTAB,CNAE2.0Subclasse,AcidentesComCATTipico,AcidentesComCATTrajeto,
                           AcidentesComCATDoencadoTrabalho,AcidentesSemCATRegistrada))

conseq<-read.csv2("Consequencia_Acidente_2012.csv",header=T,fileEncoding="latin1",
                  colClasses=c(rep("character",2),rep("numeric",5)))

conseq$Classes.do.CNAE.2.0 <- ifelse(conseq$Classes.do.CNAE.2.0=="Ignorado", "0000", conseq$Classes.do.CNAE.2.0)
names(conseq)[1]<-"CNAE20Classe"
conseq<-merge(conseq,cod_uf,by.x="UF",by.y="SIGLA",all.x=T)
conseq<-subset(conseq,select=c(CÓDIGO,CNAE20Classe,Assistência.Médica,Incapacidade.Menos.de.15.dias,
                               Incapacidade.Mais.de.15.dias,Incapacidade.Permanente,Óbitos))
names(conseq)<-c("UF_ESTAB","CNAE20Classe","ConseqAssistMedica","ConseqMenosde15dias",
                 "ConseqMaisde15dias","ConseqIncPermanente","ConseqObito")

conseq <- merge(conseq, tot_empr, by=c("UF_ESTAB","CNAE20Classe"), all.x=F, all.y=T)
conseq <- merge(conseq, Empr2, by=c("UF_ESTAB","CNAE20Classe"), all.x=T, all.y=F)

conseq$ConseqAssistMedica<-conseq$ConseqAssistMedica*conseq$Empregados.y/conseq$Empregados.x
conseq$ConseqMenosde15dias<-conseq$ConseqMenosde15dias*conseq$Empregados.y/conseq$Empregados.x
conseq$ConseqMaisde15dias<-conseq$ConseqMaisde15dias*conseq$Empregados.y/conseq$Empregados.x
conseq$ConseqIncPermanente<-conseq$ConseqIncPermanente*conseq$Empregados.y/conseq$Empregados.x
conseq$ConseqObito<-conseq$ConseqObito*conseq$Empregados.y/conseq$Empregados.x

conseq<-subset(conseq,select=c(UF_ESTAB,CNAE2.0Subclasse,ConseqAssistMedica,ConseqMenosde15dias,
                               ConseqMaisde15dias,ConseqIncPermanente,ConseqObito))
rm(tot_empr,Empr2)

escol <- ffdfdply(rais[c('UF_ESTAB', 'CNAE2.0Subclasse', 'Escolaridadeapós2005')], 
                  split=rais$CNAE2.0Subclasse, FUN=function(data){
                    data.frame(count(data, c('UF_ESTAB', 'CNAE2.0Subclasse', 'Escolaridadeapós2005')))})

escol <- data.frame(escol)
names(escol)[4] <- "n"
escol$Escolaridadeapós2005<-recode(as.factor(escol$Escolaridadeapós2005),recodes=c("'1'='Analfabetos';'2'='Ate5AnoIncompleto'; '3'='QuintoAnoCompleto'; '4'='Do6ao9Incompleto';
                                                                                   '5'='Fundamental';'6'='MedioIncompleto';'7'='MedioCompleto'; '8'='SuperiorIncompleto';
                                                                                   '9'='SuperiorCompleto';'10'='Mestrado';'11'='Doutorado'"))

escol<-reshape(escol,timevar=c("Escolaridadeapós2005"),direction="wide",idvar=c("UF_ESTAB","CNAE2.0Subclasse"))
escol[,3:13]<-apply(escol[,3:13],2,function(x){ifelse(is.na(x),0,x)})
names(escol)[3:13]<-gsub("n.","",names(escol)[3:13],fixed=T)

Ida <- ffdfdply(rais[c('UF_ESTAB', 'CNAE2.0Subclasse', 'FaixaEtária')], 
                  split=rais$CNAE2.0Subclasse, FUN=function(data){
                    data.frame(count(data, c('UF_ESTAB', 'CNAE2.0Subclasse', 'FaixaEtária')))})

Ida <- data.frame(Ida)
names(Ida)[4] <- "n"
Ida$FaixaEtária <- as.character(Ida$FaixaEtária)
Ida$FaixaEtária <- ifelse(Ida$FaixaEtária == "2", "1", Ida$FaixaEtária)
Ida <- aggregate(n ~ UF_ESTAB + CNAE2.0Subclasse + FaixaEtária, data=Ida, FUN="sum")
Ida$FaixaEtária<-recode(as.factor(Ida$FaixaEtária),recodes=c("'1'='Idade17';'3'='Idade18a24'; '4'='Idade25a29'; '5'='Idade30a39';
                                  '6'='Idade40a49';'7'='Idade50a64';'8'='Idade65'; '99'='Ignorados'"))

Ida<-reshape(Ida,timevar=c("FaixaEtária"),direction="wide",idvar=c("UF_ESTAB","CNAE2.0Subclasse"))
Ida[,3:10]<-apply(Ida[,3:10],2,function(x){ifelse(is.na(x),0,x)})
names(Ida)[3:10]<-gsub("n.","",names(Ida)[3:10],fixed=T)

Ocu <- ffdfdply(rais[c('UF_ESTAB', 'CNAE2.0Subclasse', 'CBOOcupação2002')], 
                split=rais$CNAE2.0Subclasse, FUN=function(data){
                  data.frame(count(data, c('UF_ESTAB', 'CNAE2.0Subclasse', 'CBOOcupação2002')))})
Ocu <- data.frame(Ocu)
names(Ocu)[4]<- "n"
#classes_cbo <- read.spss('BD_CBO_Uniepro2012.sav', use.value.labels=T, to.data.frame=T)
classes_cbo <- read.xlsx("Classificação das Ocupações_UNIEPRO_2014.09.29.xlsx", sheetIndex=1)
names(classes_cbo)[c(4,10)] <- c("CBO4", "Tipologia_OI")
classes_cbo$CBO4 <- as.character(classes_cbo$CBO4)
classes_cbo <- subset(classes_cbo, select=c(CBO4, Tipologia_OI))
classes_cbo$Tipologia_OI <- ifelse(gsub(" ", "", classes_cbo$Tipologia_OI)=="Técnicos", "Tecnicos", as.character(classes_cbo$Tipologia_OI))

Ocu$CBO4 <- substr(as.character(Ocu$CBOOcupação2002), 1, 4)
Ocu <- merge(Ocu, classes_cbo, by="CBO4", all.x=T, all.y=F)
Ocu$Tipologia_OI <- ifelse(is.na(Ocu$Tipologia_OI), "NaoEspecificado", Ocu$Tipologia_OI)

Ocu <- aggregate(n ~ UF_ESTAB + CNAE2.0Subclasse + Tipologia_OI, data=Ocu, FUN="sum")


Ocu<-reshape(Ocu,timevar=c("Tipologia_OI"),direction="wide",idvar=c("UF_ESTAB","CNAE2.0Subclasse"))
Ocu[,3:9]<-apply(Ocu[,3:9],2,function(x){ifelse(is.na(x),0,x)})
names(Ocu)[3:9]<-gsub(" ", "", gsub("n.","",names(Ocu)[3:9],fixed=T))

Ocu <- Ocu[,c("UF_ESTAB", "CNAE2.0Subclasse", "Administrativo", "Gerencial", "Qualificado", "Superior", "Supervisores", "Tecnicos", "NaoEspecificado")]

## Lê base Segmento X CNAE ####
seg_cnae <- seg_cnae[,c("CNAE","segmento1_cod","segmento2_cod","segmento3_cod")]
names(seg_cnae) <- c("CNAE2.0Subclasse","CodigoSeg1","CodigoSeg2","CodigoSeg3")
seg_cnae<- unique(seg_cnae)

DBMaster<-merge(seg_cnae,adm,by="CNAE2.0Subclasse",all.y=T, all.x=F)
DBMaster<-merge(DBMaster,des,by=c("CNAE2.0Subclasse","UF_ESTAB"),all.x=T, all.y=F)
DBMaster<-merge(DBMaster,acid,by=c("CNAE2.0Subclasse","UF_ESTAB"),all.x=T, all.y=F)
DBMaster<-merge(DBMaster,conseq,by=c("CNAE2.0Subclasse","UF_ESTAB"),all=T)
DBMaster<-merge(DBMaster,escol,by=c("CNAE2.0Subclasse","UF_ESTAB"),all=T)
DBMaster<-merge(DBMaster,Ida,by=c("CNAE2.0Subclasse","UF_ESTAB"),all=T)
DBMaster<-merge(DBMaster,Ocu,by=c("CNAE2.0Subclasse","UF_ESTAB"),all=T)
DBMaster$Dispendios <- 0
DBMaster<-merge(DBMaster,Empr,by=c("CNAE2.0Subclasse","UF_ESTAB"),all.y=T, all.x=F)
DBMaster<-merge(cod_uf,DBMaster,by.x="CÓDIGO",by.y="UF_ESTAB",all.x=F,all.y=T)
DBMaster<-subset(DBMaster,select=c(-CÓDIGO,-NOME.DO.ESTADO,-CNAE2.0Subclasse))
names(DBMaster)[1]<-"UF"
DBMaster<-aggregate(. ~ UF + CodigoSeg1 + CodigoSeg2 + CodigoSeg3, sum, na.rm=T,data=DBMaster, na.action=na.pass)

ordem <- c("UF", "CodigoSeg1", "CodigoSeg2", "CodigoSeg3", "Admitidos", "Desligados", "AcidentesComCATTipico",
           "AcidentesComCATTrajeto", "AcidentesComCATDoencadoTrabalho", "AcidentesSemCATRegistrada",
           "ConseqAssistMedica", "ConseqMenosde15dias", "ConseqMaisde15dias", "ConseqIncPermanente",
           "ConseqObito", "Analfabetos", "Ate5AnoIncompleto", "QuintoAnoCompleto", "Do6ao9Incompleto",
           "Fundamental", "MedioIncompleto", "MedioCompleto", "SuperiorIncompleto", "SuperiorCompleto",
           "Mestrado", "Doutorado", "Idade17", "Idade18a24", "Idade25a29", "Idade30a39", "Idade40a49",
           "Idade50a64", "Idade65", "Ignorados", "Administrativo", "Gerencial", "Qualificado", "Superior",
           "Supervisores", "Tecnicos", "NaoEspecificado", "Dispendios", "Empregados")
DBMaster <- DBMaster[,ordem]

DBMaster[,2:4]<-apply(DBMaster[,2:4],2,as.character)

DBMaster <- subset(DBMaster, CodigoSeg1!="9")
write.table(DBMaster, 'bases_carga/DBMaster.csv', sep=";", na="", eol="\r\n", quote=F, row.names=F, fileEncoding="latin1")

