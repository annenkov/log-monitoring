#lang racket
(require web-server/dispatch
         web-server/http/basic-auth
         web-server/http/response-structs
         web-server/http/xexpr)
(require "servlets/log_monitor.rkt"
         "settings.rkt")

(define (login-required request-handler)
  (define basic-auth-response
    (response
        401 #"Unauthorized" (current-seconds) TEXT/HTML-MIME-TYPE
        (list
         (make-basic-auth-header
          "Secure Area" ))
        void))
  (lambda (req) 
    (match (request->basic-credentials req)
      [(cons user pass) 
       (if (bytes=? (hash-ref passwords user #"") pass)
           (request-handler req)
           basic-auth-response)]
      [f# basic-auth-response])))

(define-values (url-dispatch url)
    (dispatch-rules
     [("") (login-required start)]
     [("log") (login-required get-log-as-json)]))

(provide url-dispatch
         login-required)