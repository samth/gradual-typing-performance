#lang typed/racket/base

;; Resolving offsets between moments

(require
  "core-structs.rkt"
  "gregor-structs.rkt"
  racket/match)
(require "hmsn.rkt"
)
(require "datetime.rkt"
)
(require "moment-base.rkt"
)

(require/typed/provide "../base/tzinfo/main.rkt"
  [system-tzid (-> (U tz #f))]
  [#:struct tzgap ([starts-at : Natural]
                   [offset-before : tzoffset]
                   [offset-after : tzoffset])]
  [#:struct tzoffset ([utc-seconds : Integer]
                      [dst? : Boolean]
                      [abbreviation : String])]
  [#:struct tzoverlap ([offset-before : tzoffset]
                       [offset-after : tzoffset])]
  [local-seconds->tzoffset (-> String Integer (U tzoffset tzgap tzoverlap))]
  [utc-seconds->tzoffset (-> String Exact-Rational tzoffset)]
)

(provide tz)
(define-type tz (U String Integer))
;; -----------------------------------------------------------------------------

(provide
         resolve-gap/pre
         resolve-gap/post
         resolve-gap/push

         resolve-overlap/pre
         resolve-overlap/post
         resolve-overlap/retain

         resolve-offset/pre
         resolve-offset/post
         resolve-offset/post-gap/pre-overlap
         resolve-offset/retain
         resolve-offset/push
         resolve-offset/raise

         offset-resolver
)
;; =============================================================================

;; -- from exn.rkt

(struct exn:gregor exn:fail ())
(struct exn:gregor:invalid-offset exn:gregor ())

(: raise-invalid-offset (-> Any DateTime Any Any Moment))
(define (raise-invalid-offset g/o target-dt target-tzid orig)
  (raise
   (exn:gregor:invalid-offset
    (format "Illegal moment: local time ~a ~a in time zone ~a"
            (datetime->iso8601 target-dt)
            (if (tzgap? g/o)
                "does not exist"
                "is ambiguous")
            target-tzid)
    (current-continuation-marks))))

;; -- from `offset-resolvers.rkt`

(: resolve-gap/pre (-> tzgap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-gap/pre gap target-dt target-tzid orig)
  ;(define tm (tzgap-starts-at gap))
  ;(define delta (tzoffset-utc-seconds (tzgap-offset-before gap)))
  (match-define (tzgap tm (tzoffset delta _ _) _) gap)
  (make-moment (posix->datetime (+ tm delta (- (/ 1 NS/SECOND)))) delta target-tzid))

(: resolve-gap/post (-> tzgap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-gap/post gap target-dt target-tzid orig)
  ;(match-define (tzgap _ _ (tzoffset delta _ _)) gap)
  (define tm (tzgap-starts-at gap))
  (define delta (tzoffset-utc-seconds (tzgap-offset-before gap)))
  (define sum (+ tm delta))
  (make-moment (posix->datetime sum) delta target-tzid))

(: resolve-gap/push (-> tzgap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-gap/push gap target-dt target-tzid orig)
  ;(match-define (tzgap tm (tzoffset delta1 _ _) (tzoffset delta2 _ _)) gap)
  (define tm (tzgap-starts-at gap))
  (define delta1 (tzoffset-utc-seconds (tzgap-offset-before gap)))
  (define delta2 (tzoffset-utc-seconds (tzgap-offset-after gap)))
  (make-moment (posix->datetime (+ (datetime->posix target-dt) (- delta2 delta1))) delta2 target-tzid))

(: resolve-overlap/pre (-> tzoverlap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-overlap/pre overlap target-dt target-tzid orig)
  (match-define (tzoverlap (tzoffset delta _ _) _) overlap)
  (make-moment target-dt delta target-tzid))

(: resolve-overlap/post (-> tzoverlap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-overlap/post overlap target-dt target-tzid orig)
  (match-define (tzoverlap _ (tzoffset delta _ _)) overlap)
  (make-moment target-dt delta target-tzid))

(: resolve-overlap/retain (-> tzoverlap DateTime (U String #f) (U #f Moment) Moment))
(define (resolve-overlap/retain overlap target-dt target-tzid orig)
  ;(match-define (tzoverlap (tzoffset delta1 _ _) (tzoffset delta2 _ _)) overlap)
  (define delta1 (tzoffset-utc-seconds (tzoverlap-offset-before overlap)))
  (define delta2 (tzoffset-utc-seconds (tzoverlap-offset-after overlap)))
  (make-moment target-dt
               (or (and orig (= (Moment-utc-offset orig) delta1) delta1)
                   delta2)
               target-tzid))

(: offset-resolver (-> (-> tzgap DateTime (U String #f) (U #f Moment) Moment)
                       (-> tzoverlap DateTime (U String #f) (U #f Moment) Moment)
                       (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment)))
(define (offset-resolver rg ro)
  (λ ([g/o : (U tzgap tzoverlap)]
      [target-dt : DateTime]
      [target-tzid : (U String #f)]
      [orig : (U #f Moment)])
    (cond [(tzgap? g/o)
           (rg g/o target-dt target-tzid orig)]
          [else
           (ro g/o target-dt target-tzid orig)])))
    ;; (define fn (if (tzgap? g/o) rg ro))
    ;; (fn g/o target-dt target-tzid orig)))

(: resolve-offset/pre (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment))
(define resolve-offset/pre
  (offset-resolver resolve-gap/pre resolve-overlap/pre))

(: resolve-offset/post (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment))
(define resolve-offset/post
  (offset-resolver resolve-gap/post resolve-overlap/post))

(: resolve-offset/post-gap/pre-overlap (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment))
(define resolve-offset/post-gap/pre-overlap
  (offset-resolver resolve-gap/post resolve-overlap/pre))

(: resolve-offset/retain (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment))
(define resolve-offset/retain
  (offset-resolver resolve-gap/post
                   resolve-overlap/retain))

(: resolve-offset/push (-> (U tzgap tzoverlap) DateTime (U String #f) (U #f Moment) Moment))
(define resolve-offset/push
  (offset-resolver resolve-gap/push
                   resolve-overlap/post))

(: resolve-offset/raise (-> (U tzgap tzoverlap) DateTime (U String #f) (U Moment #f) Moment))
(define (resolve-offset/raise g/o target-dt target-tzid orig)
  (raise-invalid-offset g/o target-dt target-tzid orig))