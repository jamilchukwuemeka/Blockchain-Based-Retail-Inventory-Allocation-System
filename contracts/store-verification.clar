;; Store Verification Contract
;; Validates legitimate retail locations

(define-data-var admin principal tx-sender)

;; Store data map: store-id -> store data
(define-map stores
  { store-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    is-verified: bool,
    owner: principal
  }
)

;; Store ID counter
(define-data-var next-store-id uint u1)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new store
(define-public (register-store (name (string-ascii 100)) (location (string-ascii 100)))
  (let
    ((store-id (var-get next-store-id)))
    (asserts! (is-admin) (err u403))
    (map-insert stores
      { store-id: store-id }
      {
        name: name,
        location: location,
        is-verified: false,
        owner: tx-sender
      }
    )
    (var-set next-store-id (+ store-id u1))
    (ok store-id)
  )
)

;; Verify a store
(define-public (verify-store (store-id uint))
  (let
    ((store (unwrap! (map-get? stores { store-id: store-id }) (err u404))))
    (asserts! (is-admin) (err u403))
    (map-set stores
      { store-id: store-id }
      (merge store { is-verified: true })
    )
    (ok true)
  )
)

;; Check if a store is verified
(define-read-only (is-store-verified (store-id uint))
  (default-to false
    (get is-verified (map-get? stores { store-id: store-id }))
  )
)

;; Get store details
(define-read-only (get-store (store-id uint))
  (map-get? stores { store-id: store-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
