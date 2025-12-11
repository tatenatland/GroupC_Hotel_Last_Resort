-- 1) Monthly revenue trend (overall)
SELECT
    YEAR(c.dateTime)   AS revenue_year,
    MONTH(c.dateTime)  AS revenue_month,
    SUM(c.cost)        AS total_revenue
FROM charge c
GROUP BY
    YEAR(c.dateTime),
    MONTH(c.dateTime)
ORDER BY
    revenue_year,
    revenue_month;


-- 2) Revenue by hotel (which hotel makes the most)
SELECT
    h.hotelId,
    h.name                            AS hotel_name,
    SUM(c.cost)                       AS total_revenue,
    COUNT(DISTINCT r.reservationId)   AS num_reservations
FROM charge c
JOIN reservation r ON r.reservationId = c.reservationId
JOIN stay s        ON s.reservationId = r.reservationId
JOIN room rm       ON rm.roomId = s.roomId
JOIN wing w        ON w.wingId = rm.wingId
JOIN building b    ON b.buildingId = w.buildingId
JOIN hotel h       ON h.hotelId = b.hotelId
GROUP BY
    h.hotelId,
    h.name
ORDER BY
    total_revenue DESC;


-- 3) Top 10 revenue customers (parties)
SELECT
    p.partyId,
    p.firstName,
    p.lastName,
    SUM(c.cost)                     AS total_revenue,
    COUNT(DISTINCT r.reservationId) AS num_reservations
FROM party p
JOIN reservation r ON r.partyId = p.partyId
JOIN charge c      ON c.reservationId = r.reservationId
GROUP BY
    p.partyId,
    p.firstName,
    p.lastName
ORDER BY
    total_revenue DESC
LIMIT 10;


-- 4) Revenue by charge type (room night vs resort vs extras)
SELECT
    ct.chargeTypeId,
    ct.name          AS charge_type,
    SUM(c.cost)      AS total_revenue,
    COUNT(*)         AS num_charges,
    AVG(c.cost)      AS avg_charge_amount
FROM charge c
JOIN charge_type ct ON ct.chargeTypeId = c.chargeTypeId
GROUP BY
    ct.chargeTypeId,
    ct.name
ORDER BY
    total_revenue DESC;


-- 5) Room type performance (revenue per room type, room-night charges only)
SELECT
    rt.roomTypeId,
    rt.name                      AS room_type,
    COUNT(DISTINCT s.stayId)     AS num_stays,
    SUM(c.cost)                  AS total_revenue,
    AVG(c.cost)                  AS avg_revenue_per_stay
FROM room_type rt
JOIN room rm       ON rm.roomTypeId = rt.roomTypeId
JOIN stay s        ON s.roomId = rm.roomId
JOIN reservation r ON r.reservationId = s.reservationId
JOIN charge c      ON c.reservationId = r.reservationId
WHERE c.chargeTypeId = 1    -- 1 = 'Room Night'
GROUP BY
    rt.roomTypeId,
    rt.name
ORDER BY
    total_revenue DESC;


-- 6) Approximate occupancy by hotel for a given period (adjust dates if needed)
SELECT
    h.hotelId,
    h.name                                       AS hotel_name,
    COUNT(DISTINCT s.stayId)                     AS num_stays,
    COUNT(DISTINCT rm.roomId)                    AS total_rooms,
    COUNT(DISTINCT s.stayId) * 1.0
        / COUNT(DISTINCT rm.roomId)              AS stays_per_room_ratio
FROM hotel h
JOIN building b ON b.hotelId = h.hotelId
JOIN wing w     ON w.buildingId = b.buildingId
JOIN room rm    ON rm.wingId = w.wingId
LEFT JOIN stay s
       ON s.roomId = rm.roomId
      AND s.checkInTime >= '2025-01-01'
      AND s.checkInTime <  '2025-04-01'
GROUP BY
    h.hotelId,
    h.name
ORDER BY
    stays_per_room_ratio DESC;


-- 7) Customer value vs qualification score
SELECT
    cq.score                   AS qualification_score,
    COUNT(DISTINCT p.partyId)  AS num_customers,
    SUM(c.cost)                AS total_revenue,
    AVG(c.cost)                AS avg_revenue_per_customer
FROM customer_qualification cq
JOIN party p       ON p.partyId = cq.partyId
JOIN reservation r ON r.partyId = p.partyId
JOIN charge c      ON c.reservationId = r.reservationId
GROUP BY
    cq.score
ORDER BY
    qualification_score DESC;


-- 8) Staff workload: tasks and events handled by each staff member
SELECT
    s.staffId,
    s.firstName,
    s.lastName,
    s.occupation,
    COUNT(DISTINCT t.taskId)    AS num_tasks,
    COUNT(DISTINCT se.eventId)  AS num_events_supported
FROM staff s
LEFT JOIN task t        ON t.staffId = s.staffId
LEFT JOIN staff_event se ON se.staffId = s.staffId
GROUP BY
    s.staffId,
    s.firstName,
    s.lastName,
    s.occupation
ORDER BY
    num_tasks DESC,
    num_events_supported DESC;

