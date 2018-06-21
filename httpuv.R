library(httpuv)

png <- NULL
websocket <- NULL

polyfill_promise <- readLines('https://cdn.jsdelivr.net/npm/es6-promise/dist/es6-promise.auto.min.js')
html2canvas <- readLines('https://html2canvas.hertzen.com/dist/html2canvas.min.js')

app <- list(
  call = function(req) {
    wsUrl = paste(sep='',
                  '"',
                  "ws://",
                  ifelse(is.null(req$HTTP_HOST), req$SERVER_NAME, req$HTTP_HOST),
                  '"')
    
    list(
      status = 200L,
      headers = list(
        'Content-Type' = 'text/html'
      ),
      body = paste0(collapse = "\r\n",
        c("<!DOCTYPE html>",
          "<html>",
          "<head>",
          '<script type="text/javascript">',
          polyfill_promise,
          "</script>",
          '<script type="text/javascript">',
          html2canvas,
          "</script>",
          "</head>",
          "<body>",
          html_body,
          "</body>",
          '<script type="text/javascript">',
          sprintf("var ws = new WebSocket(%s);", wsUrl),
          "ws.onmessage = function(event) {",
          "  html2canvas(document.body).then(function(canvas) {",
          "    var dataURL = canvas.toDataURL();",
          "    ws.send(dataURL);",
          "  });",
          "};",
          "</script>",
          "</html>"
        )
      )
    )
  },
  onWSOpen = function(ws) {
    websocket <<- ws
    ws$onMessage(function(binary, message) {
      png <<- message
    })
  }
)

html_body <- c(
  '<h1> Content</h1>', 
  '<h2> Content</h2>', 
  'lorem ipsum...'
)

server <- startDaemonizedServer("0.0.0.0", 9454, app)

rstudioapi::viewer("http://localhost:9454")

# Get screenshot:
websocket$send("go") # send any message

writeBin(
  RCurl::base64Decode(
    gsub("data:image/png;base64,", "", png), 
    "raw"
  ), 
  "screenshot.png"
)

stopDaemonizedServer(server)
