(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-tournament-exists (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-not-active (err u104))
(define-constant err-already-registered (err u105))

(define-data-var total-tournaments uint u0)
(define-data-var total-proposals uint u0)

(define-map tournaments 
    { tournament-id: uint }
    {
        name: (string-ascii 50),
        prize-pool: uint,
        start-time: uint,
        end-time: uint,
        game: (string-ascii 50),
        is-active: bool,
        winner: (optional principal)
    }
)

(define-map participant-badges
    { tournament-id: uint, player: principal }
    { registered: bool }
)

(define-map tournament-stakes
    { tournament-id: uint, staker: principal }
    { amount: uint }
)

(define-map game-proposals
    { proposal-id: uint }
    {
        game: (string-ascii 50),
        votes: uint,
        proposer: principal
    }
)

(define-public (create-tournament (name (string-ascii 50)) (game (string-ascii 50)) (start-time uint) (end-time uint))
    (let ((tournament-id (var-get total-tournaments)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> end-time start-time) err-invalid-amount)
        (map-insert tournaments
            { tournament-id: tournament-id }
            {
                name: name,
                prize-pool: u0,
                start-time: start-time,
                end-time: end-time,
                game: game,
                is-active: true,
                winner: none
            }
        )
        (var-set total-tournaments (+ tournament-id u1))
        (ok tournament-id)
    )
)

(define-public (register-player (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (is-none (map-get? participant-badges { tournament-id: tournament-id, player: tx-sender })) err-already-registered)
        (map-insert participant-badges
            { tournament-id: tournament-id, player: tx-sender }
            { registered: true }
        )
        (ok true)
    )
)

(define-public (stake-tokens (tournament-id uint) (amount uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (get is-active tournament) err-not-active)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament { prize-pool: (+ (get prize-pool tournament) amount) })
        )
        (let ((existing-stake (default-to u0 (get amount (map-get? tournament-stakes { tournament-id: tournament-id, staker: tx-sender })))))
            (map-set tournament-stakes
                { tournament-id: tournament-id, staker: tx-sender }
                { amount: (+ existing-stake amount) }
            )
        )
        (ok true)
    )
)

(define-public (declare-winner (tournament-id uint) (winner principal))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (is-some (map-get? participant-badges { tournament-id: tournament-id, player: winner })) err-not-found)
        (try! (as-contract (stx-transfer? (get prize-pool tournament) tx-sender winner)))
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament 
                {
                    is-active: false,
                    winner: (some winner)
                }
            )
        )
        (ok true)
    )
)

(define-public (propose-game (game (string-ascii 50)))

    (let ((proposal-id (var-get total-proposals)))
        (map-insert game-proposals
            { proposal-id: proposal-id }
            {
                game: game,
                votes: u0,
                proposer: tx-sender
            }
        )
        (var-set total-proposals (+ proposal-id u1))
        (ok proposal-id)
    )
)

(define-public (vote-game-proposal (proposal-id uint))
    (let ((proposal (unwrap! (map-get? game-proposals { proposal-id: proposal-id }) err-not-found)))
        (map-set game-proposals
            { proposal-id: proposal-id }
            (merge proposal { votes: (+ (get votes proposal) u1) })
        )
        (ok true)
    )
)

(define-read-only (get-tournament-info (tournament-id uint))
    (ok (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found))
)

(define-read-only (get-participant-status (tournament-id uint) (player principal))
    (ok (unwrap! (map-get? participant-badges { tournament-id: tournament-id, player: player }) err-not-found))
)