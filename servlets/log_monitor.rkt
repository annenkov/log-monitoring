#lang racket
(require web-server/templates
         web-server/http/response-structs
         web-server/http/bindings
         web-server/dispatchers/dispatch-passwords)
(require (planet dherman/json:3:0))
(require "../parse.rkt")

(define APPLICATION/JSON-MIME-TYPE
  (string->bytes/utf-8 "application/json; charset=utf-8"))

(define (start request)
  (render-template (include-template "../htdocs/index.html")))

(define (render-template template)
  (response/full
   200 #"OK"
   (current-seconds) TEXT/HTML-MIME-TYPE
   empty
   (list (string->bytes/utf-8 template))))

(define (jsexpr->listbytes jsexpr)
  (list (string->bytes/utf-8 (jsexpr->json jsexpr))))

(define (json-response jsexpr)
  (response/full
   200 #"OK"
   (current-seconds) APPLICATION/JSON-MIME-TYPE
   empty
  (jsexpr->listbytes jsexpr)))

(define (get-log-with-statistics filters)
  (define (get-log)
    (if (null? filters)
        (parse-log)
        (filter (type-in? filters) (parse-log))))
  (hash "log_statistics" (log-statistics (get-log))
        "log_data" (get-log)))

(define (get-filters-or-null request)
  (let ([bindings (request-bindings request)])
    (if (not (null? bindings))
        (extract-binding/single 'filters (request-bindings request))
        '())))

(define (get-log-as-json request)
  (let ([filters (get-filters-or-null request)])
    (json-response (get-log-with-statistics filters))))

(provide (all-defined-out))
