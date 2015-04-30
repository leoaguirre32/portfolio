require(ggplot2)

# create data
skills <- data.frame(dominio=c(1,2,3,4), 
                     linguagem=factor(
                       c("XML, PMML,\nAngularJS, SPSS,\nStata", 
                         "HTML, CSS,\nJavascript, iMacros", 
                         "SQL, Python", 
                         "R, SAS")))

# reorder factor levels
skills$linguagem <- factor(skills$linguagem, levels(skills$linguagem)[c(4,1,3,2)])

# create labels
labels <- c("", "I've been there", "Confortable", "Very\nconfortable", "Expert")

# plot data
ggplot(skills, aes(linguagem, dominio)) + geom_bar(stat="identity", fill="#008CBA") + coord_flip() +
  scale_y_discrete(labels=labels) + xlab("") + ylab("")
