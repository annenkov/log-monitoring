#lang racket
(require racket/runtime-path)

(define-runtime-path pid-file "./pid")
(define-runtime-path log-file "sample_log/payworld.log")
(define passwords #hash((#"admin" . #"sample")))

(provide pid-file 
         log-file
         passwords)