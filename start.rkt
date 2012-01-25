#lang racket
(require web-server/dispatch 
         web-server/servlet-env
         mzlib/os)
(require "dispatch.rkt"
         "settings.rkt")

(with-output-to-file pid-file (lambda () (write (getpid))) #:exists 'replace)
(serve/servlet url-dispatch
               #:port 8080
               #:command-line? #t
               #:servlets-root "servlets"
               #:extra-files-paths (list (build-path "htdocs"))
               #:servlet-regexp #rx"")