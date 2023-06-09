#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

prefix <- "/data/projects/phillippy/projects/MetaMap/tmp/hmp7_2_miniSeq+H"
minimumPlotFreq <- 0.001

if(length(args) > 0)
{
	prefix <- args[[1]]
}

if(length(args) > 1)
{
	minimumPlotFreq <- args[[2]]
}
minimumPlotFreq <-as.numeric(minimumPlotFreq)
sample<-gsub("_classification_results","",prefix)
readtotal<-scan(paste(prefix, ".total_reads", sep = ""))



data_LandI <- read.delim(paste(prefix, ".EM.lengthAndIdentitiesPerMappingUnit", sep = ""))
data_LandI <- data_LandI[data_LandI[["AnalysisLevel"]] == "EqualCoverageUnit",]

data_coverage <- read.delim(paste(prefix, ".EM.contigCoverage", sep = ""))

countsPerUnit <- table(data_LandI[["ID"]])
countsPerUnit <- sort(countsPerUnit, d = T)
freqPerUnit <- countsPerUnit/sum(countsPerUnit)
freqTotalPerUnit <- countsPerUnit/readtotal

fn_output <- paste(prefix, '.identitiesAndCoverage.pdf', sep = "")
fn_output_coveragePlots <- paste(prefix, '.coveragePerContig_MetaMapComplete.pdf', sep = "")

plotLabels <- c()
identities_per_label <- list()
lengths_per_label <- list()
plotTaxonIDs <- list()
taxonID_2_mappingUnits <- list()
final_report <- list()
final_report<-list(Sample=vector("character",length(countsPerUnit)),Accession=vector("character",length(countsPerUnit)),TaxID=vector("character",length(countsPerUnit)), 
                   VirusName=vector("character",length(countsPerUnit)), MappedReads=vector("numeric",length(countsPerUnit)), 
                   FractionMappedReads=vector("numeric", length(countsPerUnit)), Abundance=vector("numeric",length(countsPerUnit)),
                   GenomeCoverage=vector("numeric", length(countsPerUnit)), DepthAverage=vector("numeric", length(countsPerUnit)), 
                   MedianReadIdentities=vector("numeric", length(countsPerUnit)), MeanReadLength=vector("numeric", length(countsPerUnit)))

final_report$Sample<-rep(sample,length(countsPerUnit))

TaxIDvec<-vector()
Chromvec<-vector()
for(i in 1:length(countsPerUnit)){
  iLabel <- names(countsPerUnit)[[i]]
  if(!(length(regmatches(iLabel, regexec("kraken:taxid\\|(x?\\d+)\\|", iLabel))[[1]]) == 2)){
    cat("Can't match ", iLabel, "\n")
  }
  taxonID <- regmatches(iLabel, regexec("kraken:taxid\\|(x?\\d+)\\|", iLabel))[[1]][[2]]
  chromosomeID <-regmatches(iLabel, regexec(".*\\|([^|]+)$", iLabel))[[1]][[2]]
  TaxIDvec<-c(TaxIDvec,taxonID) #Antonio
  Chromvec<-c(Chromvec,chromosomeID) #Antonio
}
final_report$TaxID<-TaxIDvec
final_report$Accession<-Chromvec

ViNameVec<-vector()
depthAveVec<-vector()
covgenVec<-vector()
wholeIdenVec<-vector()
wholeLenVec<-vector()

for(i in 1:length(countsPerUnit)){
  indices_coverage_taxonID <- which( data_coverage[["taxonID"]] == final_report$TaxID[i])
  stopifnot(length(indices_coverage_taxonID) > 0)
  taxonLabel <- as.character(data_coverage[["equalCoverageUnitLabel"]][[indices_coverage_taxonID[[1]]]])
  ViNameVec<-c(ViNameVec,taxonLabel)
  regionCover<-0
  
  covVec<-vector()
  for(j in 1:length(indices_coverage_taxonID)){
    covj<-as.numeric(data_coverage[["readCoverage"]][[indices_coverage_taxonID[[j]]]])
    covVec<-c(covVec,covj)
    
    if(as.numeric(data_coverage[["nBases"]][[indices_coverage_taxonID[[j]]]])!=0){
      regionCover<-regionCover+1
    }
  }
  wholeCov<-100*(regionCover/length(indices_coverage_taxonID))
  covgenVec<-c(covgenVec,wholeCov)
  covAve<-mean(covVec)
  depthAveVec<-c(depthAveVec,covAve)
  
  indice_identity_taxonID <- which(data_LandI[["ID"]] == names(countsPerUnit)[i])
  stopifnot(length(indice_identity_taxonID) > 0)
  readlenvec<-vector()
  readidenvec<-vector()
  for(z in 1:length(indice_identity_taxonID)){
    idenR<-as.numeric(data_LandI[["Identity"]][[indice_identity_taxonID[[z]]]])
    lenR<-as.numeric(data_LandI[["Length"]][[indice_identity_taxonID[[z]]]])
    readlenvec<-c(readlenvec,lenR)
    readidenvec<-c(readidenvec,idenR)
    }
  wholeIdenVec<-c(wholeIdenVec,median(readidenvec))
  wholeLenVec<-c(wholeLenVec,mean(readlenvec))
  
}
final_report$VirusName<-ViNameVec
final_report$DepthAverage<-depthAveVec
final_report$GenomeCoverage<-covgenVec
final_report$MedianReadIdentities<-wholeIdenVec
final_report$MeanReadLength<-wholeLenVec

final_report$MappedReads<-as.vector(countsPerUnit)
final_report$FractionMappedReads<-as.vector((100*freqTotalPerUnit))
final_report$Abundance<-as.vector((100*freqPerUnit))

final_report_df<-as.data.frame(final_report)
final_report_df_ft <- final_report_df[final_report_df[["FractionMappedReads"]]>=(minimumPlotFreq*100),]

#write.table(as.data.frame(final_report), file = paste(prefix, '.final_report.tsv', sep = ""), sep = "\t") 
write.table(final_report_df_ft, file = paste(prefix, '.final_report.tsv', sep = ""), sep = "\t") 

if(dim(final_report_df[(final_report_df[["MedianReadIdentities"]]>=0.8 & final_report_df[["GenomeCoverage"]]>=50 & final_report_df[["MeanReadLength"]]>=500),])[1]>0){
  denovo<-"no"
}else{
  denovo<-"yes"
}
write(x = denovo,file = paste(prefix, '.denovo.txt', sep = ""))

##Remember before to write into file final_report, convert it to dataframe (e.g.: as.data.frame(final_report))
for(i in 1:length(countsPerUnit))
{
	iLabel <- names(countsPerUnit)[[i]]
	iCount <- countsPerUnit[[i]]
	iFreq <- freqPerUnit[[i]]
	if(iFreq >= minimumPlotFreq)
	{
		if(!(length(regmatches(iLabel, regexec("kraken:taxid\\|(x?\\d+)\\|", iLabel))[[1]]) == 2))
		{
			cat("Can't match ", iLabel, "\n")
		}
		stopifnot(length(regmatches(iLabel, regexec("kraken:taxid\\|(x?\\d+)\\|", iLabel))[[1]]) == 2)
		taxonID <- regmatches(iLabel, regexec("kraken:taxid\\|(x?\\d+)\\|", iLabel))[[1]][[2]]
		plotTaxonIDs[[taxonID]] <- 1
		
		if(!(taxonID %in% names(taxonID_2_mappingUnits)))
		{
			taxonID_2_mappingUnits[[taxonID]] <- list()
		}
		taxonID_2_mappingUnits[[taxonID]][[iLabel]] <- 1
		
		#iIdentities <- data_LandI[["Identity"]][data_LandI[["ID"]] == iLabel]
		#iLengths <- data_LandI[["Length"]][data_LandI[["ID"]] == iLabel]
		#identities_per_label[[iLabel]] <- iIdentities
		#lengths_per_label[[iLabel]] <- iLengths
		#plotLabels <- c(plotLabels, iLabel)
	}
}
# pdf(fn_output_coveragePlots, width = 15, height = 5)
# for(taxonID in names(plotTaxonIDs))
# {

# }
# dev.off()



pdf(fn_output, width = 12, height = 8)
#par(mfrow=c(1,3),oma=c(0,0,2,0))
par(mar = c(5, 3, 5, 3), oma = c(0,0,2,0))
m <- rbind(c(1,2,3), c(4, 4, 4))
layout(m)

allIdentityDensities <- c()
allIdentity_min_not0 <- c()
for(doWhat in c("limits", "plot"))
{
	for(taxonID in names(plotTaxonIDs))
	{
		indices_coverage_taxonID <- which( data_coverage[["taxonID"]] == taxonID )
		stopifnot(length(indices_coverage_taxonID) > 0)
		
		taxonLabel <- as.character(data_coverage[["equalCoverageUnitLabel"]][[indices_coverage_taxonID[[1]]]])
				reads_count <- 0
		allReads_lengths <- c()
		allReads_identities <- c()
		allWindows_coverages <- c()
		for(mappingUnit in names(taxonID_2_mappingUnits[[taxonID]]))
		{	
			reads_count <- reads_count + countsPerUnit[[mappingUnit]]
			coverage_indices_mappingUnit <- which(data_coverage[["contigID"]] == mappingUnit)
			stopifnot(length(coverage_indices_mappingUnit) > 0)
			allWindows_coverages <- c(allWindows_coverages, data_coverage[["readCoverage"]][coverage_indices_mappingUnit])
			
			LandI_indices_mappingUnit <- which(data_LandI[["ID"]] == mappingUnit)
			stopifnot(length(LandI_indices_mappingUnit) > 0)		
			
			allReads_lengths <- c(allReads_lengths, data_LandI[["Length"]][LandI_indices_mappingUnit])
			allReads_identities <- c(allReads_identities, data_LandI[["Identity"]][LandI_indices_mappingUnit])
			
		}
		stopifnot(length(allReads_lengths) == reads_count)
		
		if(doWhat == "plot")
		{
			histogram_length <- hist(allReads_lengths, plot = F)
			plot(histogram_length, main = "Read length histogram", xlim = c(0, max(data_LandI[["Length"]])), xlab = "Read length")
		}
		
		# min_identity <- 
		vector_identities <- rep(0, 101)
		names(vector_identities) <- 0:100	
		allReads_identities_100 <- round(allReads_identities*100)+1
		identitiesTable <- table(allReads_identities_100)
		identitiesTable <- identitiesTable/sum(identitiesTable)
		for(idt in names(identitiesTable))
		{
			vector_identities[[as.integer(idt)]] <- identitiesTable[[idt]]		
		}	
		
		if(doWhat == "plot")
		{
			barplot(vector_identities[min(allIdentity_min_not0):length(vector_identities)], xlab = "Identity", ylab = "Density", main = paste("Read identities"), ylim = c(0, max(allIdentityDensities)))		
			histogram_coverage <- hist(allWindows_coverages, plot = F)	
			plot(histogram_coverage, main = "Genome window coverage histogram", xlab = "Coverage")
			title(paste("MetaMaps mapping summary for ", taxonLabel, " (taxon ID ", taxonID, ") - ", reads_count, " mapped reads assigned", sep = ""), outer=TRUE, cex.main = 1.5)			
		}
		else
		{
			allIdentityDensities <- c(allIdentityDensities, vector_identities)
			allIdentity_min_not0 <- c(allIdentity_min_not0, min(which(vector_identities != 0)))
		}
		
		if(doWhat == "plot")
		{
			indices_coverage_taxonID <- which( data_coverage[["taxonID"]] == taxonID )
			stopifnot(length(indices_coverage_taxonID) > 0)
			
			taxonLabel <- as.character(data_coverage[["equalCoverageUnitLabel"]][[indices_coverage_taxonID[[1]]]])
			
			reads_count <- 0	 
			allWindows_coverages <- c()
			allWindows_coverages_colors <- c()
			mappingUnits <- names(taxonID_2_mappingUnits[[taxonID]])	
			mappingUnits <- unique(data_coverage[["contigID"]][data_coverage[["taxonID"]] == taxonID])
			for(mappingUnitI in 1:length(mappingUnits))
			{	
				reads_count <- reads_count + countsPerUnit[[mappingUnit]]	
				mappingUnit <- mappingUnits[[mappingUnitI]]
				# reads_count <- reads_count + countsPerUnit[[mappingUnit]]
				coverage_indices_mappingUnit <- which(data_coverage[["contigID"]] == mappingUnit)
				stopifnot(length(coverage_indices_mappingUnit) > 0)
				coverages_thisMappingUnit <- data_coverage[["readCoverage"]][coverage_indices_mappingUnit]
				allWindows_coverages <- c(allWindows_coverages, coverages_thisMappingUnit)
				thisMappingUnit_color <- "blue"
				if((mappingUnitI %% 2) == 0)
				{
					thisMappingUnit_color <- "red"
				}
				allWindows_coverages_colors <- c(allWindows_coverages_colors, rep(thisMappingUnit_color, length(coverages_thisMappingUnit)))
			}
			plot(1:length(allWindows_coverages), allWindows_coverages, col = allWindows_coverages_colors, main = paste("Genome-wide coverage over all contigs for ", taxonLabel, " (taxon ID ", taxonID, ") - ", reads_count, " mapped reads assigned",  sep = ""), xlab = "Coordinate concatenated genome (1000s)", type = "b" ,ylab = "Coverage", pch = 20, cex.main = 1)		
		}
	}
}
dev.off()


cat("\nGenerated file: ", fn_output, "\n")

