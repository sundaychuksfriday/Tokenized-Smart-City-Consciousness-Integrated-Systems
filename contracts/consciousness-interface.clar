;; Consciousness Interface Contract
;; Manages human-city consciousness interaction

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-interaction (err u201))
(define-constant err-user-not-registered (err u202))

;; User consciousness profiles
(define-map user-profiles
  { user: principal }
  {
    consciousness-level: uint,
    interaction-count: uint,
    last-interaction: uint,
    preferences: (string-ascii 256)
  }
)

;; Consciousness interaction logs
(define-map interaction-logs
  { interaction-id: uint }
  {
    user: principal,
    system-id: (string-ascii 64),
    interaction-type: (string-ascii 32),
    consciousness-impact: uint,
    timestamp: uint
  }
)

(define-data-var interaction-counter uint u0)

;; Register user for consciousness interaction
(define-public (register-user (consciousness-level uint) (preferences (string-ascii 256)))
  (begin
    (asserts! (and (> consciousness-level u0) (<= consciousness-level u100)) err-invalid-interaction)

    (map-set user-profiles
      { user: tx-sender }
      {
        consciousness-level: consciousness-level,
        interaction-count: u0,
        last-interaction: block-height,
        preferences: preferences
      }
    )

    (ok true)
  )
)

;; Log consciousness interaction
(define-public (log-interaction (system-id (string-ascii 64)) (interaction-type (string-ascii 32)) (consciousness-impact uint))
  (let ((interaction-id (+ (var-get interaction-counter) u1)))
    (asserts! (is-some (map-get? user-profiles { user: tx-sender })) err-user-not-registered)
    (asserts! (<= consciousness-impact u100) err-invalid-interaction)

    (map-set interaction-logs
      { interaction-id: interaction-id }
      {
        user: tx-sender,
        system-id: system-id,
        interaction-type: interaction-type,
        consciousness-impact: consciousness-impact,
        timestamp: block-height
      }
    )

    ;; Update user interaction count
    (match (map-get? user-profiles { user: tx-sender })
      user-data (map-set user-profiles
        { user: tx-sender }
        (merge user-data {
          interaction-count: (+ (get interaction-count user-data) u1),
          last-interaction: block-height
        })
      )
      false
    )

    (var-set interaction-counter interaction-id)
    (ok interaction-id)
  )
)

;; Get user profile
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

;; Get interaction details
(define-read-only (get-interaction (interaction-id uint))
  (map-get? interaction-logs { interaction-id: interaction-id })
)

;; Get total interactions
(define-read-only (get-total-interactions)
  (var-get interaction-counter)
)
