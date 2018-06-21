library(httpuv)

png <- NULL

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
      body = paste(
        sep = "\r\n",
        "<!DOCTYPE html>",
        "<html>",
        "<head>",
        "</head>",
        "<body>",
        "Hello world",
        "</body>",
        "<script>",
        sprintf("var ws = new WebSocket(%s);", wsUrl),
        "ws.onopen = function(event) {",
        "  ws.send('received...');",
        "};",
        "</script>",
        "</html>"
      )
    )
  },
  onWSOpen = function(ws) {
    ws$onMessage(function(binary, message) {
      png <<- message
      ws$send(message)
    })
  }
)

server <- startDaemonizedServer("0.0.0.0", 9454, app)

rstudioapi::viewer("http://localhost:9454")

stopDaemonizedServer(server)

