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

(define test-log-string
  "[W 2011-10-04 23:11:14,842 payworld.payment@notifications:76]11\r\n[W 2011-10-04 23:11:16,875 payworld.payment@processing:204] Transaction #0000010 status changed to \"failed\" due to exception in process_account_payment (current user \"user@pay-world.ru\"):Insufficient funds\r\n[W 2011-10-04 23:11:14,842 payworld.payment@notifications:76] Transaction #0000006 status changed to \"failed\" due to exception in process_notification_gorod (current user \"\"):Insufficient funds\r\n[W 2011-10-04 23:11:16,875 payworld.payment@processing:204] Transaction #0000010 status changed to \"failed\" due to exception in process_account_payment (current user \"user@pay-world.ru\"):Insufficient funds\r\n")

(define LOG-ENTRY-TYPES
  #hash([#\E . "Error"]
        [#\W . "Warning"]
        [#\I . "Info"]))

(define (parse-log)
  ((make-reader log-entries) (load-log)))

(define log-entries
  (seq entry <- (one-many (seq head <- header
                               msg <- message
                               (return (make-hash (append head `(["msg" .  ,(list->string msg)]))))))
       (return entry)))

(define header
  (tokens  #\[
           type <- (char-in '(#\E #\W #\I))
           date <- parse-date
           time <- parse-time
           logger <- parse-logger
           #\@
           place <- parse-place
           #\]
           (return `(["type" . ,(hash-ref LOG-ENTRY-TYPES type)]
                     ["date" . ,date]
                     ["time" . ,time]
                     ["logger" . ,logger]
                     ["place" . ,place]))))

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