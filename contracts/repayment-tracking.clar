;; Repayment Tracking Contract
;; Manages payment collection and distribution

;; Define repayment structure
(define-map repayments
  { invoice-id: uint }
  {
    total-amount: uint,
    amount-paid: uint,
    last-payment-date: uint,
    status: (string-ascii 20)
  }
)

;; Define payment history
(define-map payment-history
  { invoice-id: uint, payment-id: uint }
  {
    payer: principal,
    amount: uint,
    payment-date: uint
  }
)

;; Track the last payment ID for each invoice
(define-map last-payment-id
  { invoice-id: uint }
  { id: uint }
)

;; Initialize repayment tracking for an invoice
(define-public (initialize-repayment (invoice-id uint) (principal-amount uint) (interest-rate uint) (borrower principal))
  (let
    (
      (total-amount (+ principal-amount (/ (* principal-amount interest-rate) u10000)))
    )
    ;; Initialize the repayment tracking
    (map-set repayments
      { invoice-id: invoice-id }
      {
        total-amount: total-amount,
        amount-paid: u0,
        last-payment-date: u0,
        status: "pending"
      }
    )

    ;; Initialize the last payment ID
    (map-set last-payment-id
      { invoice-id: invoice-id }
      { id: u0 }
    )

    (ok total-amount)
  )
)

;; Make a payment for an invoice
(define-public (make-payment (invoice-id uint) (amount uint))
  (let
    (
      (repayment (unwrap! (map-get? repayments { invoice-id: invoice-id }) (err u1)))
      (last-id (default-to { id: u0 } (map-get? last-payment-id { invoice-id: invoice-id })))
      (new-payment-id (+ (get id last-id) u1))
      (new-amount-paid (+ (get amount-paid repayment) amount))
    )
    ;; Check that the repayment is not already completed
    (asserts! (not (is-eq (get status repayment) "completed")) (err u4))

    ;; Record the payment
    (map-set payment-history
      { invoice-id: invoice-id, payment-id: new-payment-id }
      {
        payer: tx-sender,
        amount: amount,
        payment-date: block-height
      }
    )

    ;; Update the last payment ID
    (map-set last-payment-id
      { invoice-id: invoice-id }
      { id: new-payment-id }
    )

    ;; Update the repayment status
    (map-set repayments
      { invoice-id: invoice-id }
      {
        total-amount: (get total-amount repayment),
        amount-paid: new-amount-paid,
        last-payment-date: block-height,
        status: (if (>= new-amount-paid (get total-amount repayment)) "completed" "partial")
      }
    )

    (ok true)
  )
)

;; Get repayment status for an invoice
(define-read-only (get-repayment-status (invoice-id uint))
  (map-get? repayments { invoice-id: invoice-id })
)

;; Get payment history for an invoice
(define-read-only (get-payment-history (invoice-id uint))
  (let
    (
      (last-id (default-to { id: u0 } (map-get? last-payment-id { invoice-id: invoice-id })))
    )
    (ok (get id last-id))
  )
)

;; Get a specific payment by ID
(define-read-only (get-payment (invoice-id uint) (payment-id uint))
  (map-get? payment-history { invoice-id: invoice-id, payment-id: payment-id })
)
