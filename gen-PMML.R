# ...
# estimates GLMs

for (i in 1:length(lista)){
  xout<-NULL
  out<-1
  sub<-subset(dados,subset=(id==lista[i]))
  quantis<-quantile(sub$Valor,probs=c(.30,.70))
  sub$padrao<-ifelse(sub$Valor<quantis[[1]],"Baixo","Médio")
  sub$padrao<-ifelse(sub$Valor>quantis[[2]],"Alto",sub$padrao)
  sub$padrao<-as.factor(sub$padrao)
  min_area[i]<-min(sub$Area)
  max_area[i]<-round(quantile(sub$Area,probs=.95),0)
  min_quartos[i]<-min(sub$quartos)
  max_quartos[i]<-round(quantile(sub$quartos,probs=.95),0)
  min_suites[i]<-min(sub$suites)
  max_suites[i]<-round(quantile(sub$suites,probs=.95),0)
  min_garagem[i]<-min(sub$garagem)
  max_garagem[i]<-round(quantile(sub$garagem,probs=.95),0)
  tabela<-data.frame(var=c("quartos","suites","garagem"),n=c(length(table(sub$quartos)),length(table(sub$suites)),length(table(sub$garagem))))
  tabela$n<-ifelse(tabela$n>1,1,0)
  while(length(out)!=0 & length(xout)<.2*nrow(subset(dados,subset=(id==lista[i])))) {
    fit.model<-try(glm(as.formula(paste("Valor ~ Area",paste(rep(tabela$var,tabela$n),collapse="+"),"Area2+padrao",sep="+")),family=Gamma(link=log),data=sub))
    if(class(fit.model)!="try-error"){
      X <- model.matrix(fit.model)
      h <- hat(X,intercept=T)
      fi <- gamma.shape(fit.model)$alpha
      td <- resid(fit.model,type="deviance")*sqrt(fi/(1-h))
      out<-NULL
      out<-subset(td,td>=2.5 | td<=-2.5 | td=="NaN")
      xout<-append(out,xout)
      sub<-subset(dados,subset=(id==lista[i]))[-((as.numeric(names(xout)))-as.numeric(row.names(subset(dados,subset=(id==lista[i])))[1])+1),]
      sub$padrao<-ifelse(sub$Valor<quantis[[1]],"Baixo","Médio")
      sub$padrao<-ifelse(sub$Valor>quantis[[2]],"Alto",sub$padrao)
      sub$padrao<-as.factor(sub$padrao)
      tabela<-data.frame(var=c("quartos","suites","garagem"),n=c(length(table(sub$quartos)),length(table(sub$suites)),length(table(sub$garagem))))
      tabela$n<-ifelse(tabela$n>1,1,0)
    }
    else{
      fit.model<-NULL
    }
  }
  if(sum(is.na(fit.model$coefficients))>0){
    fit.model<-NULL
  }
  if(!is.null(fit.model)){
    z <- predict(fit.model) + resid(fit.model, type="pearson")/sqrt(fit.model$weights)
    correl[[i]]<-cor(z,predict(fit.model))
    mod[[i]]<-fit.model
    rm(z,sub,xout,out,fit.model,tabela)
  }
  print(paste(i, " de ",length(lista),sep=""))
}


pearson<-sqrt(0.7)
# creates PMML
require(pmml)
final<-NULL
listax<-data.frame(id=lista,num=1:length(lista))
for(i in listax$num[correl>=pearson]){
  if(length(listax$num[correl>=pearson])!=0 & !is.null(mod[[i]])){
    final[[i]]<-pmml(mod[[i]])
    print(i)
  }
  else{}
}
# ...
