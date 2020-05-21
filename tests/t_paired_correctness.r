library(matrixTests)

#--- functions -----------------------------------------------------------------

base_t_paired <- function(mat1, mat2, alt="two.sided", null=0, conf=0.95) {
  stopifnot(ncol(mat1)==ncol(mat2))
  if(is.vector(mat1)) mat1 <- matrix(mat1, nrow=1)
  if(is.vector(mat2)) mat2 <- matrix(mat2, nrow=1)
  if(length(alt)==1) alt <- rep(alt, nrow(mat1))
  if(length(null)==1) null <- rep(null, nrow(mat1))
  if(length(conf)==1) conf <- rep(conf, nrow(mat1))

  mx <- my <- md <- vx <- vy <- vd <- nx <- ny <- nt <- tst <- p <- cl <- ch <-
    se <- df <- m0 <- cnf <- numeric(nrow(mat1))
  al <- character(nrow(mat1))
  for(i in 1:nrow(mat1)) {
    vec1 <- mat1[i,]
    vec2 <- mat2[i,]
    res <- t.test(vec1, vec2, alternative=alt[i], mu=null[i], conf.level=conf[i],
                  paired=TRUE
                  )

    mx[i]  <- mean(na.omit(vec1))
    my[i]  <- mean(na.omit(vec2))
    md[i]  <- res$estimate
    vx[i]  <- var(na.omit(vec1))
    vy[i]  <- var(na.omit(vec2))
    vd[i]  <- var(na.omit(vec1-vec2))
    nx[i]  <- length(na.omit(vec1))
    ny[i]  <- length(na.omit(vec2))
    nt[i]  <- length(na.omit(vec1-vec2))
    tst[i] <- res$statistic
    p[i]   <- res$p.value
    cl[i]  <- res$conf.int[1]
    ch[i]  <- res$conf.int[2]
    df[i]  <- res$parameter
    m0[i]  <- res$null.value
    al[i]  <- res$alternative
    cnf[i] <- attr(res$conf.int, "conf.level")
    se[i]  <- sqrt(vd[i]/nt[i])
  }

  data.frame(obs.x=nx, obs.y=ny, obs.paired=nt, mean.x=mx, mean.y=my,
             mean.diff=md, var.x=vx, var.y=vy, var.diff=vd, stderr=se,
             df=df, statistic=tst, pvalue=p, conf.low=cl, conf.high=ch,
             alternative=al, mean.null=m0, conf.level=cnf,
             stringsAsFactors=FALSE
             )
}


#--- montecarlo ----------------------------------------------------------------

# 5 observations
x <- matrix(rnorm(5000), ncol=5)
y <- matrix(rnorm(5000), ncol=5)
alts <- sample(c("t", "g", "l"), nrow(x), replace=TRUE)
mus  <- sample(seq(-1, 1, length.out=nrow(x)))
cfs  <- sample(seq(0, 1, length.out=nrow(x)))
res1 <- base_t_paired(x, y, alts, mus, cfs)
res2 <- row_t_paired(x, y, alts, mus, cfs)
stopifnot(all.equal(res1, res2))

# 20 observations
x <- matrix(rnorm(20000), ncol=20)
y <- matrix(rnorm(20000), ncol=20)
alts <- sample(c("t", "g", "l"), nrow(x), replace=TRUE)
mus  <- sample(seq(-1, 1, length.out=nrow(x)))
cfs  <- sample(seq(0, 1, length.out=nrow(x)))
res1 <- base_t_paired(x, y, alts, mus, cfs)
res2 <- row_t_paired(x, y, alts, mus, cfs)
stopifnot(all.equal(res1, res2))


#--- extreme numbers -----------------------------------------------------------

# big numbers
x <- c(100000000000004, 100000000000002, 100000000000003, 100000000000000)
y <- c(100000000000003, 100000000000002, 100000000000003, 100000000000000)
res1 <- base_t_paired(x, y)
res2 <- row_t_paired(x, y)
stopifnot(all.equal(res1, res2))

# small numbers
x <- c(0.00000000000004, 0.00000000000002, 0.00000000000003, 0)
y <- c(0.00000000000003, 0.00000000000002, 0.00000000000003, 0)
res1 <- base_t_paired(x, y)
res2 <- row_t_paired(x, y)
stopifnot(all.equal(res1, res2))

# TODO: add tests for Inf and -Inf values once decided how to handle them.


#--- minimal sample size -------------------------------------------------------

# 2 observations in both groups
x <- matrix(rnorm(6), ncol=2)
y <- matrix(rnorm(6), ncol=2)
alt <- c("two.sided", "greater", "less")
res1 <- base_t_paired(x, y, alt)
res2 <- row_t_paired(x, y, alt)
stopifnot(all.equal(res1, res2))

# two numbers with NAs
x <- matrix(c(rnorm(9), NA, NA, NA), ncol=4)
y <- matrix(c(NA, NA, NA, rnorm(9)), ncol=4)
alt <- c("two.sided", "greater", "less")
res1 <- base_t_paired(x, y)
res2 <- suppressWarnings(row_t_paired(x, y))
stopifnot(all.equal(res1, res2))


#--- parameter edge cases ------------------------------------------------------

# various corner cases with NAs
alt <- c("l", "t", "g")
mus <- c(-Inf, -1, 0, 1, Inf)
cfs <- c(0, 0.5, 1)
pars <- expand.grid(alt, mus, cfs, stringsAsFactors=FALSE)
x <- matrix(rnorm(10*nrow(pars)), ncol=10)
y <- matrix(rnorm(10*nrow(pars)), ncol=10)
x[sample(length(x), nrow(pars)*2)] <- NA
y[sample(length(y), nrow(pars)*2)] <- NA
res1 <- base_t_paired(x, y, pars[,1], pars[,2], pars[,3])
res2 <- row_t_paired(x, y, pars[,1], pars[,2], pars[,3])
stopifnot(all.equal(res1, res2))

# null exactly equal to the mean
res1 <- base_t_paired(c(1,2,3), c(0,0,0), null=2)
res2 <- row_t_paired(c(1,2,3), c(0,0,0), null=2)
stopifnot(all.equal(res2$pvalue, 1))
stopifnot(all.equal(res1, res2))

