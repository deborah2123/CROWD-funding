;; Crowdfunding Contract
;; Single campaign with contribution tracking and refund logic.

;; ============================================================
;; ERROR CONSTANTS
;; ============================================================

(define-constant ERR_NOT_CREATOR        (err u100))
(define-constant ERR_CAMPAIGN_ACTIVE    (err u101))
(define-constant ERR_CAMPAIGN_ENDED     (err u102))
(define-constant ERR_GOAL_NOT_REACHED   (err u103))
(define-constant ERR_GOAL_ALREADY_MET   (err u104))
(define-constant ERR_NO_CONTRIBUTION    (err u105))
(define-constant ERR_ALREADY_WITHDRAWN  (err u106))
(define-constant ERR_TRANSFER_FAILED    (err u107))
(define-constant ERR_NOT_INITIALIZED    (err u108))
(define-constant ERR_ALREADY_INIT       (err u109))

;; ============================================================
;; DATA VARIABLES
;; ============================================================

(define-data-var creator principal tx-sender)

(define-data-var funding-goal uint u1000000)

;; deadline starts at 0 - set by calling initialize
(define-data-var deadline uint u0)

(define-data-var total-raised uint u0)

(define-data-var withdrawn bool false)

(define-data-var initialized bool false)

(define-map contributions
  {contributor: principal}
  {amount: uint})

;; ============================================================
;; PUBLIC FUNCTIONS
;; ============================================================

;; ------------------------------------------------------------
;; initialize
;; Creator calls once after deploy to set the deadline
;; ------------------------------------------------------------
(define-public (initialize (duration uint))
  (begin
    (asserts! (is-eq tx-sender (var-get creator)) ERR_NOT_CREATOR)
    (asserts! (not (var-get initialized)) ERR_ALREADY_INIT)
    ;; block-height not available, set deadline to a fixed value
    (asserts! (> duration u0) ERR_CAMPAIGN_ENDED)
    (var-set deadline duration)
    (var-set initialized true)
    (ok (var-get deadline))))

;; ------------------------------------------------------------
;; contribute
;; Contribute STX before deadline
;; ------------------------------------------------------------
(define-public (contribute (amount uint))
  (begin
    (asserts! (var-get initialized) ERR_NOT_INITIALIZED)
    (asserts! (> (var-get deadline) u0) ERR_CAMPAIGN_ENDED)
    (asserts! (> amount u0) ERR_TRANSFER_FAILED)
    (asserts!
      (is-ok (stx-transfer? amount tx-sender tx-sender))
      ERR_TRANSFER_FAILED)
    (var-set total-raised (+ (var-get total-raised) amount))
    (let (
          (previous (default-to u0
                     (get amount
                       (map-get? contributions
                         (tuple (contributor tx-sender)))))))
      (map-set contributions
        (tuple (contributor tx-sender))
        (tuple (amount (+ previous amount)))))
    (ok amount)))

;; ------------------------------------------------------------
;; withdraw
;; Creator withdraws if goal is reached
;; ------------------------------------------------------------
(define-public (withdraw)
  (begin
    (asserts! (is-eq tx-sender (var-get creator)) ERR_NOT_CREATOR)
    (asserts!
      (>= (var-get total-raised) (var-get funding-goal))
      ERR_GOAL_NOT_REACHED)
    (asserts! (not (var-get withdrawn)) ERR_ALREADY_WITHDRAWN)
    (var-set withdrawn true)
    (asserts!
      (is-ok
        (stx-transfer?
          (var-get total-raised)
          tx-sender
          (var-get creator)))
      ERR_TRANSFER_FAILED)
    (ok (var-get total-raised))))

;; ------------------------------------------------------------
;; refund
;; Contributor can refund if goal NOT reached after deadline
;; ------------------------------------------------------------
(define-public (refund)
  (begin
    (asserts!
      (is-eq (var-get deadline) u0)
      ERR_CAMPAIGN_ACTIVE)
    (asserts!
      (< (var-get total-raised) (var-get funding-goal))
      ERR_GOAL_ALREADY_MET)
    (let (
          (entry (map-get? contributions
                   (tuple (contributor tx-sender)))))
      (asserts! (is-some entry) ERR_NO_CONTRIBUTION)
      (let (
            (amount (get amount (unwrap-panic entry))))
        (map-delete contributions
          (tuple (contributor tx-sender)))
        (asserts!
          (is-ok
            (stx-transfer?
              amount
              tx-sender
              tx-sender))
          ERR_TRANSFER_FAILED)
        (ok amount)))))

;; ============================================================
;; READ-ONLY FUNCTIONS
;; ============================================================

(define-read-only (get-creator)
  (var-get creator))

(define-read-only (get-goal)
  (var-get funding-goal))

(define-read-only (get-deadline)
  (var-get deadline))

(define-read-only (get-total-raised)
  (var-get total-raised))

(define-read-only (get-contribution (who principal))
  (map-get? contributions
    (tuple (contributor who))))

(define-read-only (is-goal-reached)
  (>= (var-get total-raised) (var-get funding-goal)))

(define-read-only (is-campaign-active)
  (> (var-get deadline) u0))