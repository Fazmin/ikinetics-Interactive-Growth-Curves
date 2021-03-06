library(shiny)
library(plyr)
library(ggplot2)
library(googleVis)
library(reshape2)
library(opm)
library(Hmisc)
library(multcomp)



### Start shinyServer
shinyServer(function(input, output,session) {

    # functions
    # ************************************
    ### Functions 
    gcLoadData <- function(file) {
        require(reshape2)
        d <- read.delim(file, head=FALSE)
        names(d) <- c("Strain",d[1,-1])
        d <- d[-1,]
        d$Strain <- factor(d$Strain, levels=unique(d$Strain))
        d$Replicate <- unlist(lapply(table(d$Strain), function(x) seq(1,x,by=1)))
        gc <- melt(d, id=c("Strain","Replicate"), variable.name="Time", value.name="OD")
        gc$Time <- as.numeric(as.character(gc$Time))
        gc
    }

    # size=input$line_weight)

    plot_gc <- function(data=gc.s, strain="WT") {
        stat_sum_df <- function(fun, geom="smooth", ...) {
            stat_summary(fun.data=fun, geom=geom, ...)
        }
        p <- ggplot(data[data$Strain %in% strain,], aes(Time, OD, colour=Strain)) +
            theme_bw() + 
            stat_sum_df("mean_sdl", mult=1, mapping=aes(group=Strain),size=input$line_weight) +
            labs(title=paste(input$g_title," |", paste(strain, collapse=", "), sep=" "), x=input$g_ytext, y=input$g_xtext) + theme(plot.title = element_text(size=input$g_title_fsize)) + theme(text = element_text(size=input$g_xytext_fsize)) + theme(legend.position=input$g_legposition, legend.direction=input$g_legdirection) + labs(color = input$g_legtitle)
        p
    }

    plot_ci <- function(data=ci) {
        p <- ggplot(data, aes(estimate, lhs)) +
        geom_point(aes(estimate, lhs, colour=Significant)) +
        geom_errorbarh(aes(xmin = lwr, xmax = upr, colour=Significant), size=0.5, height = 0.3) +
        scale_color_manual(values = c("TRUE"="red", "FALSE"="black")) +
        facet_grid(.~param, scales="free") +
        geom_vline(xintercept=0, colour="blue", linetype="dotted") +
        ggtitle("95% family-wise confident intervals") +
        xlab("Estimated difference") +
        ylab("Pairwise comparison") +
        theme_bw()
        p
    }
        
    extractparam <- function(data) {
        require(opm)
        mu <- extract(data, as.labels=list("Strain","Replicate"),subset="mu", dataframe=TRUE)
        lambda <- extract(data, as.labels=list("Strain","Replicate"),subset="lambda", dataframe=TRUE)
        A <- extract(data, as.labels=list("Strain","Replicate"),subset="A", dataframe=TRUE)
        AUC <- extract(data, as.labels=list("Strain","Replicate"),subset="AUC", dataframe=TRUE)
        param <- data.frame("Strain"=mu$Strain,
                            "Replicate"=mu$Replicate, 
                            "mu"=mu[,4],
                            "lambda"=lambda[,4],
                            "A"=A[,4],
                            "AUC"=AUC[,4])
        param
    }

    compare <- function(data, ref) {
        require(opm)
        c <- parse(text = paste("c(Dunnett.",ref," = 1)", sep=""))
        stat.mu <- opm_mcp(data, ~ Strain, linfct = eval(c), m.type="aov", in.parens=FALSE, subset="mu")
        stat.lambda <- opm_mcp(data, ~ Strain, linfct = eval(c), m.type="aov", in.parens=FALSE, subset="lambda")
        stat.A <- opm_mcp(data, ~ Strain, linfct = eval(c), m.type="aov", in.parens=FALSE, subset="A")
        stat.AUC <- opm_mcp(data, ~ Strain, linfct = eval(c), m.type="aov", in.parens=FALSE, subset="AUC")
        ci.mu <- fortify(confint(stat.mu))
        ci.lambda <- fortify(confint(stat.lambda))
        ci.A <- fortify(confint(stat.A))
        ci.AUC <- fortify(confint(stat.AUC))
        ci.all <- rbind(ci.mu, ci.lambda, ci.A, ci.AUC)
        ci.all$param <- factor(rep(c("mu","lambda","A","AUC"), each=nrow(ci.mu)), levels=c("mu","lambda","A","AUC"))
        ci.all$Significant <- ci.all$lwr > 0 | ci.all$upr < 0
        ci.all
    }





    # *************************************
    
    Data <- reactive({
        
        
        # input$file1 will be NULL initially. After the user selects and uploads a 
        # file, it will be a data frame with 'name', 'size', 'type', and 'datapath' 
        # columns. The 'datapath' column will contain the local filenames where the 
        # data can be found.
        
        inFile <- input$file1
        
        if (is.null(inFile))
            return(NULL)
        
        df.raw <- read.delim(inFile$datapath)
        overview <- as.data.frame(table(df.raw[,1]))
        names(overview) <- c("Strain","Replicates")
        
        gc <- gcLoadData(inFile$datapath)
        
        # opm analysis: estimate parameters
        gc$Treatment <- "Treatment"
        gc.opm <- reshape(gc, v.names = "OD", direction = "wide", idvar = c("Strain","Treatment","Replicate"), timevar= "Time")
        gc.opm <- opmx(gc.opm, position = c("Strain","Replicate"), well = "Treatment", prefix = "OD.", full.name = c(GC = "Growth curves"))
        sm.gc <- do_aggr(gc.opm, method = "splines", boot = 100, options = set_spline_options(type = "smooth.spline")) 
        param <- extractparam(sm.gc)
        
        # create a list of data for use in rendering
        info <- list(gc=gc,
                     overview=overview,
                     strainlist=levels(overview$Strain),
                     param=param,
                     sm.gc=sm.gc)
        return(info)
    })
    
    # allows pageability and number of rows setting
#     myOptions <- reactive({  
#         list(
#             page=ifelse(input$pageable==TRUE,'enable','disable'),
#             pageSize=input$pagesize
#         ) 
#     } )

    # Options for gvisTable()
    myOptions <- list(page='enable',
                      pageSize=5)
    
    output$overview <- renderGvis({
        if (is.null(input$file1)) { return() }
        gvisTable(Data()$overview,options=myOptions)         
    })

    output$checklist <- renderUI({
        if (is.null(input$file1)) { return() }
        checkboxGroupInput(inputId = "strain", 
                           label = "Select strain(s) to plot (and click Submit):", 
                           choices = Data()$strainlist, 
                           inline = TRUE)        
    })

    output$param <- renderGvis({
        if (is.null(input$file1)) { return() }
        gvisTable(Data()$param,options=myOptions)         
    })
    
    
    output$selectref <- renderUI({
        if (is.null(input$file1)) { return() }
        selectInput(inputId = "ref",
                    label = "Select a reference strain for comparison (and click Submit): ",
                    choices = Data()$strainlist,
                    selected="wildtype")
    })
    
    output$gc_plot <- renderPlot({
        if (is.null(input$file1)) { return() }
        plot_gc(data=Data()$gc,strain=input$strain)      
    })

    output$dl_gc_plot <- downloadHandler(
        filename = "gc_plot.pdf",
        content = function(filename,res=300, units="cm"){
            device <- function(..., width, height) {
                grDevices::pdf(..., width = width, height = height)
            }
            ggsave(filename,plot=plot_gc(data=Data()$gc,strain=input$strain), device=device,dpi=res, units=units)
        }
    )

    ci <- reactive({
        d <- compare(Data()$sm.gc, input$ref)
        plot_ci(d)
    })

    output$ci_plot <- renderPlot({
        if (is.null(input$ref)) { return() }
        ci()
    })

    output$dl_ci_plot <- downloadHandler(
        filename = "ci_plot.pdf",
        content = function(filename,res=300, units="cm"){
            device <- function(..., width, height) {
                grDevices::pdf(..., width = width, height = height)
            }
            ggsave(filename,plot=ci(), device=device,dpi=res, units=units)
        }
    )




    # GSAVE DOWNLOADS
    # output$dl_gc_plot_pdf_s <- downloadHandler(
    #     filename =  function() {
    #       "gc_plot.pdf"
    #     },
    #     # content is a function with argument file. content writes the plot to the device
    #     content = function(filename,res=300, units="in"){
    #         ggsave(filename,plot=plot_gc(data=Data()$gc,strain=input$strain), device="pdf",dpi=res, units=units)
    #     } 
    # )

    # output$dl_gc_plot_png_s <- downloadHandler(
    #     filename =  function() {
    #       "gc_plot.png"
    #     },
    #     # content is a function with argument file. content writes the plot to the device
    #     content = function(filename,res=300, units="in"){
    #         ggsave(filename,plot=plot_gc(data=Data()$gc,strain=input$strain), device="png",dpi=res, units=units)
    #     } 
    # )

    # output$dl_gc_plot_svg_s <- downloadHandler(
    #     filename =  function() {
    #       "gc_plot.svg"
    #     },
    #     # content is a function with argument file. content writes the plot to the device
    #     content = function(filename,res=300, units="in"){
    #         ggsave(filename,plot=plot_gc(data=Data()$gc,strain=input$strain), device="svg",dpi=res, units=units)
    #     } 
    # )



    # //PRINT METHOD DOWNLOADS - WORKING TOO - GC

    output$dl_gc_plot_pdf <- downloadHandler(
        filename =  function() {
          "gc_plot.pdf"
        },
        content = function(file) {
        pdf(file)
        print(plot_gc(data=Data()$gc,strain=input$strain))
        dev.off()
        
        } 
    )

    output$dl_gc_plot_png <- downloadHandler(
        filename =  function() {
          "gc_plot.png"
        },
        content = function(file) {
        png(file, width = input$g_down_width, height = input$g_down_height)
        print(plot_gc(data=Data()$gc,strain=input$strain))
        dev.off()
        
        } 
    )


    output$dl_gc_plot_tiff <- downloadHandler(
        filename =  function() {
          "gc_plot.tiff"
        },
        content = function(file) {
        tiff(file, width = input$g_down_width, height = input$g_down_height)
        print(plot_gc(data=Data()$gc,strain=input$strain))
        dev.off()
        
        } 
    )


    # //PRINT METHOD DOWNLOADS - WORKING TOO - CI

    output$dl_ci_plot_pdf <- downloadHandler(
        filename =  function() {
          "ci_plot.pdf"
        },
        content = function(file) {
        pdf(file)
        print(ci())
        dev.off()
        
        } 
    )

    output$dl_ci_plot_png <- downloadHandler(
        filename =  function() {
          "ci_plot.png"
        },
        content = function(file) {
        png(file, width = input$g_down_width, height = input$g_down_height)
        print(ci())
        dev.off()
        
        } 
    )


    output$dl_ci_plot_tiff <- downloadHandler(
        filename =  function() {
          "ci_plot.tiff"
        },
        content = function(file) {
        tiff(file, width = input$g_down_width, height = input$g_down_height)
        print(ci())
        dev.off()
        
        } 
    )


  

    output$caption1 <- renderText( {
        if (is.null(input$file1)) { return("Waiting for input...") }
        "Summary of input data"
    })
    
    output$caption2 <- renderText( {
        if (is.null(input$file1)) { return("Waiting for input...") }
        "Growth curves"
    })   
     
    output$caption3 <- renderText( {
        if (is.null(input$file1)) { return("Waiting for input...") }
        "Curve parameters"
    })

    output$caption4 <- renderText( {
       if (is.null(input$file1)) { return("Waiting for input...") }
        "Pair-wise comparisons"
    })
    
    output$note1 <- renderText( {
        if (is.null(input$file1)) { return() }
        "The above table lists curve parameters estimated by the package 'opm' using 'smooth_spline' method. Spline interpolation uses stats::spline() to interpolate between existing vertices using piecewise cubic polynomials. The x and y coordinates are interpolated independently. The curve will always pass through the vertices of the original feature."  
    })

    output$note2 <- renderText( {
       if (is.null(input$file1)) { return() }
        "Statistical comparison was done using anova and Dunnett post-test. - Dunnett’s Test (also called Dunnett’s Method or Dunnett’s Multiple Comparison) compares means from several experimental groups against a control group mean to see is there is a difference. When an ANOVA test has significant findings, it doesn’t report which pairs of means are different. Dunnett’s can be used after the ANOVA has been run to identify the pairs with significant differences."    
    })

  
  })