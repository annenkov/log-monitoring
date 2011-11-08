#lang racket
(require web-server/dispatch)
(require "servlets/log_monitor.rkt")

(define-values (url-dispatch url)
    (dispatch-rules
     [("") start]
     [("log") get-log-as-json]))

(provide url-dispatch)