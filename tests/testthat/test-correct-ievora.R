context("correctness of ievora")

################################################################################
############################### HELPER FUNCTIONS ###############################
################################################################################

base_ievora <- function(mat, groups, tCut=0.05, bCut=0.001) {
  if(is.vector(mat)) mat <- matrix(mat, nrow=1)

  bad <- is.na(groups)
  mat <- mat[,!bad, drop=FALSE]
  groups <- groups[!bad]

  doDV <- function(tmp.v,pheno.v) {
    co.idx <- which(pheno.v==0)
    ca.idx <- which(pheno.v==1)
    bt.o <- bartlett.test(x=tmp.v,g=pheno.v)
    pv <- bt.o$p.value
    st <- bt.o$statistic
    logR <- log2(var(tmp.v[ca.idx])/var(tmp.v[co.idx]))
    avCA <- mean(tmp.v[ca.idx])
    avCO <- mean(tmp.v[co.idx])
    out.v <- c(logR,st,pv,avCA,avCO)
    names(out.v) <- c("log(V1/V0)","Stat","P(BT)","Av1","Av0")
    return(out.v)
  }

  doTT <- function(tmp.v,pheno.v){
    tt.o <- t.test(tmp.v ~ pheno.v)
    out.v <- c(-tt.o$stat,tt.o$p.val)
    names(out.v) <- c("t","P")
    return(out.v)
  }

  m0 <- m1 <- md <- v0 <- v1 <- n0 <- n1 <- nt <- vlr <- ts <- bs <- tp <- bp <- numeric(nrow(mat))
  for(i in 1:nrow(mat)) {
    naInds <- is.na(mat[i,])
    vec <- mat[i,!naInds]
    grp <- groups[!naInds]
    statDVC <- doDV(vec, grp)
    statDMC <- doTT(vec, grp)
    m0[i] <- statDVC[5]
    m1[i] <- statDVC[4]
    md[i] <- m1[i]-m0[i]
    v0[i] <- var(vec[grp==0])
    v1[i] <- var(vec[grp==1])
    n0[i] <- sum(grp==0)
    n1[i] <- sum(grp==1)
    nt[i] <- n0[i] + n1[i]
    vlr[i] <- statDVC[1]
    ts[i]  <- statDMC[1]
    tp[i]  <- statDMC[2]
    bs[i]  <- statDVC[2]
    bp[i]  <- statDVC[3]
  }

  bq  <- p.adjust(bp, "fdr")
  sig <- bp < bCut & tp < tCut
  idx <- rank(tp[sig], ties.method="first")
  rnk <- rep(NA, length(sig))
  rnk[sig] <- idx

  data.frame(obs.0=n0, obs.1=n1, obs.tot=nt, mean.0=m0, mean.1=m1, mean.diff=md,
             var.0=v0, var.1=v1, var.log2.ratio=vlr, statistic.t=ts, pvalue.t=tp,
             statistic.bt=bs, pvalue.bt=bp, qvalue.bt=bq, significant=sig,
             rank=rnk, row.names=rownames(mat)
             )
}

################################################################################
#################### TEST CONSISTENCY WITH ORIGINAL VERSION ####################
################################################################################

test_that("monte-carlo random testing gives equal results", {
  set.seed(14)
  X1 <- matrix(rnorm(10000,0,0.5), ncol=50)
  X2 <- matrix(rnorm(10000,0,1), ncol=50)
  X <- cbind(X1, X2)
  X[sample(length(X),500)] <- NA
  rownames(X) <- 1:nrow(X)
  groups <- rep(c(0,1), each=50)

  t1 <- base_ievora(X, groups, 0.05, 0.001)
  t2 <- row_ievora(X, groups, 0.05, 0.001)

  expect_equal(t1, t2)
})

################################## EDGE CASES ##################################

test_that("weird numbers give equal results", {
  x <- rnorm(12, sd=0.000001); b <- rep(c("a","b"), each=6)
  expect_equal(base_ievora(x, b=="a"), row_ievora(x, b=="a"))
})

test_that("minumum allowed sample sizes give equal results", {
  x <- rnorm(4); b <- c(0,1,0,1)
  expect_equal(base_ievora(x, b), row_ievora(x, b))
  expect_equal(base_ievora(c(x, NA), c(b, 0)), row_ievora(c(x, NA), c(b, 0)))
})

test_that("first group is treated as 0 group", {
  x <- rnorm(12); b <- rep(c("a","b"), each=6)
  expect_equal(row_ievora(x, b), row_ievora(x, as.numeric(b=="b")))
  expect_equal(row_ievora(x, b), row_ievora(x, b=="b"))
})

test_that("constant values give equal results", {
  x <- c(1,1,2,3); b <- c(0,0,1,1)
  expect_equal(base_ievora(x, b), suppressWarnings(row_ievora(x, b)))
})

