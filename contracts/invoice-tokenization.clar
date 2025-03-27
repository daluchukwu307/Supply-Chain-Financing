;; Invoice Tokenization Contract
;; Converts verified invoices into tradable assets

(define-data-var last-invoice-id uint u0)

;; Define invoice token structure
(define-map invoices
  { invoice-id: uint }
  {
    issuer: principal,
    buyer: principal,
    amount: uint,
    due-date: uint,
    status: (string-ascii 20),
    tokenized: bool
  }
)

;; Define invoice ownership
(define-map invoice-ownership
  { invoice-id: uint }
  { owner: principal }
)

;; Create a new invoice
(define-public (create-invoice (buyer principal) (amount uint) (due-date uint))
  (let
    (
      (new-id (+ (var-get last-invoice-id) u1))
    )
    (var-set last-invoice-id new-id)
    (map-set invoices
      { invoice-id: new-id }
      {
        issuer: tx-sender,
        buyer: buyer,
        amount: amount,
        due-date: due-date,
        status: "pending",
        tokenized: false
      }
    )
    (map-set invoice-ownership
      { invoice-id: new-id }
      { owner: tx-sender }
    )
    (ok new-id)
  )
)

;; Update invoice status
(define-public (update-invoice-status (invoice-id uint) (new-status (string-ascii 20)))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u1)))
    )
    ;; Update the invoice status
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { status: new-status })
    )
    (ok true)
  )
)

;; Tokenize an invoice - can only be done by the invoice issuer
(define-public (tokenize-invoice (invoice-id uint))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u1)))
      (ownership (unwrap! (map-get? invoice-ownership { invoice-id: invoice-id }) (err u2)))
    )
    ;; Check that the sender is the invoice issuer
    (asserts! (is-eq tx-sender (get issuer invoice)) (err u3))
    ;; Check that the invoice is not already tokenized
    (asserts! (not (get tokenized invoice)) (err u4))
    ;; Check that the invoice is verified
    (asserts! (is-eq (get status invoice) "verified") (err u5))

    ;; Update the invoice to be tokenized
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { tokenized: true })
    )
    (ok true)
  )
)

;; Transfer ownership of a tokenized invoice
(define-public (transfer-invoice (invoice-id uint) (recipient principal))
  (let
    (
      (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) (err u1)))
      (ownership (unwrap! (map-get? invoice-ownership { invoice-id: invoice-id }) (err u2)))
    )
    ;; Check that the sender is the current owner
    (asserts! (is-eq tx-sender (get owner ownership)) (err u3))
    ;; Check that the invoice is tokenized
    (asserts! (get tokenized invoice) (err u4))

    ;; Transfer ownership
    (map-set invoice-ownership
      { invoice-id: invoice-id }
      { owner: recipient }
    )
    (ok true)
  )
)

;; Get invoice details
(define-read-only (get-invoice (invoice-id uint))
  (map-get? invoices { invoice-id: invoice-id })
)

;; Get invoice owner
(define-read-only (get-invoice-owner (invoice-id uint))
  (map-get? invoice-ownership { invoice-id: invoice-id })
)
