(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-tournament-exists (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-not-active (err u104))
(define-constant err-already-registered (err u105))
(define-constant err-invalid-ratios (err u106))
(define-constant err-already-distributed (err u107))
(define-constant err-invalid-placement (err u108))
(define-constant err-already-cancelled (err u109))
(define-constant err-not-cancelled (err u110))

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
        winner: (optional principal),
        prizes-distributed: bool,
        cancelled: bool
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

(define-map prize-distributions
    { tournament-id: uint }
    {
        first-place-percent: uint,
        second-place-percent: uint,
        third-place-percent: uint
    }
)

(define-map tournament-placements
    { tournament-id: uint, placement: uint }
    { winner: principal }
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
                winner: none,
                prizes-distributed: false,
                cancelled: false
            }
        )
        (map-insert prize-distributions
            { tournament-id: tournament-id }
            {
                first-place-percent: u100,
                second-place-percent: u0,
                third-place-percent: u0
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

(define-public (set-prize-distribution (tournament-id uint) (first-percent uint) (second-percent uint) (third-percent uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (is-eq (+ first-percent second-percent third-percent) u100) err-invalid-ratios)
        (map-set prize-distributions
            { tournament-id: tournament-id }
            {
                first-place-percent: first-percent,
                second-place-percent: second-percent,
                third-place-percent: third-percent
            }
        )
        (ok true)
    )
)

(define-public (declare-tournament-winners (tournament-id uint) (first-place principal) (second-place (optional principal)) (third-place (optional principal)))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (is-some (map-get? participant-badges { tournament-id: tournament-id, player: first-place })) err-not-found)
        (asserts! (not (get prizes-distributed tournament)) err-already-distributed)
        
        (match second-place 
            some-second (asserts! (is-some (map-get? participant-badges { tournament-id: tournament-id, player: some-second })) err-not-found)
            true
        )
        (match third-place 
            some-third (asserts! (is-some (map-get? participant-badges { tournament-id: tournament-id, player: some-third })) err-not-found)
            true
        )
        
        (map-insert tournament-placements { tournament-id: tournament-id, placement: u1 } { winner: first-place })
        (match second-place 
            some-second (map-insert tournament-placements { tournament-id: tournament-id, placement: u2 } { winner: some-second })
            true
        )
        (match third-place 
            some-third (map-insert tournament-placements { tournament-id: tournament-id, placement: u3 } { winner: some-third })
            true
        )
        
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament 
                {
                    is-active: false,
                    winner: (some first-place)
                }
            )
        )
        (ok true)
    )
)

(define-public (distribute-prizes (tournament-id uint))
    (let 
        (
            (tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found))
            (distribution (unwrap! (map-get? prize-distributions { tournament-id: tournament-id }) err-not-found))
            (prize-pool (get prize-pool tournament))
            (first-winner (unwrap! (get winner (map-get? tournament-placements { tournament-id: tournament-id, placement: u1 })) err-not-found))
            (second-winner (get winner (map-get? tournament-placements { tournament-id: tournament-id, placement: u2 })))
            (third-winner (get winner (map-get? tournament-placements { tournament-id: tournament-id, placement: u3 })))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (get is-active tournament)) err-not-active)
        (asserts! (not (get prizes-distributed tournament)) err-already-distributed)
        
        (let ((first-prize (/ (* prize-pool (get first-place-percent distribution)) u100)))
            (try! (as-contract (stx-transfer? first-prize tx-sender first-winner)))
        )
        
        (match second-winner
            some-second 
                (let ((second-prize (/ (* prize-pool (get second-place-percent distribution)) u100)))
                    (try! (as-contract (stx-transfer? second-prize tx-sender some-second)))
                )
            true
        )
        
        (match third-winner
            some-third 
                (let ((third-prize (/ (* prize-pool (get third-place-percent distribution)) u100)))
                    (try! (as-contract (stx-transfer? third-prize tx-sender some-third)))
                )
            true
        )
        
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament { prizes-distributed: true })
        )
        (ok true)
    )
)

(define-public (extend-tournament (tournament-id uint) (new-end-time uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (> new-end-time (get end-time tournament)) err-invalid-amount)
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament { end-time: new-end-time })
        )
        (ok true)
    )
)

(define-read-only (get-prize-distribution (tournament-id uint))
    (ok (unwrap! (map-get? prize-distributions { tournament-id: tournament-id }) err-not-found))
)

(define-read-only (get-tournament-winner (tournament-id uint) (placement uint))
    (if (and (>= placement u1) (<= placement u3))
        (ok (map-get? tournament-placements { tournament-id: tournament-id, placement: placement }))
        err-invalid-placement
    )
)

(define-public (cancel-tournament (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active tournament) err-not-active)
        (asserts! (not (get cancelled tournament)) err-already-cancelled)
        (map-set tournaments
            { tournament-id: tournament-id }
            (merge tournament { is-active: false, cancelled: true })
        )
        (ok true)
    )
)

(define-public (refund-stakes (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments { tournament-id: tournament-id }) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get cancelled tournament) err-not-cancelled)
        (asserts! (not (get prizes-distributed tournament)) err-already-distributed)
        (let ((stake (unwrap! (map-get? tournament-stakes { tournament-id: tournament-id, staker: tx-sender }) err-not-found)))
            (try! (as-contract (stx-transfer? (get amount stake) tx-sender tx-sender)))
            (map-delete tournament-stakes { tournament-id: tournament-id, staker: tx-sender })
        )
        (ok true)
    )
)