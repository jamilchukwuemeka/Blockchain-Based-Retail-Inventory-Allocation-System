;; Sales Tracking Contract
;; Monitors product movement by location

(define-data-var admin principal tx-sender)

;; Sale record structure
(define-map sales
  { sale-id: uint }
  {
    store-id: uint,
    product-id: uint,
    quantity: uint,
    timestamp: uint,
    price: uint
  }
)

;; Store total sales
(define-map store-sales
  { store-id: uint, product-id: uint }
  { total-quantity: uint, total-revenue: uint }
)

;; Sale ID counter
(define-data-var next-sale-id uint u1)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Record a new sale
(define-public (record-sale (store-id uint) (product-id uint) (quantity uint) (price uint))
  (let
    ((sale-id (var-get next-sale-id))
     (current-store-sales (default-to { total-quantity: u0, total-revenue: u0 }
                          (map-get? store-sales { store-id: store-id, product-id: product-id })))
     (new-total-quantity (+ (get total-quantity current-store-sales) quantity))
     (new-total-revenue (+ (get total-revenue current-store-sales) (* quantity price))))

    ;; Verify store exists and is verified (would call store-verification contract in a real implementation)
    ;; For simplicity, we're not making a cross-contract call here

    ;; Record the sale
    (map-insert sales
      { sale-id: sale-id }
      {
        store-id: store-id,
        product-id: product-id,
        quantity: quantity,
        timestamp: block-height,
        price: price
      }
    )

    ;; Update store sales totals
    (map-set store-sales
      { store-id: store-id, product-id: product-id }
      {
        total-quantity: new-total-quantity,
        total-revenue: new-total-revenue
      }
    )

    ;; Increment sale ID
    (var-set next-sale-id (+ sale-id u1))
    (ok sale-id)
  )
)

;; Get sale details
(define-read-only (get-sale (sale-id uint))
  (map-get? sales { sale-id: sale-id })
)

;; Get store sales for a product
(define-read-only (get-store-product-sales (store-id uint) (product-id uint))
  (map-get? store-sales { store-id: store-id, product-id: product-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
