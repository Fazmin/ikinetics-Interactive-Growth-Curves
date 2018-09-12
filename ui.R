library(shiny)
library(shinydashboard)
# library(ggedit)

shinyUI(
  dashboardPage(skin = "red",
  dashboardHeader(
    title = "CMCB qKinetics"

    ),
  dashboardSidebar(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "mystyle.css")),tags$head(tags$script(src="scripts.js")),
    # ),
     sidebarMenu(id="menu1",
        menuItem("Graphs", tabName = "graphsx", icon = icon("th")),
        menuItem("Paste Data", tabName = "pdata", icon = icon("th")),
        menuItem("Parameter estimation", tabName =  "para_est", icon = icon("th")),
        menuItem("Statistical Comparisons", tabName =  "stat_comp", icon = icon("th"))
     ),

    conditionalPanel(
        condition = "input.menu1 == 'graphsx'",
          # helpText(""),
        
        tags$hr(),
        
        # helpText("Choose tab-delimited file to upload:"),
        
        fileInput('file1', '',
                  accept=c('text/comma-separated-values,text/plain')),

        radioButtons('fty','CSV File Format',choices=list("Comma deliminated"='csv',"Tab deliminated"='tab'),selected='csv'),
        
        # helpText("Note: The data provided should be blank corrected."),
        # helpText("Please download this ", tags$a(href="https://raw.githubusercontent.com/mdphan/GrowthCurvesAnalysis_shinyApp/master/sample_data.txt", "sample file"), " to use as input if you would like give this app a try."),
        
        tags$hr()
        
        
        
        # tags$hr()
          
          )
    ),
    dashboardBody(
    # output
      tabItems(
        tabItem(tabName = "graphsx", 
              box(width = 2,
                h4(textOutput("caption1")),
                htmlOutput("overview")
              ),
              box(width = 10,
                h5("Analyse bacterial growth curves, including interactive plotting of growth curves, estimating of curve parameters and comparing curve parameters of different groups. Note: The data provided should be blank corrected."),
                h4(textOutput("caption2")),
                       uiOutput("checklist"),
                       submitButton(text="Plot Data / Redraw plot with new settings"),br(),br(),
                       plotOutput("gc_plot"),
                       tags$hr(),
                     # downloadButton("dl_gc_plot","Download plot (.pdf)"),
                     # downloadButton(outputId = "dl_gc_plot_pdf", label ="Download plot (.pdf)"), 
                     # downloadButton(outputId = "dl_gc_plot_png", label ="Download plot (.png)"), 
                      
                     # plotOutput("plot"),
                     # downloadButton(outputId = "downpdf", label = "Download the plot"),             
                     value = 1
              ),
              box(width = 9,
                # fluidRow(
                  tabBox(width = 12,
                    # Title can include an icon
                    title = tagList(shiny::icon("gear"), "Customize graph"),
                    tabPanel("Text",
                      box(width = 4,
                        textInput("g_title", label = p("Title"), value = "Growth curves of"),
                        textInput("g_xtext", label = p("x axis text"), value = "Time (hour)"),
                        textInput("g_ytext", label = p("y axis text"), value = "OD[600]")
                      ),
                      box(width = 4,
                        textInput("g_legtitle", label = p("Legend title"), value = "Strains"),
                        radioButtons("g_legdirection", "Legend direction:", c("Horizontal" = "horizontal", "Vertical" = "vertical"),selected  = "Horizontal"),
                        radioButtons("g_legposition", "Legend direction:", c( "Top" = "top", "Bottom" = "bottom", "Right" = "right", "Left" = "left"), selected  = "Bottom")
                      ),
                      box(width = 4,
                        sliderInput("g_title_fsize", "Title font size:", min = 10, max = 38, value = 14),
                        sliderInput("g_xytext_fsize", "Axis font size:", min = 8, max = 32, value = 10),
                        sliderInput("line_weight", "Line Weight:", min = 0.3, max = 6, value = 1.8, step = 0.3)
                        # sliderInput("g_ytext_fsize", "Integer:", min = 8, max = 20, value = 10)
                      )
                      
                    ),
                    tabPanel("Colors",
                      textInput("g_color_palette", label = p("Select color palette"), value = "Enter text...")
                    )
                  )
                # )

              ),
              box(width = 3,
                h4("Download"),
                # textInput("g_down_width", label = p("Width"), value = "1024"),
                # textInput("g_down_height", label = p("Height"), value = "600"),
                sliderInput("g_down_width", "Width", min = 600, max = 2560, value = 800),
                sliderInput("g_down_height", "Height", min = 400, max = 2240, value = 600),
                 
                  downloadButton(outputId = "dl_gc_plot_pdf", label ="Download hi-res plot (.pdf) -GC"),br(),br(),
                downloadButton(outputId = "dl_gc_plot_png", label ="Download hi-res plot (.png)"),br(),br(),
                downloadButton(outputId = "dl_gc_plot_tiff", label ="Download hi-res plot (.tiff)"),br(),br()
              )
        ),
        tabItem(tabName = "pdata",
          box(width = 12,
                h3("Paste Data (comma/tab separated-values with headers) please setect type on sidebar"),
                tags$textarea(id="datainput", rows=14, cols=140),
                br(),
                actionButton("submitclick", strong("Load data"))
              )
        ),
        tabItem(tabName = "para_est",
          box(width = 12,
            h4(textOutput("caption3")),
                     tableOutput("param"),
                     tags$hr(),
                     tags$body(textOutput("note1")),
                     value = 2
          )
        ),
        tabItem(tabName = "stat_comp",
          box(width = 12,
            h4(textOutput("caption4")),                      
                     uiOutput("selectref"),
                     submitButton(text="Process Data"),br(),
                     plotOutput("ci_plot"),
                     tags$hr(),
                     tags$body(textOutput("note2")),
                     tags$hr(),
                     downloadButton("dl_ci_plot", "Download plot (.pdf)"),
                     value = 3
          ),
          box(width = 9,
                # fluidRow(
                  tabBox(width = 12,
                    # Title can include an icon
                    title = tagList(shiny::icon("gear"), "Customize graph"),
                    tabPanel("Text",
                      box(width = 4,
                        textInput("c_title", label = p("Title"), value = "Growth curves of"),
                        textInput("c_xtext", label = p("x axis text"), value = "Time (hour)"),
                        textInput("c_ytext", label = p("y axis text"), value = "OD[600]")
                      ),
                      box(width = 4,
                        textInput("c_legtitle", label = p("Legend title"), value = "Strains"),
                        radioButtons("c_legdirection", "Legend direction:", c("Horizontal" = "horizontal", "Vertical" = "vertical"),selected  = "Horizontal"),
                        radioButtons("c_legposition", "Legend direction:", c( "Top" = "top", "Bottom" = "bottom", "Right" = "right", "Left" = "left"), selected  = "Bottom")
                      ),
                      box(width = 4,
                        sliderInput("c_title_fsize", "Title font size:", min = 10, max = 38, value = 14),
                        sliderInput("c_xytext_fsize", "Axis font size:", min = 8, max = 32, value = 10),
                        sliderInput("cline_weight", "Line Weight:", min = 0.3, max = 6, value = 1.8, step = 0.3)
                        # sliderInput("g_ytext_fsize", "Integer:", min = 8, max = 20, value = 10)
                      )
                      
                    ),
                    tabPanel("Colors",
                      textInput("c_color_palette", label = p("Select color palette"), value = "Enter text...")
                    )
                  )
            ),
            box(width = 3,
              h4("Download"),
              # textInput("g_down_width", label = p("Width"), value = "1024"),
              # textInput("g_down_height", label = p("Height"), value = "600"),
              sliderInput("c_down_width", "Width", min = 600, max = 2560, value = 800),
              sliderInput("c_down_height", "Height", min = 400, max = 2240, value = 600),

                downloadButton(outputId = "dl_ci_plot_pdf", label ="Download hi-res plot (.pdf) -ci"),br(),br(),
                downloadButton(outputId = "dl_ci_plot_png", label ="Download hi-res plot (.png)"),br(),br(),
                downloadButton(outputId = "dl_ci_plot_tiff", label ="Download hi-res plot (.tiff)"),br(),br()
            )
          )
      ),  

      tags$span(HTML('<div id="sfooter">copyright &copy; 2017-2018 - IIDR Bioinformatics QuickKinetics 1.12v- Fazmin</div>'))

    )
  )
)