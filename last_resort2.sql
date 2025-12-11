-- ============================================
--  CORE LOOKUP TABLES
-- ============================================

CREATE TABLE hotel (
    hotelId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    brand TEXT NOT NULL
);

CREATE TABLE building (
    buildingId INTEGER PRIMARY KEY AUTOINCREMENT,
    hotelId INTEGER NOT NULL,
    name TEXT NOT NULL,
    FOREIGN KEY (hotelId) REFERENCES hotel(hotelId)
);

CREATE TABLE wing (
    wingId INTEGER PRIMARY KEY AUTOINCREMENT,
    buildingId INTEGER NOT NULL,
    name TEXT NOT NULL,
    nearPool INTEGER NOT NULL DEFAULT 0,
    nearParking INTEGER NOT NULL DEFAULT 0,
    handicapAccessible INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (buildingId) REFERENCES building(buildingId)
);

CREATE TABLE floor (
    floorId INTEGER PRIMARY KEY AUTOINCREMENT,
    wingId INTEGER NOT NULL,
    smokingPolicy TEXT NOT NULL,
    level INTEGER NOT NULL,
    FOREIGN KEY (wingId) REFERENCES wing(wingId)
);

CREATE TABLE room_type (
    roomTypeId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE status_type (
    statusId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE amenity (
    amenityId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE bed_type (
    bedId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- ============================================
--  ROOM & LAYOUT TABLES
-- ============================================

CREATE TABLE room (
    roomId INTEGER PRIMARY KEY AUTOINCREMENT,
    wingId INTEGER NOT NULL,
    roomTypeId INTEGER NOT NULL,
    floorId INTEGER NOT NULL,
    statusId INTEGER NOT NULL,
    roomNumber TEXT NOT NULL,
    baseDailyRate REAL NOT NULL,
    maxOccupancy INTEGER NOT NULL,
    FOREIGN KEY (wingId) REFERENCES wing(wingId),
    FOREIGN KEY (roomTypeId) REFERENCES room_type(roomTypeId),
    FOREIGN KEY (floorId) REFERENCES floor(floorId),
    FOREIGN KEY (statusId) REFERENCES status_type(statusId)
);

CREATE TABLE room_bed (
    roomId INTEGER NOT NULL,
    bedId INTEGER NOT NULL,
    count INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (roomId, bedId),
    FOREIGN KEY (roomId) REFERENCES room(roomId),
    FOREIGN KEY (bedId) REFERENCES bed_type(bedId)
);

CREATE TABLE room_amenity (
    roomId INTEGER NOT NULL,
    amenityId INTEGER NOT NULL,
    count INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (roomId, amenityId),
    FOREIGN KEY (roomId) REFERENCES room(roomId),
    FOREIGN KEY (amenityId) REFERENCES amenity(amenityId)
);

CREATE TABLE room_adjacency (
    roomId INTEGER NOT NULL,
    adjacentRoomId INTEGER NOT NULL,
    adjacencyType TEXT NOT NULL,
    PRIMARY KEY (roomId, adjacentRoomId),
    FOREIGN KEY (roomId) REFERENCES room(roomId),
    FOREIGN KEY (adjacentRoomId) REFERENCES room(roomId)
);

-- ============================================
--  PARTY / CUSTOMER / ORGANIZATION TABLES
-- ============================================

CREATE TABLE party (
    partyId INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    phone TEXT,
    email TEXT
);

CREATE TABLE organization (
    orgId INTEGER PRIMARY KEY AUTOINCREMENT,
    partyId INTEGER NOT NULL,
    name TEXT NOT NULL,
    FOREIGN KEY (partyId) REFERENCES party(partyId)
);

CREATE TABLE customer_qualification (
    qualificationId INTEGER PRIMARY KEY AUTOINCREMENT,
    partyId INTEGER NOT NULL,
    score INTEGER NOT NULL,
    notes TEXT,
    FOREIGN KEY (partyId) REFERENCES party(partyId)
);

CREATE TABLE guest (
    guestId INTEGER PRIMARY KEY AUTOINCREMENT,
    partyId INTEGER NOT NULL,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    FOREIGN KEY (partyId) REFERENCES party(partyId)
);

-- ============================================
--  RESERVATIONS, STAYS, EVENTS, CHARGES
-- ============================================

CREATE TABLE reservation (
    reservationId INTEGER PRIMARY KEY AUTOINCREMENT,
    partyId INTEGER NOT NULL,
    dateTime TEXT NOT NULL,
    FOREIGN KEY (partyId) REFERENCES party(partyId)
);

CREATE TABLE reservation_guest (
    reservationId INTEGER NOT NULL,
    guestId INTEGER NOT NULL,
    role TEXT,
    PRIMARY KEY (reservationId, guestId),
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId),
    FOREIGN KEY (guestId) REFERENCES guest(guestId)
);

CREATE TABLE charge_type (
    chargeTypeId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE charge (
    chargeId INTEGER PRIMARY KEY AUTOINCREMENT,
    reservationId INTEGER NOT NULL,
    chargeTypeId INTEGER NOT NULL,
    description TEXT,
    cost REAL NOT NULL,
    dateTime TEXT NOT NULL,
    time TEXT,
    splitCharge INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId),
    FOREIGN KEY (chargeTypeId) REFERENCES charge_type(chargeTypeId)
);

CREATE TABLE stay (
    stayId INTEGER PRIMARY KEY AUTOINCREMENT,
    reservationId INTEGER NOT NULL,
    roomId INTEGER NOT NULL,
    checkInTime TEXT NOT NULL,
    checkoutTime TEXT NOT NULL,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId),
    FOREIGN KEY (roomId) REFERENCES room(roomId)
);

CREATE TABLE event (
    eventId INTEGER PRIMARY KEY AUTOINCREMENT,
    reservationId INTEGER NOT NULL,
    roomId INTEGER NOT NULL,
    guestCount INTEGER,
    FOREIGN KEY (reservationId) REFERENCES reservation(reservationId),
    FOREIGN KEY (roomId) REFERENCES room(roomId)
);

-- ============================================
--  STAFF, TASKS, STAFF_EVENT
-- ============================================

CREATE TABLE staff (
    staffId INTEGER PRIMARY KEY AUTOINCREMENT,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    occupation TEXT NOT NULL
);

CREATE TABLE task_type (
    taskTypeId INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE task (
    taskId INTEGER PRIMARY KEY AUTOINCREMENT,
    roomId INTEGER NOT NULL,
    staffId INTEGER NOT NULL,
    taskTypeId INTEGER NOT NULL,
    FOREIGN KEY (roomId) REFERENCES room(roomId),
    FOREIGN KEY (staffId) REFERENCES staff(staffId),
    FOREIGN KEY (taskTypeId) REFERENCES task_type(taskTypeId)
);

CREATE TABLE staff_event (
    staffId INTEGER NOT NULL,
    eventId INTEGER NOT NULL,
    PRIMARY KEY (staffId, eventId),
    FOREIGN KEY (staffId) REFERENCES staff(staffId),
    FOREIGN KEY (eventId) REFERENCES event(eventId)
);

-- ============================================
--  GUEST CARDS, MESSAGES
-- ============================================

CREATE TABLE guest_card (
    cardId INTEGER PRIMARY KEY AUTOINCREMENT,
    guestId INTEGER NOT NULL,
    roomId INTEGER NOT NULL,
    pin TEXT NOT NULL,
    FOREIGN KEY (guestId) REFERENCES guest(guestId),
    FOREIGN KEY (roomId) REFERENCES room(roomId)
);

CREATE TABLE message (
    messageId INTEGER PRIMARY KEY AUTOINCREMENT,
    guestId INTEGER NOT NULL,
    message TEXT NOT NULL,
    FOREIGN KEY (guestId) REFERENCES guest(guestId)
);

-- Count tables in SQLite
-- SELECT count(*) FROM sqlite_master WHERE type = 'table';

