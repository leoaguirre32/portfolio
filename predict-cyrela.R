#AGUAS-CLARAS

mod1<-glm(valor ~ quartos + suites + garagens + m2 + factor(bairro),
          data=subset(apto,subset=(nome_cidade=="AGUAS-CLARAS")),family=Gamma(link="log"))
summary(mod1)
NagelkerkeR2(mod1)
anova(mod1,test="Chisq")
exp(coef(mod1))
exp(confint(mod1))
par(mfrow=c(3,2))

sub<-subset(apto,subset=(nome_cidade=="AGUAS-CLARAS"))
fit.model<-mod1
attach(sub)
source(file="envel_gama.R")
detach(sub)

# ...

ggplot(a, aes(regiao,parametro)) + geom_tile(aes(fill = (exp(estimativa)-1)*100), colour = "white") + 
  scale_fill_gradient(low = "white",high = rgb(243,94,90,maxColorValue=255)) + labs(x=NULL,y=NULL) +
  opts(legend.position="none") +
  geom_text(data=a,aes(x=regiao,y=parametro,label=as.character(round((exp(estimativa)-1)*100,1))),
            vjust=0.45,hjust=.45,col=rgb(.3,.3,.3)) +
              scale_y_discrete(labels=c("Nº Quartos","Nº Suítes","Nº Garagens","Área Útil (m2)")) +
              scale_x_discrete(labels=c("Águas Claras","Brasília","Guará","Taguatinga","Cruzeiro","Samambaia"))

