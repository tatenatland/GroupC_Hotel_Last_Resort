from flask import Flask, render_template, request
import sqlite3

app = Flask(__name__)

DB_PATH = "last_resort.db"   


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@app.route("/")
def dashboard():
    conn = get_connection()
    cur = conn.cursor()

    # 1) Monthly revenue trend (overall)
    cur.execute("""
        SELECT
            strftime('%Y', c.dateTime) AS revenue_year,
            strftime('%m', c.dateTime) AS revenue_month,
            SUM(c.cost)                AS total_revenue
        FROM charge c
        GROUP BY
            strftime('%Y', c.dateTime),
            strftime('%m', c.dateTime)
        ORDER BY
            revenue_year,
            revenue_month;
    """)
    monthly_revenue = cur.fetchall()

    # 2) Revenue by hotel
    cur.execute("""
        SELECT
            h.hotelId,
            h.name                          AS hotel_name,
            SUM(c.cost)                     AS total_revenue,
            COUNT(DISTINCT r.reservationId) AS num_reservations
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
    """)
    revenue_by_hotel = cur.fetchall()

    # 3) Top 10 revenue customers (parties)
    cur.execute("""
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
    """)
    top_customers = cur.fetchall()

    # 4) Revenue by charge type
    cur.execute("""
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
    """)
    revenue_by_charge_type = cur.fetchall()

    # 5) Room type performance (room-night charges only)
    cur.execute("""
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
    """)
    room_type_perf = cur.fetchall()

    # 6) Approx occupancy by hotel (example period)
    cur.execute("""
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
    """)
    occupancy_by_hotel = cur.fetchall()

    # 7) Customer value vs qualification score
    cur.execute("""
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
    """)
    value_vs_score = cur.fetchall()

    # 8) Staff workload
    cur.execute("""
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
    """)
    staff_workload = cur.fetchall()

    conn.close()

    return render_template(
        "dashboard.html",
        monthly_revenue=monthly_revenue,
        revenue_by_hotel=revenue_by_hotel,
        top_customers=top_customers,
        revenue_by_charge_type=revenue_by_charge_type,
        room_type_perf=room_type_perf,
        occupancy_by_hotel=occupancy_by_hotel,
        value_vs_score=value_vs_score,
        staff_workload=staff_workload,
    )


@app.route("/search")
def search():
    search_type = request.args.get("type", "guest")  # 'guest', 'hotel', 'staff'
    q = request.args.get("q", "").strip()
    results = []

    if q:
        conn = get_connection()
        cur = conn.cursor()

        if search_type == "guest":
            # Search guest name → reservations
            cur.execute("""
                SELECT
                    r.reservationId,
                    p.firstName || ' ' || p.lastName AS customer_name,
                    p.email,
                    MIN(s.checkInTime)               AS check_in,
                    MAX(s.checkOutTime)              AS check_out,
                    SUM(c.cost)                      AS total_revenue
                FROM reservation r
                JOIN party p       ON p.partyId = r.partyId
                LEFT JOIN stay s   ON s.reservationId = r.reservationId
                LEFT JOIN charge c ON c.reservationId = r.reservationId
                WHERE
                    p.firstName LIKE ?
                    OR p.lastName LIKE ?
                    OR (p.firstName || ' ' || p.lastName) LIKE ?
                GROUP BY
                    r.reservationId,
                    customer_name,
                    p.email
                ORDER BY
                    check_in DESC;
            """, (f"%{q}%", f"%{q}%", f"%{q}%"))
            results = cur.fetchall()

        elif search_type == "hotel":
            # Search hotel name → monthly revenue for that hotel
            cur.execute("""
                SELECT
                    h.name                           AS hotel_name,
                    strftime('%Y-%m', c.dateTime)   AS year_month,
                    SUM(c.cost)                     AS total_revenue
                FROM charge c
                JOIN reservation r ON r.reservationId = c.reservationId
                JOIN stay s        ON s.reservationId = r.reservationId
                JOIN room rm       ON rm.roomId = s.roomId
                JOIN wing w        ON w.wingId = rm.wingId
                JOIN building b    ON b.buildingId = w.buildingId
                JOIN hotel h       ON h.hotelId = b.hotelId
                WHERE h.name LIKE ?
                GROUP BY
                    h.name,
                    year_month
                ORDER BY
                    year_month;
            """, (f"%{q}%",))
            results = cur.fetchall()

        elif search_type == "staff":
            # Search staff member → tasks & events
            cur.execute("""
                SELECT
                    s.staffId,
                    s.firstName || ' ' || s.lastName AS staff_name,
                    s.occupation,
                    COUNT(DISTINCT t.taskId)    AS num_tasks,
                    COUNT(DISTINCT se.eventId)  AS num_events_supported
                FROM staff s
                LEFT JOIN task t         ON t.staffId = s.staffId
                LEFT JOIN staff_event se ON se.staffId = s.staffId
                WHERE
                    s.firstName LIKE ?
                    OR s.lastName LIKE ?
                    OR (s.firstName || ' ' || s.lastName) LIKE ?
                GROUP BY
                    s.staffId,
                    staff_name,
                    s.occupation
                ORDER BY
                    num_tasks DESC,
                    num_events_supported DESC;
            """, (f"%{q}%", f"%{q}%", f"%{q}%"))
            results = cur.fetchall()

        conn.close()

    return render_template(
        "search.html",
        search_type=search_type,
        q=q,
        results=results,
    )


if __name__ == "__main__":
    app.run(debug=True)

