#lang racket
(require racket/runtime-path)

(define-runtime-path log-file "sample_log/payworld.log")
(define passwords #hash((#"admin" . #"sample")))

(provide log-file
         passwords)