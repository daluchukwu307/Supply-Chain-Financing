;; Financing Marketplace Contract
;; Connects invoice holders with capital providers

;; Define financing offer structure
(define-map financing-offers
  { offer-id: uint }
  {
    invoice-id: uint,
    lender: principal,
    amount: uint,
    interest-rate: uint,
    expiration: uint,
    status: (string-ascii 20)
  }
)

;; Define financing agreements
(define-map financing-agreements
  { invoice-id: uint }
  {
    lender: principal,
    borrower: principal,
    amount: uint,
    interest-rate: uint,
    due-date: uint,
    status: (string-ascii 20)
  }
)

;; Track the last offer ID
(define-data-var last-offer-id uint u0)

;; Create a financing offer for an invoice
(define-public (create-offer (invoice-id uint) (amount uint) (interest-rate uint) (expiration uint))
  (let
    (
      (new-id (+ (var-get last-offer-id) u1))
    )
    ;; Create the offer
    (var-set last-offer-id new-id)
    (map-set financing-offers
      { offer-id: new-id }
      {
        invoice-id: invoice-id,
        lender: tx-sender,
        amount: amount,
        interest-rate: interest-rate,
        expiration: expiration,
        status: "active"
      }
    )
    (ok new-id)
  )
)

;; Accept a financing offer
(define-public (accept-offer (offer-id uint) (invoice-owner principal) (due-date uint))
  (let
    (
      (offer (unwrap! (map-get? financing-offers { offer-id: offer-id }) (err u1)))
      (invoice-id (get invoice-id offer))
    )
    ;; Check that the offer is still active
    (asserts! (is-eq (get status offer) "active") (err u5))
    ;; Check that the offer hasn't expired
    (asserts! (< block-height (get expiration offer)) (err u6))

    ;; Create the financing agreement
    (map-set financing-agreements
      { invoice-id: invoice-id }
      {
        lender: (get lender offer),
        borrower: tx-sender,
        amount: (get amount offer),
        interest-rate: (get interest-rate offer),
        due-date: due-date,
        status: "active"
      }
    )

    ;; Update the offer status
    (map-set financing-offers
      { offer-id: offer-id }
      (merge offer { status: "accepted" })
    )

    (ok true)
  )
)

;; Get financing offer details
(define-read-only (get-offer (offer-id uint))
  (map-get? financing-offers { offer-id: offer-id })
)

;; Get financing agreement for an invoice
(define-read-only (get-agreement (invoice-id uint))
  (map-get? financing-agreements { invoice-id: invoice-id })
)
