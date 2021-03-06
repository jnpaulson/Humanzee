#' Permutation-based test for per gene interaction models
#' 
#' Written for Sidneys' paper on inter-species comparsions of 
#' translation regulation. This function performs permutation of sample
#' lables across species and/or across technology type (RNA, Ribo, Protein)
#' to compute empirical p-values of interaction models.
#'
#' @param eset_full Expression set.
#' @param datatypes data types included in the analysis
#' @param permute_phenotypes phenotypes that we would like to shuffle labels between/within
#' @param n_permute number of permutation
#' @param ncores Number of cores requested.
#' 
#' @keywords Humanzee
#'
#' @export
#' @examples 
#' permute_interact_per_gene()

permute_interact_per_gene <- 

  function (eset_full, datatypes, permute_phenotype, n_permute, 
        ncores = 4) 
{
  # Set up parallel computing environment
  require(doParallel)
  registerDoParallel(cores = ncores)


  n_genes <- dim(exprs(eset_full))[1]
  order_datatypes <- match(datatypes, c("rna", "ribo", "protein"))
  exclude_datatypes <- c("rna", "ribo", "protein")[setdiff(c(1:3), 
                                                           order_datatypes)]
  eset_sub <- eset_full[, eset_full$seqData != exclude_datatypes & 
                          eset_full$species != "rhesus"]
  emat <- exprs(eset_sub)
  
  # Identify phenotype that we would to shuffle the labels
  permute_phenotype_order <- which(c("seqData", "species") %in% permute_phenotype)
  permute_phenotype_order_label <- c("seqData", "species")[permute_phenotype_order]
  
  # Permute across species and sequencing data type
  if ( length(permute_phenotype_order_label) == 2)  {
      null_interact <- foreach(each_null = 1:n_permute) %dopar% {
                                n_samples_per_genes <- dim(pData(eset_sub))[1]
                                emat_per_permute <- t( sapply(1:n_genes, function(i) {
                                  sample_labels <- sample(1:n_samples_per_genes)
                                  emat[i, sample_labels]
                                } ) )
                                dimnames(emat_per_permute)[2] <- NULL
                                
                                eset_per_permute <- ExpressionSet(assayData = as.matrix(emat_per_permute))
                                phenoData(eset_per_permute) <- phenoData(eset_sub)
                                featureData(eset_per_permute) <- featureData(eset_sub)
                                return(interact2way(eset_per_permute))
      }
      return(null_interact)
  }      

  # Shuffle sample labels within each data type
  if (permute_phenotype_order_label == "seqData") {
      pheno_labels <- unique(pData(eset_sub)$seqData)
      null_interact <- foreach(each_null = 1:n_permute) %dopar% {
                                
                                n_samples_per_genes <- dim(pData(eset_sub))[1]
                                
                                # Split the data into parts for each phenotype
                                emat_1 <- emat[, pData(eset_sub)$seqData == pheno_labels[1]]
                                emat_2 <- emat[, pData(eset_sub)$seqData == pheno_labels[2]]
                                
                                # Create permuted data set
                                emat_per_permute <- t( sapply(1:n_genes, function(i) {
                                  sample_labels_1 <- sample(1: (n_samples_per_genes/2) )
                                  sample_labels_2 <- sample(1: (n_samples_per_genes/2) )
                                  cbind(emat_1[i,sample_labels_1], emat_2[i,sample_labels_2])
                                } ) )
                                dimnames(emat_per_permute)[2] <- NULL
                                
                                eset_per_permute <- ExpressionSet(assayData = as.matrix(emat_per_permute))
                                phenoData(eset_per_permute) <- phenoData(eset_sub)
                                featureData(eset_per_permute) <- featureData(eset_sub)
                                return(interact2way(eset_per_permute))
      }
      return(null_interact)
  }
  

  if (permute_phenotype_order_label == "species") {
      null_interact <- foreach(each_null = 1:n_permute) %dopar% {
        
                                n_samples_per_genes <- dim(pData(eset_sub))[1]
                                emat_chimp <- emat[, pData(eset_sub)$species == "chimp"]
                                emat_human <- emat[, pData(eset_sub)$species == "human"]
                                
                                emat_per_permute <- t( sapply(1:n_genes, function(i) {
                                  sample_labels_1 <- sample(1: (n_samples_per_genes/2) )
                                  sample_labels_2 <- sample(1: (n_samples_per_genes/2) )
                                  emat_chimp_permute <- emat_chimp[i, sample_labels_1]
                                  emat_human_permute <- emat_human[i, sample_labels_2]
                                  
                                  emat <- cbind( emat_chimp_permute[1:5], emat_human_permute[1:5],
                                                 emat_chimp_permute[6:10], emat_human_permute[6:10] )
                                  return(emat)
                                  } ) )
                                dimnames(emat_per_permute)[2] <- NULL
                                
                                eset_per_permute <- ExpressionSet(assayData = as.matrix(emat_per_permute))
                                phenoData(eset_per_permute) <- phenoData(eset_sub)
                                featureData(eset_per_permute) <- featureData(eset_sub)
                                return(interact2way(eset_per_permute))
                              }
      return(null_interact)
  }
  
}

