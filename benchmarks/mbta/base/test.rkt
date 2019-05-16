#lang racket/base

(module m racket/base
  (provide attach-edge-property)
  (define (attach-edge-property graph #:init (x #f)) #f))
(require 'm)

(define v:attach-edge-property
  (contract (->* (any/c) (#:init any/c) any)
            attach-edge-property 'a 'b))

(v:attach-edge-property #f #:init #f)
