#lang racket
(require web-server/dispatch 
         web-server/servlet-env)
(require "dispatch.rkt")

(serve/servlet url-dispatch
               #:port 8080
               #:command-line? #t
               #:servlets-root "servlets"
               #:extra-files-paths (list (build-path "htdocs"))
               #:servlet-regexp #rx"")