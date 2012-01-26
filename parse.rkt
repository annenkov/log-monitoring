#lang racket
(require (planet bzlib/parseq)) 
(require racket/file)
(require srfi/19)  ; time datatype and utils
(require (only-in srfi/13
                  string-contains
                  substring/shared))  ; string utils
(require "settings.rkt")

(define (load-log)
  (file->string log-file))

(define LOG-ENTRY-TYPES
  #hash([#\E . "Error"]
        [#\W . "Warning"]
        [#\I . "Info"]
        [#\D . "Debug"]))

(define (parse-log)
  ((make-reader log-entries) (load-log)))

(define log-entries
  (seq entry <- (one-many (seq head <- header
                               msg <- message
                               (return (make-hash (append head `(["msg" .  ,(list->string msg)]))))))
       (return entry)))

(define header
  (tokens  #\[
           type <- (char-in '(#\E #\W #\I #\D))
           date <- parse-date
           time <- parse-time
           logger <- parse-logger
           #\@
           place <- parse-place
           tx-id <- (choice parse-tx-id
                            (return #\null))
           #\]
           (return `(["type" . ,(hash-ref LOG-ENTRY-TYPES type)]
                     ["date" . ,date]
                     ["time" . ,time]
                     ["logger" . ,logger]
                     ["place" . ,place]
                     ["tx_id" . ,tx-id]))))

(define message
  (seq msg <- (one-many (seq (check-not entry-header)
                             v <- any-char
                             (return v)))
       (return msg)))

(define entry-header
  (seq (char= #\[)
       (char-in '(#\E #\W #\I))
       whitespace))

;;;;; 'check-not' combinator
(define (check-not parser)
  (lambda (in) 
      (let-values ([(val new-in) 
                    (parser in)])
        (if (succeeded? val) 
            (fail in)
        (values #t in)))))

(define (parse-string-of parser)
  (seq value <- (one-many parser)
       (return (list->string value))))

(define parse-date
  (parse-string-of (choice digit (char= #\-))))
 
(define parse-time
  (parse-string-of (choice digit (char-in '(#\: #\, #\.)))))
         
(define parse-logger
  (parse-string-of (choice word (char= #\.))))

(define parse-place
  (parse-string-of (choice word (char= #\:))))

(define parse-tx-id
  (seq #\# 
       tx-id <- (parse-string-of digit)
       (return tx-id)))


;;;;; filters predicates
(define (type? log-entry-type)
  (lambda (entry)
    (string=? (hash-ref entry "type") log-entry-type)))

(define (type-in? types-shortcuts-string)
  (let ([log-entry-types 
         (map 
          (lambda(x) (hash-ref LOG-ENTRY-TYPES x))
          (string->list types-shortcuts-string))])
  (lambda (entry)
    (member (hash-ref entry "type") log-entry-types))))

;;;;;; statistics
(define (log-statistics logs)
  (hash "infos" (length (filter (type? "Info") logs))
         "warnings" (length (filter (type? "Warning") logs))
         "errors" (length (filter (type? "Error") logs))))

(define (identity x) x)

(provide parse-log log-statistics type-in? type?)